package com.cardscontrol.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.NfcManager
import android.provider.Settings
import com.cardscontrol.app.hce.HceManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Plugin NFC pour Flutter
 *
 * Ce plugin permet à Flutter de communiquer avec les fonctionnalités NFC natives Android :
 * - Lecture/écriture de tags NFC
 * - Host Card Emulation (HCE)
 * - Vérification de la disponibilité NFC
 */
class NfcPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        private const val CHANNEL = "com.cardscontrol.app/nfc"
        private const val HCE_CHANNEL = "com.cardscontrol.app/hce"
    }

    private var channel: MethodChannel? = null
    private var hceChannel: MethodChannel? = null
    private var context: Context? = null
    private var activity: Activity? = null
    private var hceManager: HceManager? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)

        hceChannel = MethodChannel(binding.binaryMessenger, HCE_CHANNEL)
        hceChannel?.setMethodCallHandler { call, result ->
            handleHceMethodCall(call, result)
        }

        hceManager = HceManager.getInstance(binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        hceChannel?.setMethodCallHandler(null)
        hceChannel = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isNfcAvailable" -> {
                result.success(isNfcAvailable())
            }
            "isNfcEnabled" -> {
                result.success(isNfcEnabled())
            }
            "openNfcSettings" -> {
                openNfcSettings()
                result.success(true)
            }
            "getNfcInfo" -> {
                result.success(getNfcInfo())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleHceMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isHceSupported" -> {
                result.success(hceManager?.isHceSupported() ?: false)
            }
            "isEmulationEnabled" -> {
                result.success(hceManager?.isEmulationEnabled() ?: false)
            }
            "setEmulationEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                hceManager?.setEmulationEnabled(enabled)
                result.success(true)
            }
            "setBusinessCard" -> {
                val cardId = call.argument<String>("cardId")
                val cardUrl = call.argument<String>("cardUrl")
                val vCardData = call.argument<String>("vCardData")

                if (cardId != null && cardUrl != null) {
                    val success = hceManager?.setBusinessCardData(cardId, cardUrl, vCardData) ?: false
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "cardId and cardUrl are required", null)
                }
            }
            "getConfiguredCardUrl" -> {
                result.success(hceManager?.getConfiguredCardUrl())
            }
            "clearData" -> {
                hceManager?.clearData()
                result.success(true)
            }
            "getHceInfo" -> {
                result.success(hceManager?.getHceInfo() ?: emptyMap<String, Any>())
            }
            "isDefaultService" -> {
                result.success(hceManager?.isDefaultService() ?: false)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun isNfcAvailable(): Boolean {
        val nfcManager = context?.getSystemService(Context.NFC_SERVICE) as? NfcManager
        return nfcManager?.defaultAdapter != null
    }

    private fun isNfcEnabled(): Boolean {
        val nfcManager = context?.getSystemService(Context.NFC_SERVICE) as? NfcManager
        return nfcManager?.defaultAdapter?.isEnabled == true
    }

    private fun openNfcSettings() {
        activity?.let { act ->
            val intent = Intent(Settings.ACTION_NFC_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            act.startActivity(intent)
        }
    }

    private fun getNfcInfo(): Map<String, Any?> {
        val nfcAdapter = NfcAdapter.getDefaultAdapter(context)
        val pm = context?.packageManager

        return mapOf(
            "isAvailable" to (nfcAdapter != null),
            "isEnabled" to (nfcAdapter?.isEnabled == true),
            "hasHce" to (pm?.hasSystemFeature("android.hardware.nfc.hce") == true),
            "hasHceF" to (pm?.hasSystemFeature("android.hardware.nfc.hcef") == true),
            "hasNfcA" to (pm?.hasSystemFeature("android.hardware.nfc") == true),
            "hasNfcB" to (pm?.hasSystemFeature("android.hardware.nfc") == true),
            "hasNfcF" to (pm?.hasSystemFeature("android.hardware.nfc") == true),
            "hasNfcV" to (pm?.hasSystemFeature("android.hardware.nfc") == true),
            "hasIsoDep" to (pm?.hasSystemFeature("android.hardware.nfc") == true),
            "hasMifareClassic" to (pm?.hasSystemFeature("android.hardware.nfc") == true),
            "hasMifareUltralight" to (pm?.hasSystemFeature("android.hardware.nfc") == true)
        )
    }
}
