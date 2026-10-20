package com.singboxclient.verge

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Единственная Activity. Регистрирует те же платформенные каналы, что и
 * десктопные раннеры (имена каналов и формат событий совпадают), — Dart-код
 * общий, отличается только реализация под ними.
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val REQ_VPN = 1001
        private const val REQ_NOTIFICATIONS = 1002
        private const val START_TIMEOUT_MS = 30_000L
        private const val STOP_TIMEOUT_MS = 10_000L
    }

    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newCachedThreadPool()

    private var tunSink: EventChannel.EventSink? = null
    private var xraySink: EventChannel.EventSink? = null
    private var singboxTestSink: EventChannel.EventSink? = null
    private var xrayTestSink: EventChannel.EventSink? = null
    private var deepLinkChannel: MethodChannel? = null

    /** Ссылка, с которой открыли приложение; отдаётся Dart один раз. */
    private var initialLink: String? = null

    /** Старт VPN, ожидающий ответа системного диалога разрешения. */
    private var pendingStart: Pair<String, MethodChannel.Result>? = null
    private var notificationsAsked = false

    private val vpnListener = object : VpnState.Listener {
        override fun onStatus(status: VpnState.Status, message: String?) {
            main.post { tunSink?.success(statusEvent(status, message)) }
        }

        override fun onLog(line: String) {
            main.post { tunSink?.success(mapOf("type" to "log", "line" to line)) }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Engines.init(this)
        initialLink = vergeLink(intent)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        registerTun(messenger)
        registerTunnel(messenger)
        registerXray(messenger)
        registerTests(messenger)
        MethodChannel(messenger, "singbox/helper").setMethodCallHandler { call, result ->
            // Отдельного helper'а на Android нет: TUN даёт VpnService.
            if (call.method == "status") result.success("enabled") else result.notImplemented()
        }
        deepLinkChannel = MethodChannel(messenger, "app/deeplink").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getInitialLink") {
                    result.success(initialLink)
                    initialLink = null
                } else {
                    result.notImplemented()
                }
            }
        }
        VpnState.addListener(vpnListener)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        VpnState.removeListener(vpnListener)
        Engines.xrayLog = null
        Engines.singboxTestLog = null
        Engines.xrayTestLog = null
        tunSink = null
        xraySink = null
        singboxTestSink = null
        xrayTestSink = null
        deepLinkChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val link = vergeLink(intent) ?: return
        deepLinkChannel?.invokeMethod("onLink", link)
    }

    private fun vergeLink(intent: Intent?): String? {
        val data = intent?.data ?: return null
        return if (data.scheme == "verge") data.toString() else null
    }

    // region VPN (TUN)

    private fun statusEvent(status: VpnState.Status, message: String?) = mapOf(
        "type" to "status",
        "value" to status.wire,
        "message" to message,
    )

    private fun registerTun(messenger: BinaryMessenger) {
        EventChannel(messenger, "singbox/tun/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    tunSink = events
                    // Новый движок Flutter при живом VPN: сразу сообщаем, что
                    // туннель уже поднят.
                    if (VpnState.status != VpnState.Status.DISCONNECTED) {
                        events.success(statusEvent(VpnState.status, VpnState.lastError))
                    }
                }

                override fun onCancel(arguments: Any?) {
                    tunSink = null
                }
            },
        )
        MethodChannel(messenger, "singbox/tun").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val config = call.argument<String>("config")
                    if (config == null) {
                        result.error("ARG", "нет конфига", null)
                        return@setMethodCallHandler
                    }
                    requestNotificationsOnce()
                    val prepare = VpnService.prepare(this)
                    if (prepare == null) {
                        startVpn(config, result)
                    } else {
                        pendingStart?.second?.error("PERMISSION", "запрос отменён", null)
                        pendingStart = config to result
                        @Suppress("DEPRECATION")
                        startActivityForResult(prepare, REQ_VPN)
                    }
                }
                "stop" -> stopVpn(result)
                "state" -> result.success(
                    mapOf(
                        "status" to VpnState.status.wire,
                        "config" to VpnState.runningConfig,
                    ),
                )
                else -> result.notImplemented()
            }
        }
    }

    // startActivityForResult — единственный путь у FlutterActivity без
    // зависимости на androidx.activity.
    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_VPN) return
        val (config, result) = pendingStart ?: return
        pendingStart = null
        if (resultCode == RESULT_OK) {
            startVpn(config, result)
        } else {
            result.error("PERMISSION", "Нет разрешения на VPN-подключение", null)
        }
    }

    private fun startVpn(config: String, result: MethodChannel.Result) {
        awaitStatus(START_TIMEOUT_MS, result) { status, message ->
            when (status) {
                VpnState.Status.CONNECTED -> result.success(null)
                VpnState.Status.ERROR -> result.error("START", message ?: "sing-box не запустился", null)
                VpnState.Status.DISCONNECTED -> result.error("START", "VPN остановлен", null)
                VpnState.Status.CONNECTING -> return@awaitStatus false
            }
            true
        }
        VergeVpnService.start(this, config)
    }

    private fun stopVpn(result: MethodChannel.Result) {
        if (VpnState.status == VpnState.Status.DISCONNECTED ||
            VpnState.status == VpnState.Status.ERROR
        ) {
            io.execute { Engines.xray.stop() }
            result.success(null)
            return
        }
        awaitStatus(STOP_TIMEOUT_MS, result) { status, _ ->
            if (status == VpnState.Status.DISCONNECTED || status == VpnState.Status.ERROR) {
                result.success(null)
                true
            } else {
                false
            }
        }
        VergeVpnService.stop(this)
    }

    /**
     * Ждёт смены статуса VPN. [onStatus] возвращает true, когда ответ отдан.
     * По таймауту отвечает ошибкой — Dart не должен висеть вечно.
     */
    private fun awaitStatus(
        timeoutMs: Long,
        result: MethodChannel.Result,
        onStatus: (VpnState.Status, String?) -> Boolean,
    ) {
        var done = false
        lateinit var listener: VpnState.Listener
        val timeout = Runnable {
            if (done) return@Runnable
            done = true
            VpnState.removeListener(listener)
            result.error("TIMEOUT", "VPN не ответил вовремя", null)
        }
        listener = object : VpnState.Listener {
            override fun onStatus(status: VpnState.Status, message: String?) {
                main.post {
                    if (done) return@post
                    if (onStatus(status, message)) {
                        done = true
                        VpnState.removeListener(this)
                        main.removeCallbacks(timeout)
                    }
                }
            }

            override fun onLog(line: String) {}
        }
        VpnState.addListener(listener)
        main.postDelayed(timeout, timeoutMs)
    }

    /** Без уведомления VPN всё равно работает, поэтому не ждём ответа. */
    private fun requestNotificationsOnce() {
        if (notificationsAsked || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        notificationsAsked = true
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQ_NOTIFICATIONS)
        }
    }

    // endregion

    // region singbox/tunnel: версии, обновление

    private fun registerTunnel(messenger: BinaryMessenger) {
        MethodChannel(messenger, "singbox/tunnel").setMethodCallHandler { call, result ->
            when (call.method) {
                "singboxVersion" -> result.success(BoxEngine.version())
                "xrayVersion" -> background(result) { XrayRunner.version(this) }
                // Сетевых служб, как на macOS, на Android нет.
                "listNetworkServices" -> result.success(emptyList<String>())
                "defaultService" -> result.success(null)
                "deviceAbi" -> result.success(apkAbi())
                "installUpdate" -> {
                    val path = call.arguments as? String
                    if (path == null) result.error("ARG", "нет пути", null) else installApk(path, result)
                }
                // Режима «системный прокси» на Android нет — только VPN.
                "start", "stop" -> result.error("UNSUPPORTED", "только VPN-режим", null)
                else -> result.notImplemented()
            }
        }
    }

    /**
     * ABI установленного APK (а не устройства): под него и ищется файл
     * обновления. На arm64-телефоне вполне может стоять armeabi-v7a-сборка.
     */
    private fun apkAbi(): String {
        val dir = File(applicationInfo.nativeLibraryDir).name
        return when (dir) {
            "arm64" -> "arm64-v8a"
            "arm" -> "armeabi-v7a"
            "x86_64" -> "x86_64"
            "x86" -> "x86"
            else -> Build.SUPPORTED_ABIS.firstOrNull() ?: "arm64-v8a"
        }
    }

    private fun installApk(path: String, result: MethodChannel.Result) {
        val file = File(path)
        if (!file.exists()) {
            result.error("OPEN", "файл не найден: $path", null)
            return
        }
        if (!packageManager.canRequestPackageInstalls()) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ),
            )
            result.error(
                "PERMISSION",
                "Разрешите Verge установку приложений и нажмите «Обновить» ещё раз",
                null,
            )
            return
        }
        val uri = FileProvider.getUriForFile(this, "$packageName.files", file)
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, "application/vnd.android.package-archive")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        result.success(null)
    }

    // endregion

    // region Xray и тестовые движки

    private fun registerXray(messenger: BinaryMessenger) {
        EventChannel(messenger, "singbox/xray/events").setStreamHandler(
            sinkHandler({ xraySink = it }) { sink ->
                Engines.xrayLog = { line ->
                    main.post { sink?.success(mapOf("type" to "log", "line" to line)) }
                }
            },
        )
        MethodChannel(messenger, "singbox/xray").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val config = call.argument<String>("config")
                    if (config == null) {
                        result.error("ARG", "нет конфига", null)
                    } else {
                        background(result) { Engines.xray.start(config); null }
                    }
                }
                "stop" -> background(result) { Engines.xray.stop(); null }
                else -> result.notImplemented()
            }
        }
    }

    private fun registerTests(messenger: BinaryMessenger) {
        EventChannel(messenger, "singbox/test/events").setStreamHandler(
            sinkHandler({ singboxTestSink = it }) { sink ->
                Engines.singboxTestLog = { line -> main.post { sink?.success(line) } }
            },
        )
        MethodChannel(messenger, "singbox/test").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val config = call.argument<String>("config")
                    if (config == null) {
                        result.error("ARG", "нет конфига", null)
                    } else {
                        background(result) { Engines.singboxTest.start(config); null }
                    }
                }
                "stop" -> background(result) { Engines.singboxTest.stop(); null }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "xray/test/events").setStreamHandler(
            sinkHandler({ xrayTestSink = it }) { sink ->
                Engines.xrayTestLog = { line -> main.post { sink?.success(line) } }
            },
        )
        MethodChannel(messenger, "xray/test").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val config = call.argument<String>("config")
                    if (config == null) {
                        result.error("ARG", "нет конфига", null)
                    } else {
                        background(result) { Engines.xrayTest.start(config); null }
                    }
                }
                "stop" -> background(result) { Engines.xrayTest.stop(); null }
                else -> result.notImplemented()
            }
        }
    }

    /** StreamHandler, который запоминает sink и подключает к нему лог движка. */
    private fun sinkHandler(
        store: (EventChannel.EventSink?) -> Unit,
        attach: (EventChannel.EventSink?) -> Unit,
    ) = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            store(events)
            attach(events)
        }

        override fun onCancel(arguments: Any?) {
            store(null)
            attach(null)
        }
    }

    /** Долгая работа — в фоне, ответ — на главном потоке. */
    private fun background(result: MethodChannel.Result, block: () -> Any?) {
        io.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("START", e.message ?: e.toString(), null) }
            }
        }
    }

    // endregion
}
