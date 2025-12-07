package com.cardscontrol.app.shortcuts

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class ShortcutPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "ShortcutPlugin"
        private const val SHORTCUT_REQUEST_CODE = 1001
    }

    private val shortcutManager: ShortcutManager? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            context.getSystemService(ShortcutManager::class.java)
        } else {
            null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "onMethodCall: ${call.method}")
        when (call.method) {
            "isShortcutSupported" -> {
                val supported = isShortcutSupported()
                Log.d(TAG, "isShortcutSupported: $supported")
                result.success(supported)
            }
            "createShortcut" -> {
                val shortcutId = call.argument<String>("shortcutId")
                val shortcutLabel = call.argument<String>("shortcutLabel")
                val iconPath = call.argument<String>("iconPath")
                val deepLink = call.argument<String>("deepLink")

                Log.d(TAG, "createShortcut: id=$shortcutId, label=$shortcutLabel, icon=$iconPath, link=$deepLink")

                if (shortcutId != null && shortcutLabel != null && deepLink != null) {
                    // Essayer d'abord avec ShortcutManagerCompat (meilleure compatibilité)
                    val success = createShortcutWithCompat(shortcutId, shortcutLabel, iconPath, deepLink)
                    Log.d(TAG, "createShortcut result: $success")
                    result.success(success)
                } else {
                    Log.e(TAG, "createShortcut: missing arguments")
                    result.error("INVALID_ARGUMENT", "shortcutId, shortcutLabel, and deepLink are required", null)
                }
            }
            "removeShortcut" -> {
                val shortcutId = call.argument<String>("shortcutId")
                if (shortcutId != null) {
                    val success = removeShortcut(shortcutId)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "shortcutId is required", null)
                }
            }
            "hasShortcut" -> {
                val shortcutId = call.argument<String>("shortcutId")
                if (shortcutId != null) {
                    val hasShortcut = hasShortcut(shortcutId)
                    result.success(hasShortcut)
                } else {
                    result.error("INVALID_ARGUMENT", "shortcutId is required", null)
                }
            }
            "isMiuiDevice" -> {
                val isMiui = isMiuiDevice()
                Log.d(TAG, "isMiuiDevice: $isMiui")
                result.success(isMiui)
            }
            "openAppSettings" -> {
                openAppSettings()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun isShortcutSupported(): Boolean {
        // Utiliser ShortcutManagerCompat pour une meilleure compatibilité
        return ShortcutManagerCompat.isRequestPinShortcutSupported(context)
    }

    /**
     * Crée un raccourci en utilisant ShortcutManagerCompat (meilleure compatibilité MIUI/Xiaomi)
     */
    private fun createShortcutWithCompat(
        shortcutId: String,
        shortcutLabel: String,
        iconPath: String?,
        deepLink: String
    ): Boolean {
        Log.d(TAG, "createShortcutWithCompat called")

        try {
            // Créer l'intent pour le deep link
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(deepLink)).apply {
                setPackage(context.packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            Log.d(TAG, "Intent created for deepLink: $deepLink")

            // Construire le shortcut avec ShortcutInfoCompat
            val shortcutBuilder = ShortcutInfoCompat.Builder(context, shortcutId)
                .setShortLabel(shortcutLabel)
                .setLongLabel(shortcutLabel)
                .setIntent(intent)

            // Ajouter l'icône si disponible
            var bitmap: Bitmap? = null
            if (iconPath != null) {
                val iconFile = File(iconPath)
                Log.d(TAG, "Icon path: $iconPath, exists: ${iconFile.exists()}")
                if (iconFile.exists()) {
                    bitmap = BitmapFactory.decodeFile(iconPath)
                    if (bitmap != null) {
                        Log.d(TAG, "Bitmap loaded: ${bitmap.width}x${bitmap.height}")
                        shortcutBuilder.setIcon(IconCompat.createWithAdaptiveBitmap(bitmap))
                    } else {
                        Log.e(TAG, "Failed to decode bitmap from $iconPath")
                    }
                }
            }

            // Si pas d'icône personnalisée, utiliser l'icône de l'app
            if (bitmap == null) {
                Log.d(TAG, "Using app icon as fallback")
                shortcutBuilder.setIcon(IconCompat.createWithResource(context, android.R.drawable.ic_menu_share))
            }

            val shortcutInfo = shortcutBuilder.build()
            Log.d(TAG, "ShortcutInfoCompat built successfully")

            // Utiliser ShortcutManagerCompat pour meilleure compatibilité
            val result = ShortcutManagerCompat.requestPinShortcut(context, shortcutInfo, null)
            Log.d(TAG, "ShortcutManagerCompat.requestPinShortcut result: $result")

            // Si ça n'a pas marché, essayer la méthode legacy
            if (!result) {
                Log.d(TAG, "Trying legacy shortcut method...")
                return createLegacyShortcut(shortcutId, shortcutLabel, iconPath, deepLink)
            }

            return result
        } catch (e: Exception) {
            Log.e(TAG, "Exception in createShortcutWithCompat", e)
            e.printStackTrace()
            // Fallback sur la méthode legacy
            return createLegacyShortcut(shortcutId, shortcutLabel, iconPath, deepLink)
        }
    }

    /**
     * Méthode legacy pour créer un raccourci (fonctionne sur certains launchers MIUI)
     */
    @Suppress("DEPRECATION")
    private fun createLegacyShortcut(
        shortcutId: String,
        shortcutLabel: String,
        iconPath: String?,
        deepLink: String
    ): Boolean {
        Log.d(TAG, "createLegacyShortcut called")

        try {
            // Intent qui sera lancé par le raccourci
            val shortcutIntent = Intent(Intent.ACTION_VIEW, Uri.parse(deepLink)).apply {
                setPackage(context.packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }

            // Intent pour installer le raccourci (méthode legacy)
            val addIntent = Intent("com.android.launcher.action.INSTALL_SHORTCUT").apply {
                putExtra(Intent.EXTRA_SHORTCUT_INTENT, shortcutIntent)
                putExtra(Intent.EXTRA_SHORTCUT_NAME, shortcutLabel)
                putExtra("duplicate", false) // Éviter les doublons

                // Ajouter l'icône
                if (iconPath != null) {
                    val iconFile = File(iconPath)
                    if (iconFile.exists()) {
                        val bitmap = BitmapFactory.decodeFile(iconPath)
                        if (bitmap != null) {
                            putExtra(Intent.EXTRA_SHORTCUT_ICON, bitmap)
                        }
                    }
                }
            }

            context.sendBroadcast(addIntent)
            Log.d(TAG, "Legacy shortcut broadcast sent")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Exception in createLegacyShortcut", e)
            e.printStackTrace()
            return false
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createPinnedShortcut(
        shortcutId: String,
        shortcutLabel: String,
        iconPath: String?,
        deepLink: String
    ): Boolean {
        Log.d(TAG, "createPinnedShortcut called")

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            Log.e(TAG, "Android version too old: ${Build.VERSION.SDK_INT}")
            return false
        }

        val shortcutManager = shortcutManager
        if (shortcutManager == null) {
            Log.e(TAG, "ShortcutManager is null")
            return false
        }

        if (!shortcutManager.isRequestPinShortcutSupported) {
            Log.e(TAG, "Pin shortcuts not supported")
            return false
        }

        try {
            // Créer l'intent pour le deep link
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(deepLink)).apply {
                setPackage(context.packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            Log.d(TAG, "Intent created for deepLink: $deepLink")

            // Construire le shortcut
            val shortcutBuilder = ShortcutInfo.Builder(context, shortcutId)
                .setShortLabel(shortcutLabel)
                .setLongLabel(shortcutLabel)
                .setIntent(intent)

            // Ajouter l'icône si disponible
            if (iconPath != null) {
                val iconFile = File(iconPath)
                Log.d(TAG, "Icon path: $iconPath, exists: ${iconFile.exists()}")
                if (iconFile.exists()) {
                    val bitmap = BitmapFactory.decodeFile(iconPath)
                    if (bitmap != null) {
                        Log.d(TAG, "Bitmap loaded: ${bitmap.width}x${bitmap.height}")
                        // Créer une icône adaptative si possible
                        shortcutBuilder.setIcon(Icon.createWithAdaptiveBitmap(bitmap))
                    } else {
                        Log.e(TAG, "Failed to decode bitmap from $iconPath")
                    }
                }
            } else {
                Log.d(TAG, "No icon path provided")
            }

            // Si pas d'icône personnalisée, utiliser l'icône de l'app
            val shortcutInfo = shortcutBuilder.build()
            Log.d(TAG, "ShortcutInfo built successfully")

            // Créer un PendingIntent pour le callback (nécessaire pour certains launchers comme MIUI)
            val callbackIntent = Intent(context, ShortcutResultReceiver::class.java).apply {
                action = "com.cardscontrol.app.SHORTCUT_RESULT"
                putExtra("shortcut_id", shortcutId)
            }

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val successCallback = PendingIntent.getBroadcast(
                context,
                SHORTCUT_REQUEST_CODE,
                callbackIntent,
                flags
            )

            // Demander l'ajout du raccourci avec callback
            val result = shortcutManager.requestPinShortcut(shortcutInfo, successCallback.intentSender)
            Log.d(TAG, "requestPinShortcut result: $result")
            return result
        } catch (e: Exception) {
            Log.e(TAG, "Exception in createPinnedShortcut", e)
            e.printStackTrace()
            return false
        }
    }

    private fun removeShortcut(shortcutId: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) {
            return false
        }

        return try {
            shortcutManager?.disableShortcuts(listOf(shortcutId))
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun hasShortcut(shortcutId: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) {
            return false
        }

        return try {
            shortcutManager?.pinnedShortcuts?.any { it.id == shortcutId } ?: false
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Détecte si l'appareil est un Xiaomi/MIUI
     */
    private fun isMiuiDevice(): Boolean {
        return try {
            val manufacturer = Build.MANUFACTURER.lowercase()
            val brand = Build.BRAND.lowercase()

            manufacturer.contains("xiaomi") ||
            manufacturer.contains("redmi") ||
            manufacturer.contains("poco") ||
            brand.contains("xiaomi") ||
            brand.contains("redmi") ||
            brand.contains("poco") ||
            getMiuiVersion() != null
        } catch (e: Exception) {
            Log.e(TAG, "Error detecting MIUI", e)
            false
        }
    }

    /**
     * Récupère la version de MIUI si présente
     */
    private fun getMiuiVersion(): String? {
        return try {
            @Suppress("PrivateApi")
            val c = Class.forName("android.os.SystemProperties")
            val get = c.getMethod("get", String::class.java)
            val miuiVersion = get.invoke(c, "ro.miui.ui.version.name") as? String
            if (!miuiVersion.isNullOrEmpty()) miuiVersion else null
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Ouvre les paramètres de l'application
     */
    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening app settings", e)
        }
    }
}
