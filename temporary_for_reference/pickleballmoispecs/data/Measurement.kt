package com.example.pickleballmoispecs.data

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "measurements",
    foreignKeys = [
        ForeignKey(
            entity = MeasurementGroup::class,
            parentColumns = ["id"],
            childColumns = ["groupId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("groupId")]
)
data class Measurement(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val groupId: Int? = null,
    val type: String, // OBJECT_A, OBJECT_B, PADDLE, TARE_PB, TARE_TW
    val period: Double,
    val moi: Double,
    val tareMode: String = "None",
    val rawData: String = "", // Comma-separated gyro values for graphing
    val cyclePeriods: String = "", // Comma-separated individual oscillation periods
    val totalDuration: Double = 0.0, // Length of measurement session in seconds
    val fitResidual: Double = 0.0, // Quality score (MAE / Ref * 10)
    val timestamp: Long = System.currentTimeMillis()
)

@Entity(tableName = "estimation_groups")
data class EstimationGroup(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val mass: Double = 0.0,
    val massUnit: String = "oz",
    val length: Double = 0.0,
    val lengthUnit: String = "in",
    val width: Double = 0.0,
    val widthUnit: String = "in",
    val balancePoint: Double = 0.0,
    val bpUnit: String = "in",
    val radius: Double = 0.0,
    val radiusUnit: String = "cm",
    val type: String = "Pickleball Paddle",
    val resultSW: Double = 0.0,
    val resultTW: Double = 0.0,
    val timestamp: Long = System.currentTimeMillis()
)
