package com.cardscontrol.app

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Intent
import android.content.IntentFilter
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.cardemulation.CardEmulation
import android.nfc.tech.*
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import com.cardscontrol.app.hce.CardEmulationService
import com.cardscontrol.app.hce.HceManager
import com.cardscontrol.app.shortcuts.ShortcutPlugin
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val TAG = "MainActivity"
    private val CHANNEL = "com.cardscontrol.app/nfc"
    private val HCE_CHANNEL = "com.cardscontrol.app/hce"
    private val SHORTCUT_CHANNEL = "com.cardscontrol.app/shortcuts"
    private val DEEP_LINK_CHANNEL = "com.cardscontrol.app/deeplink"
    private var nfcAdapter: NfcAdapter? = null
    private var cardEmulation: CardEmulation? = null
    private var pendingIntent: PendingIntent? = null
    private var methodChannel: MethodChannel? = null
    private var hceChannel: MethodChannel? = null
    private var shortcutChannel: MethodChannel? = null
    private var deepLinkChannel: MethodChannel? = null
    private var hceManager: HceManager? = null
    private var shortcutPlugin: ShortcutPlugin? = null

    // États NFC optimisés pour HCE
    @Volatile private var isReading = false
    @Volatile private var isWriting = false
    @Volatile private var isFormatting = false
    @Volatile private var isEmulating = false
    private var dataToWrite: String? = null
    private var typeToWrite: String? = null
    private var pendingDeepLink: String? = null

    // Flag pour éviter les conflits entre foreground dispatch et HCE
    @Volatile private var foregroundDispatchEnabled = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize HCE Manager et pré-charger les données pour une détection rapide
        hceManager = HceManager.getInstance(applicationContext)
        // Pré-charger les données HCE dès le démarrage pour éviter les latences
        hceManager?.preloadEmulationData()

        // Initialize Shortcut Plugin
        shortcutPlugin = ShortcutPlugin(applicationContext)

        // Setup Shortcut Channel
        shortcutChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHORTCUT_CHANNEL)
        shortcutChannel?.setMethodCallHandler(shortcutPlugin)

        // Setup Deep Link Channel
        deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEP_LINK_CHANNEL)
        deepLinkChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    result.success(pendingDeepLink)
                    pendingDeepLink = null
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Handle initial deep link from intent
        handleDeepLinkIntent(intent)

        // Setup HCE Channel
        hceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HCE_CHANNEL)
        hceChannel?.setMethodCallHandler { call, result ->
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
                        // Envoyer un broadcast pour recharger les données dans le service
                        val reloadIntent = Intent(CardEmulationService.ACTION_RELOAD_DATA)
                        reloadIntent.setPackage(packageName)
                        sendBroadcast(reloadIntent)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "cardId and cardUrl are required", null)
                    }
                }
                "setTemplate" -> {
                    // Les templates utilisent la même logique que les cartes de visite
                    // On envoie juste l'URL publique du template
                    val templateId = call.argument<String>("templateId")
                    val templateUrl = call.argument<String>("templateUrl")

                    if (templateId != null && templateUrl != null) {
                        // Réutiliser setBusinessCardData car c'est le même mécanisme (envoyer une URL)
                        val success = hceManager?.setBusinessCardData(templateId, templateUrl, null) ?: false
                        // Envoyer un broadcast pour recharger les données dans le service
                        val reloadIntent = Intent(CardEmulationService.ACTION_RELOAD_DATA)
                        reloadIntent.setPackage(packageName)
                        sendBroadcast(reloadIntent)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "templateId and templateUrl are required", null)
                    }
                }
                "startEmulation" -> {
                    startEmulation()
                    result.success(true)
                }
                "stopEmulation" -> {
                    stopEmulation()
                    result.success(true)
                }
                "getConfiguredCardUrl" -> {
                    result.success(hceManager?.getConfiguredCardUrl())
                }
                "clearData" -> {
                    hceManager?.clearData()
                    result.success(true)
                }
                "getHceInfo" -> {
                    val info = hceManager?.getHceInfo()?.toMutableMap() ?: mutableMapOf()
                    info["isEmulating"] = isEmulating
                    result.success(info)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isNfcAvailable" -> {
                    result.success(isNfcAvailable())
                }
                "isNfcEnabled" -> {
                    result.success(isNfcEnabled())
                }
                "startReading" -> {
                    startReading()
                    result.success(true)
                }
                "stopReading" -> {
                    stopReading()
                    result.success(true)
                }
                "startWriting" -> {
                    val data = call.argument<Any>("data")
                    val type = call.argument<String>("type") ?: "text"
                    if (data != null) {
                        val dataString = when (data) {
                            is String -> data
                            is Map<*, *> -> org.json.JSONObject(data as Map<String, Any>).toString()
                            else -> data.toString()
                        }
                        startWriting(dataString, type)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Data is required", null)
                    }
                }
                "stopWriting" -> {
                    stopWriting()
                    result.success(true)
                }
                "startFormatting" -> {
                    startFormatting()
                    result.success(true)
                }
                "stopFormatting" -> {
                    stopFormatting()
                    result.success(true)
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
    }

    private fun openNfcSettings() {
        val intent = Intent(Settings.ACTION_NFC_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun getNfcInfo(): Map<String, Any?> {
        val pm = packageManager
        return mapOf(
            "isAvailable" to (nfcAdapter != null),
            "isEnabled" to (nfcAdapter?.isEnabled == true),
            "hasHce" to pm.hasSystemFeature("android.hardware.nfc.hce"),
            "hasHceF" to pm.hasSystemFeature("android.hardware.nfc.hcef"),
            "hasNfcA" to pm.hasSystemFeature("android.hardware.nfc"),
            "hasNfcB" to pm.hasSystemFeature("android.hardware.nfc"),
            "hasNfcF" to pm.hasSystemFeature("android.hardware.nfc"),
            "hasNfcV" to pm.hasSystemFeature("android.hardware.nfc"),
            "hasIsoDep" to pm.hasSystemFeature("android.hardware.nfc"),
            "hasMifareClassic" to pm.hasSystemFeature("android.hardware.nfc"),
            "hasMifareUltralight" to pm.hasSystemFeature("android.hardware.nfc")
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initNfc()
    }

    private fun initNfc() {
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)

        // Initialize CardEmulation for HCE
        nfcAdapter?.let {
            cardEmulation = CardEmulation.getInstance(it)
        }

        val intent = Intent(this, javaClass).apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_MUTABLE
        } else {
            0
        }

        pendingIntent = PendingIntent.getActivity(this, 0, intent, flags)
    }

    /**
     * Démarre l'émulation HCE avec optimisations pour une détection ultra-rapide
     *
     * Optimisations appliquées:
     * 1. Pré-charge les données NDEF avant de démarrer
     * 2. Désactive agressivement le foreground dispatch
     * 3. Configure le service HCE comme préféré
     * 4. Évite le broadcast asynchrone (données déjà en cache)
     */
    private fun startEmulation() {
        Log.d(TAG, "Starting HCE emulation (optimized)")

        // 1. Pré-charger les données dans le cache statique AVANT tout
        hceManager?.preloadEmulationData()

        // 2. Marquer l'émulation comme active
        isEmulating = true

        // 3. Désactiver IMMÉDIATEMENT et AGRESSIVEMENT le foreground dispatch
        // Le foreground dispatch intercepte les communications NFC et cause des délais
        forceDisableForegroundDispatch()

        // 4. Configurer le service HCE comme service préféré
        cardEmulation?.let { ce ->
            val componentName = ComponentName(this, CardEmulationService::class.java)
            try {
                @Suppress("DEPRECATION")
                ce.setPreferredService(this, componentName)
                Log.d(TAG, "HCE service set as preferred")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to set preferred service", e)
            }
        }

        // Note: Pas de broadcast nécessaire car les données sont déjà dans le cache statique
        Log.d(TAG, "HCE emulation ready (data preloaded)")
    }

    /**
     * Désactive AGRESSIVEMENT le foreground dispatch
     * Cette méthode s'assure que le dispatch est vraiment désactivé
     */
    private fun forceDisableForegroundDispatch() {
        try {
            nfcAdapter?.disableForegroundDispatch(this)
            foregroundDispatchEnabled = false
            Log.d(TAG, "Foreground dispatch forcefully disabled")
        } catch (e: Exception) {
            Log.e(TAG, "Error disabling foreground dispatch", e)
        }
    }

    /**
     * Arrête l'émulation HCE et réactive la lecture NFC si nécessaire
     */
    private fun stopEmulation() {
        Log.d(TAG, "Stopping HCE emulation")
        isEmulating = false

        // Désactiver le service préféré
        cardEmulation?.let { ce ->
            try {
                @Suppress("DEPRECATION")
                ce.unsetPreferredService(this)
                Log.d(TAG, "HCE preferred service unset")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to unset preferred service", e)
            }
        }

        // Réactiver le foreground dispatch si la lecture ou l'écriture est active
        if (isReading || isWriting) {
            enableForegroundDispatch()
        }
    }

    private fun isNfcAvailable(): Boolean {
        return nfcAdapter != null
    }

    private fun isNfcEnabled(): Boolean {
        return nfcAdapter?.isEnabled == true
    }

    private fun startReading() {
        isReading = true
        isWriting = false
        enableForegroundDispatch()
    }

    private fun stopReading() {
        isReading = false
        if (!isWriting) {
            disableForegroundDispatch()
        }
    }

    private fun startWriting(data: String, type: String) {
        Log.d(TAG, "startWriting called with type=$type, data=$data")
        isWriting = true
        isReading = false
        dataToWrite = data
        typeToWrite = type
        enableForegroundDispatch()
    }

    private fun stopWriting() {
        isWriting = false
        dataToWrite = null
        typeToWrite = null
        if (!isReading && !isFormatting) {
            disableForegroundDispatch()
        }
    }

    private fun startFormatting() {
        Log.d(TAG, "startFormatting called")
        isFormatting = true
        isReading = false
        isWriting = false
        enableForegroundDispatch()
    }

    private fun stopFormatting() {
        isFormatting = false
        if (!isReading && !isWriting) {
            disableForegroundDispatch()
        }
    }

    private fun enableForegroundDispatch() {
        // IMPORTANT: Ne jamais activer pendant l'émulation HCE
        if (isEmulating) {
            Log.d(TAG, "Skipping foreground dispatch - HCE emulation active")
            return
        }

        if (foregroundDispatchEnabled) {
            return // Déjà activé
        }

        val techList = arrayOf(
            arrayOf(NfcA::class.java.name),
            arrayOf(NfcB::class.java.name),
            arrayOf(NfcF::class.java.name),
            arrayOf(NfcV::class.java.name),
            arrayOf(IsoDep::class.java.name),
            arrayOf(Ndef::class.java.name),
            arrayOf(NdefFormatable::class.java.name),
            arrayOf(MifareClassic::class.java.name),
            arrayOf(MifareUltralight::class.java.name)
        )

        val filters = arrayOf(
            IntentFilter(NfcAdapter.ACTION_NDEF_DISCOVERED).apply {
                try {
                    addDataType("*/*")
                } catch (e: IntentFilter.MalformedMimeTypeException) {
                    throw RuntimeException("Failed to add MIME type", e)
                }
            },
            IntentFilter(NfcAdapter.ACTION_TECH_DISCOVERED),
            IntentFilter(NfcAdapter.ACTION_TAG_DISCOVERED)
        )

        try {
            nfcAdapter?.enableForegroundDispatch(this, pendingIntent, filters, techList)
            foregroundDispatchEnabled = true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enable foreground dispatch", e)
        }
    }

    private fun disableForegroundDispatch() {
        if (!foregroundDispatchEnabled) {
            return // Déjà désactivé
        }
        try {
            nfcAdapter?.disableForegroundDispatch(this)
            foregroundDispatchEnabled = false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to disable foreground dispatch", e)
        }
    }

    override fun onResume() {
        super.onResume()
        // CRITIQUE: Ne JAMAIS activer le foreground dispatch pendant l'émulation HCE
        // Le foreground dispatch intercepte les communications NFC et cause des délais de 5-9 secondes
        if (isEmulating) {
            Log.d(TAG, "onResume: HCE emulation active - keeping foreground dispatch disabled")
            forceDisableForegroundDispatch()
            return
        }

        if (isReading || isWriting || isFormatting) {
            enableForegroundDispatch()
        }
    }

    override fun onPause() {
        super.onPause()
        disableForegroundDispatch()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        // Check for deep link first
        if (handleDeepLinkIntent(intent)) {
            return
        }

        // Otherwise handle NFC intent
        handleNfcIntent(intent)
    }

    /**
     * Handle deep link intents from shortcuts, external links, or App Links
     * Returns true if the intent was a deep link, false otherwise
     *
     * Supports:
     * - Custom scheme: cardscontrol://emulate/{cardId}, cardscontrol://card/{cardId}
     * - App Links: https://cards-control.app/card/{cardId}
     */
    private fun handleDeepLinkIntent(intent: Intent): Boolean {
        val data = intent.data ?: return false

        // Check for custom scheme (cardscontrol://)
        if (data.scheme == "cardscontrol") {
            val deepLink = data.toString()
            Log.d(TAG, "Custom scheme deep link received: $deepLink")
            sendDeepLinkToFlutter(deepLink)
            return true
        }

        // Check for App Links (https://cards-control.app/*)
        if ((data.scheme == "https" || data.scheme == "http") &&
            (data.host == "cards-control.app" || data.host == "www.cards-control.app")) {

            // Only handle /card/* paths
            val path = data.path ?: ""
            if (path.startsWith("/card")) {
                val deepLink = data.toString()
                Log.d(TAG, "App Link received: $deepLink")
                sendDeepLinkToFlutter(deepLink)
                return true
            }
        }

        return false
    }

    /**
     * Sends a deep link to Flutter via the method channel
     */
    private fun sendDeepLinkToFlutter(deepLink: String) {
        // If Flutter engine is ready, send immediately
        if (deepLinkChannel != null) {
            runOnUiThread {
                deepLinkChannel?.invokeMethod("onDeepLink", deepLink)
            }
        } else {
            // Store for later retrieval
            pendingDeepLink = deepLink
        }
    }

    private fun handleNfcIntent(intent: Intent) {
        val tag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(NfcAdapter.EXTRA_TAG, Tag::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
        }

        tag?.let { nfcTag ->
            when {
                isFormatting -> formatTag(nfcTag)
                isWriting && dataToWrite != null -> writeToTag(nfcTag, dataToWrite!!)
                isReading -> readFromTag(nfcTag, intent)
            }
        }
    }

    private fun formatTag(tag: Tag) {
        var success = false
        var errorMessage: String? = null

        Log.d(TAG, "formatTag called - full memory erase")

        try {
            // Try to erase all memory on Mifare Ultralight first (most common writable tags)
            val ultralight = MifareUltralight.get(tag)
            if (ultralight != null) {
                success = eraseUltralightMemory(ultralight)
                if (success) {
                    Log.d(TAG, "Successfully erased Mifare Ultralight memory")
                } else {
                    errorMessage = "Failed to erase Ultralight memory"
                }
            } else {
                // Try Mifare Classic
                val classic = MifareClassic.get(tag)
                if (classic != null) {
                    success = eraseClassicMemory(classic)
                    if (success) {
                        Log.d(TAG, "Successfully erased Mifare Classic memory")
                    } else {
                        errorMessage = "Failed to erase Classic memory (may need authentication)"
                    }
                } else {
                    // Fallback to NDEF erase
                    val ndef = Ndef.get(tag)
                    if (ndef != null) {
                        ndef.connect()

                        if (!ndef.isWritable) {
                            errorMessage = "Tag is not writable"
                        } else {
                            // Write an empty NDEF message to erase the tag
                            val emptyRecord = NdefRecord(
                                NdefRecord.TNF_EMPTY,
                                ByteArray(0),
                                ByteArray(0),
                                ByteArray(0)
                            )
                            val emptyMessage = NdefMessage(arrayOf(emptyRecord))
                            ndef.writeNdefMessage(emptyMessage)
                            success = true
                            Log.d(TAG, "Successfully wrote empty NDEF message")
                        }
                        ndef.close()
                    } else {
                        // Try NdefFormatable
                        val formatable = NdefFormatable.get(tag)
                        if (formatable != null) {
                            formatable.connect()
                            // Format with empty NDEF message
                            val emptyRecord = NdefRecord(
                                NdefRecord.TNF_EMPTY,
                                ByteArray(0),
                                ByteArray(0),
                                ByteArray(0)
                            )
                            val emptyMessage = NdefMessage(arrayOf(emptyRecord))
                            formatable.format(emptyMessage)
                            success = true
                            formatable.close()
                            Log.d(TAG, "Successfully formatted tag with empty NDEF")
                        } else {
                            errorMessage = "Tag is not NDEF compatible"
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error formatting tag", e)
            errorMessage = e.message ?: "Unknown error"
        }

        // Send callback to Flutter
        runOnUiThread {
            methodChannel?.invokeMethod("onTagFormatted", mapOf(
                "success" to success,
                "error" to errorMessage
            ))
        }
    }

    /**
     * Erase all writable memory pages on Mifare Ultralight tags
     * Pages 4+ are user writable (pages 0-3 contain UID, lock bits, OTP)
     */
    private fun eraseUltralightMemory(ultralight: MifareUltralight): Boolean {
        return try {
            ultralight.connect()

            // Determine number of pages based on tag type
            val totalPages = when (ultralight.type) {
                MifareUltralight.TYPE_ULTRALIGHT -> 16      // Ultralight: 16 pages (64 bytes)
                MifareUltralight.TYPE_ULTRALIGHT_C -> 48    // Ultralight C: 48 pages (192 bytes)
                else -> 45                                  // NTAG: typically 45 pages for NTAG213
            }

            // User data starts at page 4 (pages 0-3 are manufacturer data/lock bits)
            // For NTAG, we also need to preserve the last few pages (config/password)
            val startPage = 4
            val endPage = when (ultralight.type) {
                MifareUltralight.TYPE_ULTRALIGHT -> 15      // Last user page for Ultralight
                MifareUltralight.TYPE_ULTRALIGHT_C -> 39    // Last user page for Ultralight C
                else -> totalPages - 5                      // Leave config pages for NTAG
            }

            // Empty 4-byte page
            val emptyPage = ByteArray(4) { 0x00 }

            var pagesErased = 0
            for (page in startPage..endPage) {
                try {
                    ultralight.writePage(page, emptyPage)
                    pagesErased++
                } catch (e: Exception) {
                    Log.w(TAG, "Could not erase page $page: ${e.message}")
                    // Continue trying other pages
                }
            }

            ultralight.close()
            Log.d(TAG, "Erased $pagesErased pages on Ultralight tag")
            pagesErased > 0
        } catch (e: Exception) {
            Log.e(TAG, "Error erasing Ultralight memory", e)
            try { ultralight.close() } catch (_: Exception) {}
            false
        }
    }

    /**
     * Erase all accessible sectors on Mifare Classic tags
     * Note: Requires default keys or known keys for authentication
     */
    private fun eraseClassicMemory(classic: MifareClassic): Boolean {
        return try {
            classic.connect()

            val defaultKeyA = MifareClassic.KEY_DEFAULT
            val defaultKeyB = MifareClassic.KEY_DEFAULT
            val nfcForumKey = byteArrayOf(0xD3.toByte(), 0xF7.toByte(), 0xD3.toByte(), 0xF7.toByte(), 0xD3.toByte(), 0xF7.toByte())

            var sectorsErased = 0
            val emptyBlock = ByteArray(16) { 0x00 }

            for (sector in 0 until classic.sectorCount) {
                var authenticated = false

                // Try different keys for authentication
                val keysToTry = listOf(defaultKeyA, nfcForumKey, defaultKeyB)
                for (key in keysToTry) {
                    try {
                        if (classic.authenticateSectorWithKeyA(sector, key)) {
                            authenticated = true
                            break
                        }
                    } catch (_: Exception) {}

                    try {
                        if (classic.authenticateSectorWithKeyB(sector, key)) {
                            authenticated = true
                            break
                        }
                    } catch (_: Exception) {}
                }

                if (authenticated) {
                    val blockCount = classic.getBlockCountInSector(sector)
                    val firstBlock = classic.sectorToBlock(sector)

                    // Erase all blocks except the sector trailer (last block)
                    for (blockIndex in 0 until blockCount - 1) {
                        val blockNumber = firstBlock + blockIndex
                        // Skip block 0 (manufacturer block on sector 0)
                        if (blockNumber == 0) continue

                        try {
                            classic.writeBlock(blockNumber, emptyBlock)
                        } catch (e: Exception) {
                            Log.w(TAG, "Could not erase block $blockNumber: ${e.message}")
                        }
                    }
                    sectorsErased++
                }
            }

            classic.close()
            Log.d(TAG, "Erased $sectorsErased sectors on Classic tag")
            sectorsErased > 0
        } catch (e: Exception) {
            Log.e(TAG, "Error erasing Classic memory", e)
            try { classic.close() } catch (_: Exception) {}
            false
        }
    }

    private fun readFromTag(tag: Tag, intent: Intent) {
        val tagInfo = mutableMapOf<String, Any?>()

        // Tag ID
        tagInfo["id"] = bytesToHex(tag.id)
        tagInfo["techList"] = tag.techList.toList()

        // Try to read NDEF data
        val ndef = Ndef.get(tag)
        if (ndef != null) {
            try {
                ndef.connect()
                val ndefMessage = ndef.cachedNdefMessage ?: ndef.ndefMessage
                if (ndefMessage != null) {
                    tagInfo["ndefMessage"] = parseNdefMessage(ndefMessage)
                }
                tagInfo["ndefType"] = ndef.type
                tagInfo["ndefMaxSize"] = ndef.maxSize
                tagInfo["ndefCanMakeReadOnly"] = ndef.canMakeReadOnly()
                tagInfo["ndefIsWritable"] = ndef.isWritable
                ndef.close()
            } catch (e: Exception) {
                tagInfo["error"] = e.message
            }
        }

        // Read tech-specific info
        readTechSpecificInfo(tag, tagInfo)

        // Send to Flutter
        runOnUiThread {
            methodChannel?.invokeMethod("onTagRead", tagInfo)
        }
    }

    private fun readTechSpecificInfo(tag: Tag, tagInfo: MutableMap<String, Any?>) {
        // NfcA (ISO 14443-3A)
        NfcA.get(tag)?.let { nfcA ->
            try {
                nfcA.connect()
                tagInfo["nfcA"] = mapOf(
                    "sak" to nfcA.sak.toInt(),
                    "atqa" to bytesToHex(nfcA.atqa),
                    "maxTransceiveLength" to nfcA.maxTransceiveLength
                )
                nfcA.close()
            } catch (e: Exception) {
                // Ignore
            }
        }

        // NfcB (ISO 14443-3B)
        NfcB.get(tag)?.let { nfcB ->
            try {
                nfcB.connect()
                tagInfo["nfcB"] = mapOf(
                    "applicationData" to bytesToHex(nfcB.applicationData),
                    "protocolInfo" to bytesToHex(nfcB.protocolInfo),
                    "maxTransceiveLength" to nfcB.maxTransceiveLength
                )
                nfcB.close()
            } catch (e: Exception) {
                // Ignore
            }
        }

        // NfcF (FeliCa)
        NfcF.get(tag)?.let { nfcF ->
            try {
                nfcF.connect()
                tagInfo["nfcF"] = mapOf(
                    "manufacturer" to bytesToHex(nfcF.manufacturer),
                    "systemCode" to bytesToHex(nfcF.systemCode),
                    "maxTransceiveLength" to nfcF.maxTransceiveLength
                )
                nfcF.close()
            } catch (e: Exception) {
                // Ignore
            }
        }

        // NfcV (ISO 15693)
        NfcV.get(tag)?.let { nfcV ->
            try {
                nfcV.connect()
                tagInfo["nfcV"] = mapOf(
                    "dsfId" to nfcV.dsfId.toInt(),
                    "responseFlags" to nfcV.responseFlags.toInt(),
                    "maxTransceiveLength" to nfcV.maxTransceiveLength
                )
                nfcV.close()
            } catch (e: Exception) {
                // Ignore
            }
        }

        // IsoDep (ISO 14443-4)
        IsoDep.get(tag)?.let { isoDep ->
            try {
                isoDep.connect()
                tagInfo["isoDep"] = mapOf(
                    "historicalBytes" to (isoDep.historicalBytes?.let { bytesToHex(it) }),
                    "hiLayerResponse" to (isoDep.hiLayerResponse?.let { bytesToHex(it) }),
                    "maxTransceiveLength" to isoDep.maxTransceiveLength,
                    "isExtendedLengthApduSupported" to isoDep.isExtendedLengthApduSupported
                )
                isoDep.close()
            } catch (e: Exception) {
                // Ignore
            }
        }

        // MifareClassic
        MifareClassic.get(tag)?.let { mifare ->
            try {
                mifare.connect()
                tagInfo["mifareClassic"] = mapOf(
                    "type" to when (mifare.type) {
                        MifareClassic.TYPE_CLASSIC -> "Classic"
                        MifareClassic.TYPE_PLUS -> "Plus"
                        MifareClassic.TYPE_PRO -> "Pro"
                        else -> "Unknown"
                    },
                    "size" to mifare.size,
                    "sectorCount" to mifare.sectorCount,
                    "blockCount" to mifare.blockCount,
                    "maxTransceiveLength" to mifare.maxTransceiveLength
                )
                mifare.close()
            } catch (e: Exception) {
                // Ignore
            }
        }

        // MifareUltralight
        MifareUltralight.get(tag)?.let { ultralight ->
            try {
                ultralight.connect()
                tagInfo["mifareUltralight"] = mapOf(
                    "type" to when (ultralight.type) {
                        MifareUltralight.TYPE_ULTRALIGHT -> "Ultralight"
                        MifareUltralight.TYPE_ULTRALIGHT_C -> "Ultralight C"
                        else -> "Unknown"
                    },
                    "maxTransceiveLength" to ultralight.maxTransceiveLength
                )
                ultralight.close()
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    private fun writeToTag(tag: Tag, data: String) {
        var success = false
        var errorMessage: String? = null

        Log.d(TAG, "writeToTag called with data=$data, typeToWrite=$typeToWrite")

        try {
            // Parse the data as JSON to get type and content
            val dataMap = try {
                val json = org.json.JSONObject(data)
                // Use typeToWrite if available, otherwise try to get from JSON, fallback to "text"
                val type = typeToWrite ?: json.optString("type").ifEmpty { "text" }
                Log.d(TAG, "Writing NDEF record with type: $type")
                mapOf(
                    "type" to type,
                    "url" to json.optString("url"),
                    "text" to json.optString("text"),
                    "phone" to json.optString("phone"),
                    "email" to json.optString("email"),
                    "subject" to json.optString("subject"),
                    "body" to json.optString("body"),
                    "ssid" to json.optString("ssid"),
                    "password" to json.optString("password"),
                    "authType" to json.optString("authType"),
                    "hidden" to json.optBoolean("hidden", false),
                    "firstName" to json.optString("firstName"),
                    "lastName" to json.optString("lastName"),
                    "organization" to json.optString("organization"),
                    "title" to json.optString("title"),
                    "website" to json.optString("website")
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing JSON, falling back to text", e)
                // Fallback: treat as plain text
                mapOf("type" to (typeToWrite ?: "text"), "text" to data)
            }

            val ndef = Ndef.get(tag)
            if (ndef != null) {
                ndef.connect()

                if (!ndef.isWritable) {
                    errorMessage = "Tag is not writable"
                } else {
                    val record = createNdefRecord(dataMap)
                    val message = NdefMessage(arrayOf(record))

                    if (message.toByteArray().size > ndef.maxSize) {
                        errorMessage = "Data too large for tag (max: ${ndef.maxSize} bytes)"
                    } else {
                        ndef.writeNdefMessage(message)
                        success = true
                        Log.d(TAG, "Successfully wrote NDEF message to tag")
                    }
                }
                ndef.close()
            } else {
                // Try to format the tag
                val ndefFormatable = NdefFormatable.get(tag)
                if (ndefFormatable != null) {
                    ndefFormatable.connect()
                    val record = createNdefRecord(dataMap)
                    val message = NdefMessage(arrayOf(record))
                    ndefFormatable.format(message)
                    ndefFormatable.close()
                    success = true
                    Log.d(TAG, "Successfully formatted and wrote to tag")
                } else {
                    errorMessage = "Tag does not support NDEF"
                }
            }
        } catch (e: Exception) {
            errorMessage = e.message ?: "Unknown error"
            Log.e(TAG, "Error writing to tag", e)
        }

        // Send result to Flutter
        runOnUiThread {
            methodChannel?.invokeMethod("onTagWritten", mapOf(
                "success" to success,
                "error" to errorMessage
            ))
        }
    }

    private fun createNdefRecord(dataMap: Map<String, Any?>): NdefRecord {
        return when (dataMap["type"] as? String) {
            "url" -> {
                val url = dataMap["url"] as? String ?: ""
                NdefRecord.createUri(url)
            }
            "phone" -> {
                val phone = dataMap["phone"] as? String ?: ""
                NdefRecord.createUri("tel:$phone")
            }
            "email" -> {
                val email = dataMap["email"] as? String ?: ""
                val subject = dataMap["subject"] as? String ?: ""
                val body = dataMap["body"] as? String ?: ""
                val mailtoUri = if (subject.isNotEmpty() || body.isNotEmpty()) {
                    "mailto:$email?subject=$subject&body=$body"
                } else {
                    "mailto:$email"
                }
                NdefRecord.createUri(mailtoUri)
            }
            "sms" -> {
                val phone = dataMap["phone"] as? String ?: ""
                val message = dataMap["message"] as? String ?: ""
                val smsUri = if (message.isNotEmpty()) {
                    "sms:$phone?body=$message"
                } else {
                    "sms:$phone"
                }
                NdefRecord.createUri(smsUri)
            }
            "wifi" -> {
                val ssid = dataMap["ssid"] as? String ?: ""
                val password = dataMap["password"] as? String ?: ""
                val authType = dataMap["authType"] as? String ?: "WPA"
                val hidden = dataMap["hidden"] as? Boolean ?: false

                val wifiString = buildWifiString(ssid, password, authType, hidden)
                NdefRecord.createMime("application/vnd.wfa.wsc", wifiString.toByteArray())
            }
            "vcard" -> {
                val vcard = buildVCard(dataMap)
                NdefRecord.createMime("text/vcard", vcard.toByteArray())
            }
            else -> {
                val text = dataMap["text"] as? String ?: ""
                NdefRecord.createTextRecord("en", text)
            }
        }
    }

    private fun buildWifiString(ssid: String, password: String, authType: String, hidden: Boolean): String {
        return "WIFI:T:${authType.uppercase()};S:$ssid;P:$password;H:${if (hidden) "true" else "false"};;"
    }

    private fun buildVCard(dataMap: Map<String, Any?>): String {
        val firstName = dataMap["firstName"] as? String ?: ""
        val lastName = dataMap["lastName"] as? String ?: ""
        val organization = dataMap["organization"] as? String ?: ""
        val title = dataMap["title"] as? String ?: ""
        val phone = dataMap["phone"] as? String ?: ""
        val email = dataMap["email"] as? String ?: ""
        val website = dataMap["website"] as? String ?: ""

        val vcard = StringBuilder()
        vcard.append("BEGIN:VCARD\r\n")
        vcard.append("VERSION:3.0\r\n")
        vcard.append("FN:$firstName $lastName\r\n")
        if (lastName.isNotEmpty()) vcard.append("N:$lastName;$firstName;;;\r\n")
        if (organization.isNotEmpty()) vcard.append("ORG:$organization\r\n")
        if (title.isNotEmpty()) vcard.append("TITLE:$title\r\n")
        if (phone.isNotEmpty()) vcard.append("TEL:$phone\r\n")
        if (email.isNotEmpty()) vcard.append("EMAIL:$email\r\n")
        if (website.isNotEmpty()) vcard.append("URL:$website\r\n")
        vcard.append("END:VCARD\r\n")

        return vcard.toString()
    }

    private fun parseNdefMessage(message: NdefMessage): List<Map<String, Any?>> {
        return message.records.map { record ->
            mapOf(
                "tnf" to record.tnf.toInt(),
                "type" to bytesToHex(record.type),
                "typeString" to String(record.type, Charsets.US_ASCII),
                "id" to bytesToHex(record.id),
                "payload" to bytesToHex(record.payload),
                "payloadString" to parseNdefPayload(record)
            )
        }
    }

    private fun parseNdefPayload(record: NdefRecord): String? {
        return when (record.tnf) {
            NdefRecord.TNF_WELL_KNOWN -> {
                when {
                    record.type.contentEquals(NdefRecord.RTD_TEXT) -> {
                        parseTextRecord(record.payload)
                    }
                    record.type.contentEquals(NdefRecord.RTD_URI) -> {
                        parseUriRecord(record.payload)
                    }
                    else -> null
                }
            }
            NdefRecord.TNF_ABSOLUTE_URI -> {
                String(record.payload, Charsets.UTF_8)
            }
            NdefRecord.TNF_MIME_MEDIA -> {
                String(record.payload, Charsets.UTF_8)
            }
            else -> null
        }
    }

    private fun parseTextRecord(payload: ByteArray): String? {
        if (payload.isEmpty()) return null

        val statusByte = payload[0].toInt()
        val languageCodeLength = statusByte and 0x3F
        val textEncoding = if ((statusByte and 0x80) != 0) Charsets.UTF_16 else Charsets.UTF_8

        return if (payload.size > languageCodeLength + 1) {
            String(payload, languageCodeLength + 1, payload.size - languageCodeLength - 1, textEncoding)
        } else null
    }

    private fun parseUriRecord(payload: ByteArray): String? {
        if (payload.isEmpty()) return null

        val prefixCode = payload[0].toInt()
        val prefix = URI_PREFIXES.getOrElse(prefixCode) { "" }
        val uri = String(payload, 1, payload.size - 1, Charsets.UTF_8)

        return prefix + uri
    }

    private fun bytesToHex(bytes: ByteArray): String {
        return bytes.joinToString("") { "%02X".format(it) }
    }

    companion object {
        private val URI_PREFIXES = mapOf(
            0x00 to "",
            0x01 to "http://www.",
            0x02 to "https://www.",
            0x03 to "http://",
            0x04 to "https://",
            0x05 to "tel:",
            0x06 to "mailto:",
            0x07 to "ftp://anonymous:anonymous@",
            0x08 to "ftp://ftp.",
            0x09 to "ftps://",
            0x0A to "sftp://",
            0x0B to "smb://",
            0x0C to "nfs://",
            0x0D to "ftp://",
            0x0E to "dav://",
            0x0F to "news:",
            0x10 to "telnet://",
            0x11 to "imap:",
            0x12 to "rtsp://",
            0x13 to "urn:",
            0x14 to "pop:",
            0x15 to "sip:",
            0x16 to "sips:",
            0x17 to "tftp:",
            0x18 to "btspp://",
            0x19 to "btl2cap://",
            0x1A to "btgoep://",
            0x1B to "tcpobex://",
            0x1C to "irdaobex://",
            0x1D to "file://",
            0x1E to "urn:epc:id:",
            0x1F to "urn:epc:tag:",
            0x20 to "urn:epc:pat:",
            0x21 to "urn:epc:raw:",
            0x22 to "urn:epc:",
            0x23 to "urn:nfc:"
        )
    }
}
