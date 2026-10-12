package com.example.pickleballmoispecs.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface MeasurementDao {
    // --- Measurements ---
    
    @Query("SELECT * FROM measurements WHERE type = :type ORDER BY timestamp DESC")
    fun getMeasurementsByType(type: String): Flow<List<Measurement>>

    @Query("SELECT * FROM measurements WHERE groupId = :groupId ORDER BY timestamp DESC")
    fun getMeasurementsByGroup(groupId: Int): Flow<List<Measurement>>

    @Insert
    suspend fun insertMeasurement(measurement: Measurement)

    @Delete
    suspend fun deleteMeasurement(measurement: Measurement)

    @Query("DELETE FROM measurements WHERE groupId = :groupId")
    suspend fun deleteMeasurementsByGroup(groupId: Int)

    @Query("DELETE FROM measurements WHERE id IN (:ids)")
    suspend fun deleteMeasurementsByIds(ids: List<Int>)

    @Query("DELETE FROM measurements WHERE type = :type")
    suspend fun deleteMeasurementsByType(type: String)

    // --- Groups ---

    @Query("SELECT * FROM measurement_groups WHERE name LIKE '%' || :query || '%' ORDER BY timestamp DESC")
    fun searchGroups(query: String): Flow<List<MeasurementGroup>>

    @Query("SELECT * FROM measurement_groups ORDER BY timestamp DESC")
    fun getAllGroups(): Flow<List<MeasurementGroup>>

    @Query("SELECT * FROM measurement_groups WHERE id = :id")
    fun getGroupById(id: Int): Flow<MeasurementGroup?>

    @Insert
    suspend fun insertGroup(group: MeasurementGroup): Long

    @Update
    suspend fun updateGroup(group: MeasurementGroup)

    @Delete
    suspend fun deleteGroup(group: MeasurementGroup)
    
    @Query("DELETE FROM measurement_groups WHERE id IN (:ids)")
    suspend fun deleteGroupsByIds(ids: List<Int>)

    @Query("SELECT COUNT(*) FROM measurement_groups")
    suspend fun getGroupCount(): Int

    // --- Estimations ---

    @Query("SELECT * FROM estimation_groups ORDER BY timestamp ASC")
    fun getAllEstimationGroups(): Flow<List<EstimationGroup>>

    @Query("SELECT * FROM estimation_groups WHERE name LIKE '%' || :query || '%' ORDER BY timestamp ASC")
    fun searchEstimationGroups(query: String): Flow<List<EstimationGroup>>

    @Insert
    suspend fun insertEstimationGroup(group: EstimationGroup): Long

    @Update
    suspend fun updateEstimationGroup(group: EstimationGroup)

    @Delete
    suspend fun deleteEstimationGroup(group: EstimationGroup)

    @Query("DELETE FROM estimation_groups WHERE id IN (:ids)")
    suspend fun deleteEstimationGroupsByIds(ids: List<Int>)

    @Query("SELECT COUNT(*) FROM estimation_groups")
    suspend fun getEstimationGroupsCount(): Int

    @Query("SELECT * FROM estimation_groups WHERE id = :groupId")
    fun getEstimationGroupById(groupId: Int): Flow<EstimationGroup?>
}
