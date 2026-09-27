package com.bondoolai.bondoolai_steps

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restarts background step counting after a reboot or an app update. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                if (StepStore.enabled(context)) StepCounterService.start(context)
            }
        }
    }
}
