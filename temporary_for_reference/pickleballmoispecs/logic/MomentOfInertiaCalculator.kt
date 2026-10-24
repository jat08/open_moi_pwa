package com.example.pickleballmoispecs.logic

import kotlin.math.PI
import kotlin.math.pow

/**
 * Calculates Moment of Inertia (MOI) for a torsional pendulum.
 * Formula: I = (kappa * T^2) / (4 * PI^2)
 */
object MomentOfInertiaCalculator {

    /**
     * Conversion factor from (kg*cm^2)/s^2 to kg*cm/rad
     * g = 980.665 cm/s^2
     */
    const val KAPPA_CONVERSION = 980.665

    /**
     * Calculates the MOI of an object given the period and device constants.
     * All parameters should be in raw physical units internally.
     */
    fun calculateObjectMOI(
        period: Double,
        springConstant: Double,
        deviceInertia: Double,
    ): Double {
        if ((period <= 0) || (springConstant <= 0)) return 0.0
        val totalInertia = (springConstant * period.pow(2)) / (4 * PI.pow(2))
        return (totalInertia - deviceInertia).coerceAtLeast(0.0)
    }

    /**
     * Calibrates using two known objects.
     * Returns raw physical units.
     */
    fun calibrateWithTwoObjects(
        periodA: Double,
        inertiaA: Double,
        periodB: Double,
        inertiaB: Double
    ): CalibrationResult {
        if (periodA <= 0 || periodB <= 0 || periodA == periodB || inertiaA == inertiaB) {
            return CalibrationResult(0.0, 0.0)
        }

        // kappa = (4 * PI^2 * (I_A - I_B)) / (T_A^2 - T_B^2)
        val kappa = (4 * PI.pow(2) * (inertiaA - inertiaB)) / (periodA.pow(2) - periodB.pow(2))
        
        // deviceInertia = (kappa * T_A^2) / (4 * PI^2) - I_A
        val deviceInertia = (kappa * periodA.pow(2)) / (4 * PI.pow(2)) - inertiaA

        return CalibrationResult(abs(kappa), deviceInertia)
    }

    private fun abs(value: Double) = if (value < 0) -value else value

    data class CalibrationResult(
        val springConstant: Double,
        val deviceInertia: Double
    )
}
