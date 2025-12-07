package com.cardscontrol.app.hce

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.nfc.cardemulation.HostApduService
import android.os.Build
import android.os.Bundle
import android.util.Log
import java.util.Arrays

/**
 * Service HCE (Host Card Emulation) optimisé pour une détection ultra-rapide
 *
 * Ce service permet au téléphone de se comporter comme une carte NFC
 * et de répondre aux lecteurs NFC externes avec une latence minimale.
 *
 * Optimisations appliquées:
 * - Cache mémoire volatil pour réponses instantanées
 * - Pré-calcul des réponses APDU courantes
 * - Élimination des allocations dans les chemins critiques
 * - SharedPreferences lu une seule fois au démarrage
 */
class CardEmulationService : HostApduService() {

    companion object {
        private const val TAG = "HCE"
        private const val DEBUG = false // Désactiver les logs en production

        // Status words ISO 7816-4 - pré-alloués pour éviter les allocations
        private val SW_OK = byteArrayOf(0x90.toByte(), 0x00)
        private val SW_UNKNOWN = byteArrayOf(0x6F.toByte(), 0x00)
        private val SW_CLA_NOT_SUPPORTED = byteArrayOf(0x6E.toByte(), 0x00)
        private val SW_INS_NOT_SUPPORTED = byteArrayOf(0x6D.toByte(), 0x00)
        private val SW_WRONG_LENGTH = byteArrayOf(0x67.toByte(), 0x00)
        private val SW_FILE_NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())
        private val SW_CONDITIONS_NOT_SATISFIED = byteArrayOf(0x69.toByte(), 0x85.toByte())

        // APDU Instructions
        private const val SELECT_INS = 0xA4.toByte()
        private const val READ_BINARY_INS = 0xB0.toByte()

        // AIDs pré-compilés pour comparaison rapide
        val AID_NFCPRO = byteArrayOf(
            0xF0.toByte(), 0x4E, 0x46, 0x43, 0x50, 0x52, 0x4F
        )
        val AID_NDEF = byteArrayOf(
            0xD2.toByte(), 0x76, 0x00, 0x00, 0x85.toByte(), 0x01, 0x01
        )

        // File IDs
        private val NDEF_CC_FILE = byteArrayOf(0xE1.toByte(), 0x03)
        private val NDEF_DATA_FILE = byteArrayOf(0xE1.toByte(), 0x04)

        // SharedPreferences
        const val PREFS_NAME = "nfcpro_hce"
        const val KEY_CARD_DATA = "card_data"
        const val KEY_CARD_URL = "card_url"
        const val KEY_ENABLED = "enabled"

        // Broadcast action pour recharger les données
        const val ACTION_RELOAD_DATA = "com.cardscontrol.app.hce.RELOAD_DATA"

        // Cache statique global pour un accès ultra-rapide entre instances
        @Volatile
        private var cachedNdefMessage: ByteArray? = null
        @Volatile
        private var cachedCapabilityContainer: ByteArray? = null
        @Volatile
        private var cacheInitialized = false

        /**
         * Pré-charge les données dans le cache statique
         * Appelé depuis MainActivity avant de démarrer l'émulation
         */
        @JvmStatic
        fun preloadData(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            val cardUrl = prefs.getString(KEY_CARD_URL, null) ?: "https://cards-control.app"

            cachedNdefMessage = createNdefUrlMessageStatic(cardUrl)
            cachedCapabilityContainer = createCapabilityContainerStatic(cachedNdefMessage!!.size)
            cacheInitialized = true

            if (DEBUG) Log.d(TAG, "Data preloaded: $cardUrl (${cachedNdefMessage!!.size} bytes)")
        }

        /**
         * Met à jour le cache avec une nouvelle URL
         */
        @JvmStatic
        fun updateCachedUrl(url: String) {
            cachedNdefMessage = createNdefUrlMessageStatic(url)
            cachedCapabilityContainer = createCapabilityContainerStatic(cachedNdefMessage!!.size)
            cacheInitialized = true
            if (DEBUG) Log.d(TAG, "Cache updated: $url")
        }

        /**
         * Version statique de createNdefUrlMessage pour le pré-chargement
         */
        private fun createNdefUrlMessageStatic(url: String): ByteArray {
            val uriRecord = createUriRecordStatic(url)
            val messageLength = uriRecord.size
            val ndefMessage = ByteArray(2 + messageLength)
            ndefMessage[0] = ((messageLength shr 8) and 0xFF).toByte()
            ndefMessage[1] = (messageLength and 0xFF).toByte()
            System.arraycopy(uriRecord, 0, ndefMessage, 2, uriRecord.size)
            return ndefMessage
        }

