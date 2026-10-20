package com.singboxclient.verge

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.IpPrefix
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.RoutePrefix
import io.nekohasekai.libbox.TunOptions
import java.net.InetAddress
import java.util.concurrent.Executors

/**
 * VPN-сервис: держит TUN и боевой экземпляр sing-box.
 *
 * Своё приложение исключено из туннеля (addDisallowedApplication). Так
 * соединения самого sing-box, Xray, проверки подписок и замеры пинга идут
 * мимо VPN — это и защита от петли, и «честный» пинг до серверов.
 */
class VergeVpnService : VpnService() {
    companion object {
        const val ACTION_START = "com.singboxclient.verge.START"
        const val ACTION_STOP = "com.singboxclient.verge.STOP"
        private const val CHANNEL_ID = "vpn"
        private const val NOTIFICATION_ID = 1

        fun start(context: Context, config: String) {
            VpnState.pendingConfig = config
            val intent = Intent(context, VergeVpnService::class.java).setAction(ACTION_START)
            context.startForegroundService(intent)
        }

        /** Работающий сервис — чтобы обновить уведомление извне. */
        @Volatile
        private var instance: VergeVpnService? = null

        /** Перерисовать уведомление после смены сервера или пинга. */
        fun refreshNotification() {
            val service = instance ?: return
            if (VpnState.status == VpnState.Status.CONNECTED) {
                service.goForeground(service.connectedText())
            }
        }

        /**
         * Конфиг последнего успешного подключения — с ним плитка быстрых
         * настроек включает VPN, не открывая приложение.
         */
        fun lastConfigFile(context: Context) = java.io.File(context.filesDir, "last-config.json")

        fun stop(context: Context) {
            if (VpnState.status == VpnState.Status.DISCONNECTED) return
            val intent = Intent(context, VergeVpnService::class.java).setAction(ACTION_STOP)
            context.startService(intent)
        }
    }

    /** Все операции с движком — последовательно, в одном фоновом потоке. */
    private val worker = Executors.newSingleThreadExecutor()
    private var tunFd: ParcelFileDescriptor? = null

    private val platform = object : BoxPlatform(this) {
        override fun autoDetectInterfaceControl(fd: Int) {
            protect(fd)
        }

        override fun openTun(options: TunOptions): Int = establishTun(options)
    }

    private val engine by lazy {
        BoxEngine(
            this,
            platform,
            "sing-box.log",
            onLog = { VpnState.log(it) },
            onStopRequest = { stopVpn() },
        )
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Engines.init(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> stopVpn(startId)
            else -> startVpn(startId)
        }
        return START_NOT_STICKY
    }

    /**
     * Выполняет [task] в потоке движка. После onDestroy поток уже закрыт —
     * опоздавшая команда просто игнорируется.
     */
    private fun runOnWorker(task: () -> Unit) {
        try {
            worker.execute(task)
        } catch (_: java.util.concurrent.RejectedExecutionException) {
        }
    }

    private fun startVpn(startId: Int) {
        // В течение 5 секунд после startForegroundService сервис обязан стать
        // foreground — до любой долгой работы.
        goForeground(getString(R.string.vpn_connecting))
        val config = VpnState.pendingConfig
        VpnState.pendingConfig = null
        if (config == null) {
            // Например, системный «постоянный VPN» поднял сервис без приложения:
            // конфига нет — подключаться не с чем.
            finish(VpnState.Status.DISCONNECTED, null, startId)
            return
        }
        VpnState.update(VpnState.Status.CONNECTING)
        runOnWorker {
            try {
                // Повторный старт поверх живого туннеля: старый TUN закрываем
                // сами, иначе дескриптор утечёт.
                engine.stop()
                closeTun()
                engine.start(config)
                VpnState.runningConfig = config
                runCatching { lastConfigFile(this).writeText(config) }
                VpnState.update(VpnState.Status.CONNECTED)
                goForeground(connectedText())
            } catch (e: Exception) {
                engine.stop()
                closeTun()
                Engines.xray.stop()
                finish(VpnState.Status.ERROR, e.message ?: e.toString(), startId)
            }
        }
    }

    private fun stopVpn(startId: Int? = null) {
        runOnWorker {
            engine.stop()
            closeTun()
            // Xray боевого подключения без sing-box бесполезен — гасим вместе,
            // как disconnect() на десктопе.
            Engines.xray.stop()
            finish(VpnState.Status.DISCONNECTED, null, startId)
        }
    }

