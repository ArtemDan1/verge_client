package com.singboxclient.verge

import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import org.json.JSONObject

/**
 * Плитка в быстрых настройках: включает и выключает VPN, не открывая
 * приложение. Включает с конфигом последнего успешного подключения.
 *
 * Открывает приложение вместо подключения, когда без него не обойтись: нет
 * разрешения на VPN, ещё ни разу не подключались или последнее подключение
 * шло через Xray (его процесс поднимает приложение).
 */
class VpnTileService : TileService() {
    private val main = Handler(Looper.getMainLooper())

    private val listener = object : VpnState.Listener {
        override fun onStatus(status: VpnState.Status, message: String?) {
            main.post { render() }
        }

        override fun onLog(line: String) {}
    }

    override fun onStartListening() {
        super.onStartListening()
        VpnState.addListener(listener)
        render()
    }

    override fun onStopListening() {
        VpnState.removeListener(listener)
        super.onStopListening()
    }

    override fun onClick() {
        super.onClick()
        when (VpnState.status) {
            VpnState.Status.CONNECTED, VpnState.Status.CONNECTING -> VergeVpnService.stop(this)
            else -> connect()
        }
    }

    private fun connect() {
        val config = runCatching { VergeVpnService.lastConfigFile(this).readText() }.getOrNull()
        if (config.isNullOrBlank() || VpnService.prepare(this) != null || usesXray(config)) {
            openApp()
            return
        }
        Engines.init(this)
        VergeVpnService.start(this, config)
    }

    /** sing-box ходит в Xray socks-outbound'ом на loopback (ConfigBuilder). */
    private fun usesXray(config: String): Boolean = runCatching {
        val outbounds = JSONObject(config).getJSONArray("outbounds")
        (0 until outbounds.length()).any { i ->
            val o = outbounds.getJSONObject(i)
            o.optString("tag") == "proxy" &&
                o.optString("type") == "socks" &&
                o.optString("server") == "127.0.0.1"
        }
    }.getOrDefault(false)

    private fun openApp() {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE),
            )
        } else {
            @Suppress("DEPRECATION", "StartActivityAndCollapseDeprecated")
            startActivityAndCollapse(intent)
        }
    }

    private fun render() {
        val tile = qsTile ?: return
        val status = VpnState.status
        tile.state = when (status) {
            VpnState.Status.CONNECTED, VpnState.Status.CONNECTING -> Tile.STATE_ACTIVE
            else -> Tile.STATE_INACTIVE
        }
        tile.label = "Verge"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = when (status) {
                VpnState.Status.CONNECTED -> getString(R.string.vpn_connected)
                VpnState.Status.CONNECTING -> getString(R.string.vpn_connecting)
                else -> getString(R.string.tile_off)
            }
        }
        tile.updateTile()
    }
}
