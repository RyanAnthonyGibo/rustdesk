package com.carriez.flutter_hbb

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import ffi.FFI
import io.flutter.embedding.android.FlutterActivity

/**
 * StarMDM: o agente Starwind (dono do aparelho) aplica a senha permanente do RyanDesk.
 * Só aceita o broadcast vindo do pacote do Starwind (identidade do remetente, Android 14+).
 * A senha nunca vai para o log.
 */
class StarmdmConfigReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Build.VERSION.SDK_INT < 34 || sentFromPackage != STARWIND) {
            Log.w(TAG, "config recusada: remetente não é o Starwind")
            return
        }
        val pw = intent.getStringExtra("password") ?: return
        val approve = intent.getStringExtra("approve_mode") ?: ""
        val ok = apply(context, pw, approve)
        if (!ok) {
            // guarda para aplicar quando o serviço iniciar (pasta de config ainda desconhecida)
            context.getSharedPreferences(PENDING, Context.MODE_PRIVATE).edit()
                .putString("password", pw).putString("approve_mode", approve).apply()
        }
        Log.i(TAG, "config StarMDM aplicada: $ok")
    }

    companion object {
        private const val TAG = "StarmdmConfig"
        private const val STARWIND = "br.com.cvt.starmdm.agent"
        private const val PENDING = "starmdm_pending"

        fun apply(context: Context, pw: String, approve: String): Boolean {
            val prefs = context.getSharedPreferences(KEY_SHARED_PREFERENCES, FlutterActivity.MODE_PRIVATE)
            val dir = prefs.getString(KEY_APP_DIR_CONFIG_PATH, "") ?: ""
            if (dir.isEmpty()) return false
            return runCatching { FFI.starmdmConfig(dir, pw, approve) }.getOrDefault(false)
        }

        /** Chamado pelo MainService depois do startServer. */
        fun applyPending(context: Context) {
            val sp = context.getSharedPreferences(PENDING, Context.MODE_PRIVATE)
            val pw = sp.getString("password", null) ?: return
            if (apply(context, pw, sp.getString("approve_mode", "") ?: "")) sp.edit().clear().apply()
        }
    }
}