    /**
     * [startId] — команда, после которой сервис можно гасить. stopSelf(id) не
     * остановит сервис, если за ней уже пришёл новый старт.
     */
    private fun finish(status: VpnState.Status, message: String?, startId: Int?) {
        VpnState.update(status, message)
        if (startId != null && !stopSelfResult(startId)) return
        stopForeground(STOP_FOREGROUND_REMOVE)
        if (startId == null) stopSelf()
    }

    override fun onRevoke() {
        // VPN отключили из системы или включили другой VPN.
        stopVpn()
    }

    override fun onDestroy() {
        if (engine.isRunning) {
            engine.stop()
            closeTun()
            VpnState.update(VpnState.Status.DISCONNECTED)
        }
        if (instance === this) instance = null
        worker.shutdown()
        super.onDestroy()
    }

    private fun closeTun() {
        runCatching { tunFd?.close() }
        tunFd = null
    }

    private fun establishTun(options: TunOptions): Int {
        if (prepare(this) != null) throw IllegalStateException("нет разрешения на VPN")
        val builder = Builder()
            .setSession("Verge")
            .setMtu(options.mtu)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) builder.setMetered(false)

        val v4 = options.inet4Address
        while (v4.hasNext()) v4.next().let { builder.addAddress(it.address(), it.prefix()) }
        val v6 = options.inet6Address
        while (v6.hasNext()) v6.next().let { builder.addAddress(it.address(), it.prefix()) }

        if (options.autoRoute) {
            if (options.dnsMode.value != Libbox.DNSModeDisabled) {
                val dns = options.dnsServerAddress
                while (dns.hasNext()) builder.addDnsServer(dns.next())
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                addRoutes33(builder, options)
            } else {
                val r4 = options.inet4RouteRange
                while (r4.hasNext()) r4.next().let { builder.addRoute(it.address(), it.prefix()) }
                val r6 = options.inet6RouteRange
                while (r6.hasNext()) r6.next().let { builder.addRoute(it.address(), it.prefix()) }
            }
        }

        try {
            builder.addDisallowedApplication(packageName)
        } catch (_: PackageManager.NameNotFoundException) {
        }

        val pfd = builder.establish()
            ?: throw IllegalStateException("система не дала поднять VPN (нет разрешения?)")
        tunFd = pfd
        return pfd.fd
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun addRoutes33(builder: Builder, options: TunOptions) {
        val r4 = options.inet4RouteAddress
        if (r4.hasNext()) {
            while (r4.hasNext()) builder.addRoute(r4.next().toIpPrefix())
        } else if (options.inet4Address.hasNext()) {
            builder.addRoute("0.0.0.0", 0)
        }
        val r6 = options.inet6RouteAddress
        if (r6.hasNext()) {
            while (r6.hasNext()) builder.addRoute(r6.next().toIpPrefix())
        } else if (options.inet6Address.hasNext()) {
            builder.addRoute("::", 0)
        }
        val e4 = options.inet4RouteExcludeAddress
        while (e4.hasNext()) builder.excludeRoute(e4.next().toIpPrefix())
        val e6 = options.inet6RouteExcludeAddress
        while (e6.hasNext()) builder.excludeRoute(e6.next().toIpPrefix())
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun RoutePrefix.toIpPrefix() = IpPrefix(InetAddress.getByName(address()), prefix())

    private fun connectedText(): String {
        val connected = getString(R.string.vpn_connected)
        val details = VpnState.details
        return if (details.isNullOrBlank()) connected else "$connected · $details"
    }

    private fun goForeground(text: String) {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                getString(R.string.vpn_channel),
                NotificationManager.IMPORTANCE_LOW,
            ).apply { setShowBadge(false) },
        )
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val stop = PendingIntent.getService(
            this,
            1,
            Intent(this, VergeVpnService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_verge)
            .setContentTitle("Verge")
            .setContentText(text)
            .setOngoing(true)
            .setShowWhen(false)
            .setContentIntent(open)
            .addAction(
                Notification.Action.Builder(null as android.graphics.drawable.Icon?, getString(R.string.vpn_disconnect), stop).build(),
            )
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }
}
