package com.cardscontrol.app.hce

import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.nfc.NfcAdapter
import android.nfc.cardemulation.CardEmulation
import android.os.Build
import android.util.Log

/**
 * Gestionnaire HCE (Host Card Emulation) optimisé pour une détection rapide
 *
 * Cette classe gère l'activation/désactivation de l'émulation de carte
 * et la configuration des données à émuler avec écriture synchrone.
 *
 * Optimisations:
 * - Utilise commit() au lieu de apply() pour écriture synchrone immédiate
 * - Pré-charge les données dans CardEmulationService.cache
 * - Gestion thread-safe des données
 */
class HceManager private constructor(private val context: Context) {

    companion object {
        private const val TAG = "HceManager"

        @Volatile
        private var instance: HceManager? = null

        fun getInstance(context: Context): HceManager {
            return instance ?: synchronized(this) {
                instance ?: HceManager(context.applicationContext).also { instance = it }
            }
        }
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(
        CardEmulationService.PREFS_NAME,
        Context.MODE_PRIVATE
    )

    private val nfcAdapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(context)
    private val cardEmulation: CardEmulation? = nfcAdapter?.let {
        CardEmulation.getInstance(it)
    }

    /**
     * Vérifie si le HCE est disponible sur l'appareil
     */
    fun isHceSupported(): Boolean {
        return nfcAdapter != null &&
                context.packageManager.hasSystemFeature("android.hardware.nfc.hce")
    }

    /**
     * Vérifie si le service HCE est le service de paiement par défaut
     */
    fun isDefaultService(): Boolean {
        if (cardEmulation == null) return false

        val componentName = ComponentName(context, CardEmulationService::class.java)
        return cardEmulation.isDefaultServiceForCategory(
            componentName,
            CardEmulation.CATEGORY_OTHER
        )
    }

    /**
     * Configure les données de la carte de visite à émuler
     * Utilise commit() pour écriture synchrone et met à jour le cache immédiatement
     */
    fun setBusinessCardData(cardId: String, cardUrl: String, vCardData: String? = null): Boolean {
        return try {
            // Écriture SYNCHRONE avec commit() au lieu de apply()
            val success = prefs.edit()
                .putString(CardEmulationService.KEY_CARD_DATA, vCardData ?: "")
                .putString(CardEmulationService.KEY_CARD_URL, cardUrl)
                .putBoolean(CardEmulationService.KEY_ENABLED, true)
                .commit() // commit() est synchrone, apply() est asynchrone

            if (success) {
                // Mettre à jour le cache statique immédiatement
                CardEmulationService.updateCachedUrl(cardUrl)
                Log.d(TAG, "Business card data set (sync): $cardUrl")
            }

            success
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set business card data", e)
            false
        }
    }

    /**
     * Pré-charge les données dans le cache du service
     * Doit être appelé avant de démarrer l'émulation
     */
    fun preloadEmulationData() {
        CardEmulationService.preloadData(context)
    }

    /**
     * Récupère l'URL de la carte configurée
     */
    fun getConfiguredCardUrl(): String? {
        return prefs.getString(CardEmulationService.KEY_CARD_URL, null)
    }

    /**
     * Vérifie si l'émulation est activée
     */
    fun isEmulationEnabled(): Boolean {
        return prefs.getBoolean(CardEmulationService.KEY_ENABLED, false)
    }

    /**
     * Active ou désactive l'émulation
     * Utilise commit() pour écriture synchrone
     */
    fun setEmulationEnabled(enabled: Boolean): Boolean {
        return prefs.edit()
            .putBoolean(CardEmulationService.KEY_ENABLED, enabled)
            .commit()
    }

    /**
     * Efface toutes les données HCE
     * Utilise commit() pour écriture synchrone
     */
    fun clearData(): Boolean {
        return prefs.edit().clear().commit()
    }

    /**
     * Récupère les informations sur le HCE
     */
    fun getHceInfo(): Map<String, Any> {
        return mapOf(
            "isSupported" to isHceSupported(),
            "isEnabled" to isEmulationEnabled(),
            "isDefaultService" to isDefaultService(),
            "configuredUrl" to (getConfiguredCardUrl() ?: ""),
            "nfcEnabled" to (nfcAdapter?.isEnabled == true)
        )
    }
}