        private fun createUriRecordStatic(url: String): ByteArray {
            val (prefixCode, remainder) = getUriPrefixStatic(url)
            val uriBytes = remainder.toByteArray(Charsets.UTF_8)
            val payloadLength = 1 + uriBytes.size

            val record = ByteArray(3 + 1 + payloadLength)
            var offset = 0
            record[offset++] = 0xD1.toByte() // MB, ME, SR, TNF=Well-known
            record[offset++] = 0x01 // Type length
            record[offset++] = payloadLength.toByte()
            record[offset++] = 0x55 // 'U' for URI
            record[offset++] = prefixCode.toByte()
            System.arraycopy(uriBytes, 0, record, offset, uriBytes.size)
            return record
        }

        private fun getUriPrefixStatic(url: String): Pair<Int, String> {
            return when {
                url.startsWith("https://www.") -> Pair(0x02, url.removePrefix("https://www."))
                url.startsWith("http://www.") -> Pair(0x01, url.removePrefix("http://www."))
                url.startsWith("https://") -> Pair(0x04, url.removePrefix("https://"))
                url.startsWith("http://") -> Pair(0x03, url.removePrefix("http://"))
                url.startsWith("tel:") -> Pair(0x05, url.removePrefix("tel:"))
                url.startsWith("mailto:") -> Pair(0x06, url.removePrefix("mailto:"))
                else -> Pair(0x00, url)
            }
        }

