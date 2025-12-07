package com.cardscontrol.app.shortcuts

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver to handle shortcut creation result callback
 * This is required for some launchers (like MIUI) to properly show the confirmation dialog
 */
class ShortcutResultReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "ShortcutResultReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val shortcutId = intent.getStringExtra("shortcut_id")
        Log.d(TAG, "Shortcut created successfully: $shortcutId")
    }
}
