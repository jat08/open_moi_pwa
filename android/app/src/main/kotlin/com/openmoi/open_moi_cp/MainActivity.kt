package com.openmoi.open_moi_cp

import android.app.PendingIntent
import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.openmoi.open_moi_cp/nfc"
    private var nfcAdapter: NfcAdapter? = null
    private var methodChannel: MethodChannel? = null
    private var isNfcScanning = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableNfc" -> {
                    isNfcScanning = true
                    enableNfcReaderMode()
                    result.success(true)
                }
                "disableNfc" -> {
                    isNfcScanning = false
                    disableNfcReaderMode()
                    result.success(true)
                }
                "isNfcAvailable" -> {
                    val available = nfcAdapter != null && nfcAdapter?.isEnabled == true
                    result.success(available)
                }
                "openNfcSettings" -> {
                    try {
                        val intent = Intent(android.provider.Settings.ACTION_NFC_SETTINGS)
                        this@MainActivity.startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_SETTINGS)
                            this@MainActivity.startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        if (isNfcScanning) {
            enableNfcReaderMode()
        }
    }

    override fun onPause() {
        super.onPause()
        disableNfcReaderMode()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action = intent.action
        if (NfcAdapter.ACTION_NDEF_DISCOVERED == action ||
            NfcAdapter.ACTION_TECH_DISCOVERED == action ||
            NfcAdapter.ACTION_TAG_DISCOVERED == action) {

            val records = mutableListOf<String>()

            val rawMsgs = intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
            if (rawMsgs != null) {
                val messages = rawMsgs.map { it as NdefMessage }
                for (message in messages) {
                    for (record in message.records) {
                        parseTextRecord(record)?.let { records.add(it) }
                    }
                }
            } else {
                val tag: Tag? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(NfcAdapter.EXTRA_TAG, Tag::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
                }

                tag?.let { t ->
                    val recordsFromTag = processTag(t)
                    records.addAll(recordsFromTag)
                }
            }

            if (records.isNotEmpty()) {
                methodChannel?.invokeMethod("onNfcScanned", records)
            }
        }
    }

    private fun enableNfcReaderMode() {
        nfcAdapter?.let { adapter ->
            if (adapter.isEnabled) {
                val flags = NfcAdapter.FLAG_READER_NFC_A or
                            NfcAdapter.FLAG_READER_NFC_B or
                            NfcAdapter.FLAG_READER_NFC_F or
                            NfcAdapter.FLAG_READER_NFC_V or
                            NfcAdapter.FLAG_READER_NFC_BARCODE or
                            NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS

                adapter.enableReaderMode(this, NfcAdapter.ReaderCallback { tag ->
                    val records = processTag(tag)
                    if (records.isNotEmpty()) {
                        this@MainActivity.runOnUiThread {
                            methodChannel?.invokeMethod("onNfcScanned", records)
                        }
                    }
                }, flags, null)

                enableNfcForegroundDispatch()
            }
        }
    }

    private fun disableNfcReaderMode() {
        try {
            nfcAdapter?.disableReaderMode(this)
            disableNfcForegroundDispatch()
        } catch (_: Exception) {}
    }

    private fun enableNfcForegroundDispatch() {
        nfcAdapter?.let { adapter ->
            if (adapter.isEnabled) {
                val intent = Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getActivity(this, 0, intent, flags)
                adapter.enableForegroundDispatch(this, pendingIntent, null, null)
            }
        }
    }

    private fun disableNfcForegroundDispatch() {
        try {
            nfcAdapter?.disableForegroundDispatch(this)
        } catch (_: Exception) {}
    }

    private fun processTag(tag: Tag): List<String> {
        val records = mutableListOf<String>()
        val ndef = Ndef.get(tag)
        try {
            ndef?.connect()
            ndef?.cachedNdefMessage?.records?.forEach { record ->
                parseTextRecord(record)?.let { records.add(it) }
            } ?: ndef?.ndefMessage?.records?.forEach { record ->
                parseTextRecord(record)?.let { records.add(it) }
            }
        } catch (_: Exception) {
        } finally {
            try { ndef?.close() } catch (_: Exception) {}
        }
        return records
    }

    private fun parseTextRecord(record: NdefRecord): String? {
        val payload = record.payload ?: return null
        if (payload.isEmpty()) return null
        return try {
            val languageCodeLength = (payload[0].toInt() and 0x3F)
            if (payload.size > languageCodeLength + 1) {
                String(payload, languageCodeLength + 1, payload.size - languageCodeLength - 1, Charsets.UTF_8)
            } else {
                String(payload, Charsets.UTF_8)
            }
        } catch (_: Exception) {
            null
        }
    }
}
