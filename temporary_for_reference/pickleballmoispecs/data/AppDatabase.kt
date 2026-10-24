package com.example.pickleballmoispecs.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [
        Measurement::class, 
        MeasurementGroup::class, 
        EstimationGroup::class,
    ], 
    version = 14, 
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun measurementDao(): MeasurementDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        val MIGRATION_12_13 = object : androidx.room.migration.Migration(12, 13) {
            override fun migrate(db: androidx.sqlite.db.SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE measurements ADD COLUMN theoreticalPeriod REAL NOT NULL DEFAULT 0.0")
                db.execSQL("ALTER TABLE measurements ADD COLUMN theoreticalMoi REAL NOT NULL DEFAULT 0.0")
            }
        }
        
        val MIGRATION_13_14 = object : androidx.room.migration.Migration(13, 14) {
            override fun migrate(db: androidx.sqlite.db.SupportSQLiteDatabase) {
                db.execSQL("CREATE TABLE IF NOT EXISTS `measurements_new` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `groupId` INTEGER, `type` TEXT NOT NULL, `period` REAL NOT NULL, `moi` REAL NOT NULL, `tareMode` TEXT NOT NULL, `rawData` TEXT NOT NULL, `cyclePeriods` TEXT NOT NULL, `totalDuration` REAL NOT NULL, `fitResidual` REAL NOT NULL, `timestamp` INTEGER NOT NULL, FOREIGN KEY(`groupId`) REFERENCES `MeasurementGroup`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE)")
                db.execSQL("INSERT INTO `measurements_new` (`id`, `groupId`, `type`, `period`, `moi`, `tareMode`, `rawData`, `cyclePeriods`, `totalDuration`, `fitResidual`, `timestamp`) SELECT `id`, `groupId`, `type`, `period`, `moi`, `tareMode`, `rawData`, `cyclePeriods`, `totalDuration`, `fitResidual`, `timestamp` FROM `measurements`")
                db.execSQL("DROP TABLE `measurements`")
                db.execSQL("ALTER TABLE `measurements_new` RENAME TO `measurements`")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_measurements_groupId` ON `measurements` (`groupId`)")
            }
        }

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "moi_database"
                )
                .addMigrations(MIGRATION_12_13, MIGRATION_13_14)
                .fallbackToDestructiveMigration(false)
                .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
