package com.example.pickleballmoispecs.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "measurement_groups")
data class MeasurementGroup(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val timestamp: Long = System.currentTimeMillis(),
    
    // Attributes
    val mass: Double = 0.0,
    val massUnit: String = "oz",
    val length: Double = 0.0,
    val lengthUnit: String = "in",
    val width: Double = 0.0,
    val widthUnit: String = "in",
    val groupType: String = "Pickleball Paddle" // "Pickleball Paddle" or "Racquet"
)