        private fun createCapabilityContainerStatic(ndefSize: Int): ByteArray {
            return byteArrayOf(
                0x00, 0x0F,              // CCLEN = 15 bytes
                0x20,                     // Mapping version 2.0
                0x00, 0x7F,              // MLe = 127 bytes (augmenté pour lecture plus rapide)
                0x00, 0x7F,              // MLc = 127 bytes
                0x04,                     // T: NDEF File Control
                0x06,                     // L: 6 bytes
                0xE1.toByte(), 0x04,     // File ID
                ((ndefSize + 2) shr 8).toByte(),
                ((ndefSize + 2) and 0xFF).toByte(),
                0x00,                     // Read access: no security
                0xFF.toByte()            // Write access: no write
            )
        }
    }

    // État de la sélection de fichier - utilise des indices pour éviter les allocations
    private var selectedFileType = FILE_NONE

    // Cache local pour les réponses pré-calculées
    @Volatile private var localNdefMessage: ByteArray? = null
    @Volatile private var localCapabilityContainer: ByteArray? = null

    // BroadcastReceiver pour recharger les données à la demande
    private val reloadReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (DEBUG) Log.d(TAG, "Reload broadcast received")
            loadCardDataImmediate()
        }
    }

    override fun onCreate() {
        super.onCreate()
        if (DEBUG) Log.d(TAG, "Service created")

        // Charger immédiatement les données en cache local
        loadCardDataImmediate()

        // Enregistrer le BroadcastReceiver
        val filter = IntentFilter(ACTION_RELOAD_DATA)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(reloadReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(reloadReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(reloadReceiver)
        } catch (e: Exception) {
            // Ignorer
        }
    }

    /**
     * Charge les données immédiatement depuis le cache statique ou SharedPreferences
     */
    private fun loadCardDataImmediate() {
        // Utiliser le cache statique s'il est disponible (plus rapide)
        if (cacheInitialized && cachedNdefMessage != null && cachedCapabilityContainer != null) {
            localNdefMessage = cachedNdefMessage
            localCapabilityContainer = cachedCapabilityContainer
            if (DEBUG) Log.d(TAG, "Using static cache")
            return
        }

        // Sinon, charger depuis SharedPreferences de manière synchrone
        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val cardUrl = prefs.getString(KEY_CARD_URL, null) ?: "https://cards-control.app"

        localNdefMessage = createNdefUrlMessageStatic(cardUrl)
        localCapabilityContainer = createCapabilityContainerStatic(localNdefMessage!!.size)

        // Mettre à jour le cache statique
        cachedNdefMessage = localNdefMessage
        cachedCapabilityContainer = localCapabilityContainer
        cacheInitialized = true

        if (DEBUG) Log.d(TAG, "Loaded from prefs: $cardUrl")
    }

    /**
     * Traite les commandes APDU reçues - CHEMIN CRITIQUE OPTIMISÉ
     */
    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        // Vérification minimale de la longueur
        if (commandApdu.size < 4) {
            return SW_WRONG_LENGTH
        }

        // Extraction rapide des champs APDU
        val ins = commandApdu[1]

        return when (ins) {
            SELECT_INS -> handleSelectFast(commandApdu)
            READ_BINARY_INS -> handleReadBinaryFast(commandApdu)
            else -> SW_INS_NOT_SUPPORTED
        }
    }

    /**
     * Gestion optimisée de SELECT - évite les allocations inutiles
     */
    private fun handleSelectFast(apdu: ByteArray): ByteArray {
        if (apdu.size < 5) return SW_WRONG_LENGTH

        val p1 = apdu[2]
        val lc = apdu[4].toInt() and 0xFF

        if (apdu.size < 5 + lc) return SW_WRONG_LENGTH

        // SELECT by AID (P1 = 0x04)
        if (p1 == 0x04.toByte()) {
            // Comparaison rapide inline des AIDs
            if (lc == 7) {
                // Check NDEF AID
                if (apdu[5] == 0xD2.toByte() && apdu[6] == 0x76.toByte() &&
                    apdu[7] == 0x00.toByte() && apdu[8] == 0x00.toByte() &&
                    apdu[9] == 0x85.toByte() && apdu[10] == 0x01.toByte() &&
                    apdu[11] == 0x01.toByte()) {
                    selectedFileType = FILE_NONE
                    if (DEBUG) Log.d(TAG, "NDEF AID selected")
                    return SW_OK
                }
                // Check NFCPRO AID
                if (apdu[5] == 0xF0.toByte() && apdu[6] == 0x4E.toByte() &&
                    apdu[7] == 0x46.toByte() && apdu[8] == 0x43.toByte() &&
                    apdu[9] == 0x50.toByte() && apdu[10] == 0x52.toByte() &&
                    apdu[11] == 0x4F.toByte()) {
                    selectedFileType = FILE_NONE
                    if (DEBUG) Log.d(TAG, "NFCPRO AID selected")
                    return SW_OK
                }
            }
            return SW_FILE_NOT_FOUND
        }

        // SELECT by File ID (P1 = 0x00)
        if (p1 == 0x00.toByte() && lc == 2) {
            // CC file: E103
            if (apdu[5] == 0xE1.toByte() && apdu[6] == 0x03.toByte()) {
                selectedFileType = FILE_CC
                if (DEBUG) Log.d(TAG, "CC file selected")
                return SW_OK
            }
            // NDEF file: E104
            if (apdu[5] == 0xE1.toByte() && apdu[6] == 0x04.toByte()) {
                selectedFileType = FILE_NDEF
                if (DEBUG) Log.d(TAG, "NDEF file selected")
                return SW_OK
            }
            return SW_FILE_NOT_FOUND
        }

        return SW_CLA_NOT_SUPPORTED
    }

    /**
     * Gestion optimisée de READ BINARY - réponse ultra-rapide
     */
    private fun handleReadBinaryFast(apdu: ByteArray): ByteArray {
        // Obtenir le fichier sélectionné depuis le cache local
        val selectedFile = when (selectedFileType) {
            FILE_CC -> localCapabilityContainer
            FILE_NDEF -> localNdefMessage
            else -> null
        }

        if (selectedFile == null) {
            return SW_CONDITIONS_NOT_SATISFIED
        }

        // Calculer offset et longueur
        val offset = ((apdu[2].toInt() and 0xFF) shl 8) or (apdu[3].toInt() and 0xFF)
        val le = if (apdu.size >= 5) apdu[4].toInt() and 0xFF else 0

        if (offset >= selectedFile.size) {
            return SW_WRONG_LENGTH
        }

        val length = if (le == 0) {
            minOf(256, selectedFile.size - offset)
        } else {
            minOf(le, selectedFile.size - offset)
        }

        // Construire la réponse avec le status word
        val response = ByteArray(length + 2)
        System.arraycopy(selectedFile, offset, response, 0, length)
        response[length] = SW_OK[0]
        response[length + 1] = SW_OK[1]

        return response
    }

    override fun onDeactivated(reason: Int) {
        if (DEBUG) Log.d(TAG, "Deactivated: $reason")
        selectedFileType = FILE_NONE
    }
}

// Constantes pour le type de fichier sélectionné (évite les allocations d'objets)
private const val FILE_NONE = 0
private const val FILE_CC = 1
private const val FILE_NDEF = 2
