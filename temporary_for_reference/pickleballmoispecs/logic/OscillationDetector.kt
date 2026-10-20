package com.example.pickleballmoispecs.logic

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.sqrt

class OscillationDetector(
    private val onStateChanged: (State) -> Unit,
    private val onMeasurementComplete: (Result) -> Unit,
    private val onProgressUpdate: (Float) -> Unit,
) : SensorEventListener {

    enum class State {
        WRONG_ORIENTATION,
        READY,
        ARMED,
        SETTLING,
        ACTIVE_COUNTING
    }

    data class Result(
        val averagePeriod: Double,
        val rawData: String,
        val cyclePeriods: String,
        val totalDuration: Double
    )

    private var currentState = State.WRONG_ORIENTATION
    private var requiredCycles = 8
    private var skipFirstCycles = 0
    
    private var detectedCycles = 0
    private var tStartNs: Long = 0
    private var tEndNs: Long = 0
    private var lastCrossingTimeNs: Long = 0
    private var lastGyroValue: Float = 0f
    private var lastSampleTimeNs: Long = 0L
    
    private var maxMeasurementDurationNs = 8_000_000_000L // Default 8s
    private var measurementStartTimeNs: Long = 0
    
    private val orientationThreshold = 5.0
    private val targetAngle = 45.0
    private val nudgeThreshold = 0.3f 
    private val debounceNs = 100_000_000L // 0.1s hysteresis window
    
    private var gravityVector = floatArrayOf(0f, 0f, 9.8f)
    private var gyroBaseline: Float = 0f // Dynamically tracks DC bias
    
    private val rawGyroSamples = mutableListOf<Float>()
    private val cycleDurations = mutableListOf<Double>()

    fun setMaxDuration(seconds: Double) {
        maxMeasurementDurationNs = (seconds * 1_000_000_000L).toLong()
    }

    fun setRequiredCycles(count: Int) {
        requiredCycles = count
    }

    fun setSkipFirstCycles(count: Int) {
        skipFirstCycles = count
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ACCELEROMETER -> handleAccelerometer(event.values)
            Sensor.TYPE_GYROSCOPE -> handleGyroscope(event.values, event.timestamp)
        }
    }

    private fun handleAccelerometer(values: FloatArray) {
        gravityVector[0] = values[0]
        gravityVector[1] = values[1]
        gravityVector[2] = values[2]

        if (currentState == State.ARMED || currentState == State.SETTLING || currentState == State.ACTIVE_COUNTING) return

        val x = values[0]
        val y = values[1]
        
        val horizontalMag = sqrt(x*x + y*y)
        if (horizontalMag < 1.0) { // Nearly flat
            updateState(State.WRONG_ORIENTATION)
            return
        }

        val angle = Math.toDegrees(abs(atan2(x.toDouble(), y.toDouble())))
        val isCorrectOrientation = abs(angle - targetAngle) < orientationThreshold

        if (!isCorrectOrientation) {
            updateState(State.WRONG_ORIENTATION)
        } else {
            updateState(State.READY)
        }
    }

    private fun handleGyroscope(values: FloatArray, timestampNs: Long) {
        if (currentState == State.WRONG_ORIENTATION) return

        val gx = gravityVector[0]
        val gy = gravityVector[1]
        val gz = gravityVector[2]
        val gMag = sqrt(gx*gx + gy*gy + gz*gz)
        
        val vRot = if (gMag > 0) {
            (values[0] * gx + values[1] * gy + values[2] * gz) / gMag
        } else 0f

        val gyroMag = sqrt(values[0]*values[0] + values[1]*values[1] + values[2]*values[2])

        when (currentState) {
            State.WRONG_ORIENTATION -> {}
            State.READY, State.ARMED -> {
                if (currentState == State.ARMED && gyroMag > nudgeThreshold) {
                    resetMeasurement()
                    measurementStartTimeNs = timestampNs
                    updateState(State.SETTLING)
                } else if (gyroMag < 0.1f) {
                    // When the phone is perfectly still, continuously track the gyro DC bias (thermal drift correction)
                    gyroBaseline = (1f - 0.05f) * gyroBaseline + 0.05f * vRot
                }
            }
            State.SETTLING, State.ACTIVE_COUNTING -> {
                // Determine zero crossing before adding to samples to ensure tStartNs sample is the first one
                detectZeroCrossing(vRot, timestampNs)
                
                if (currentState == State.ACTIVE_COUNTING) {
                    rawGyroSamples.add(vRot)
                }
                
                val elapsedNs = timestampNs - measurementStartTimeNs
                
                // Progress tracking (based on total cycles: skip + measure)
                val totalExpectedCycles = skipFirstCycles + requiredCycles
                // detectedCycles in SETTLING is 1..skipFirstCycles+1
                // detectedCycles in ACTIVE_COUNTING is 0..requiredCycles
                val currentProgressCycles = if (currentState == State.SETTLING) {
                    detectedCycles
                } else {
                    skipFirstCycles + 1 + detectedCycles
                }
                
                val cycleProgress = currentProgressCycles.toFloat() / (totalExpectedCycles + 1).coerceAtLeast(1)
                val timeProgress = elapsedNs.toFloat() / maxMeasurementDurationNs
                onProgressUpdate(maxOf(cycleProgress, timeProgress).coerceAtMost(1f))
                
                if (elapsedNs >= maxMeasurementDurationNs) {
                    finishMeasurement()
                }
            }
        }
        lastGyroValue = vRot
        lastSampleTimeNs = timestampNs
    }

    private fun detectZeroCrossing(currentGyro: Float, timestampNs: Long) {
        // Positive-slope zero crossing detection against dynamic thermal baseline: prev <= baseline && current > baseline
        if (lastGyroValue <= gyroBaseline && currentGyro > gyroBaseline) {
            // Sub-sample linear interpolation for sub-millisecond zero-crossing timestamp precision
            val deltaGyro = currentGyro - lastGyroValue
            val exactCrossingNs: Long = if (deltaGyro > 0f && lastSampleTimeNs > 0L && timestampNs > lastSampleTimeNs) {
                val fraction = (gyroBaseline - lastGyroValue) / deltaGyro
                lastSampleTimeNs + (fraction * (timestampNs - lastSampleTimeNs)).toLong()
            } else {
                timestampNs
            }

            // Debounce to prevent noise triggers
            if (exactCrossingNs - lastCrossingTimeNs < debounceNs) return
            
            val prevCrossingTime = lastCrossingTimeNs
            lastCrossingTimeNs = exactCrossingNs
            detectedCycles++
            
            when (currentState) {
                State.SETTLING -> {
                    if (detectedCycles > skipFirstCycles) {
                        tStartNs = exactCrossingNs
                        updateState(State.ACTIVE_COUNTING)
                        detectedCycles = 0 // Reset for active counting phase
                    }
                }
                State.ACTIVE_COUNTING -> {
                    // Record cycle duration
                    val cycleDuration = (exactCrossingNs - prevCrossingTime).toDouble() / 1_000_000_000.0
                    cycleDurations.add(cycleDuration)
                    
                    if (detectedCycles >= requiredCycles) {
                        tEndNs = exactCrossingNs
                        finishMeasurement()
                    }
                }
                else -> {}
            }
        }
    }

    private fun finishMeasurement() {
        if (tStartNs > 0 && detectedCycles > 0 && rawGyroSamples.isNotEmpty()) {
            // tEndNs might be 0 if we timed out
            val endTimeNs = if (tEndNs > tStartNs) tEndNs else lastCrossingTimeNs
            val durationNs = endTimeNs - tStartNs
            val actualCycleCount = cycleDurations.size
            
            if (actualCycleCount > 0) {
                val avgPeriod = (durationNs.toDouble() / actualCycleCount) / 1_000_000_000.0
                val totalDurSec = durationNs / 1_000_000_000.0
                
                onMeasurementComplete(
                    Result(
                        averagePeriod = avgPeriod,
                        rawData = rawGyroSamples.joinToString(","),
                        cyclePeriods = cycleDurations.joinToString(","), // Pass high-precision raw durations
                        totalDuration = totalDurSec
                    )
                )
            }
        }
        updateState(State.READY)
    }

    private fun resetMeasurement() {
        detectedCycles = 0
        tStartNs = 0
        tEndNs = 0
        lastCrossingTimeNs = 0
        lastGyroValue = 0f
        lastSampleTimeNs = 0L
        rawGyroSamples.clear()
        cycleDurations.clear()
        measurementStartTimeNs = 0
        onProgressUpdate(0f)
    }

    private fun updateState(newState: State) {
        if (currentState != newState) {
            currentState = newState
            onStateChanged(newState)
        }
    }

    fun arm() {
        if (currentState == State.READY) {
            updateState(State.ARMED)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
