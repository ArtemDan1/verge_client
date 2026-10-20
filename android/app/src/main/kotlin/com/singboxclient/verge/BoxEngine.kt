package com.singboxclient.verge

import android.content.Context
import io.nekohasekai.libbox.CommandServer
import io.nekohasekai.libbox.CommandServerHandler
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.OverrideOptions
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.SetupOptions
import io.nekohasekai.libbox.SystemProxyStatus
import org.json.JSONObject
import java.io.File

/**
 * Один экземпляр sing-box внутри процесса приложения (libbox).
 *
 * Таких экземпляров два: боевой (в VPN-сервисе) и тестовый — для замеров
 * автовыбора, аналог отдельного процесса `sing-box-test` на десктопе.
 *
 * @param logName имя файла лога в filesDir; строки из него уходят в [onLog].
 */
class BoxEngine(
    private val context: Context,
    private val platform: PlatformInterface,
    private val logName: String,
    private val onLog: (String) -> Unit,
    private val onStopRequest: () -> Unit = {},
) : CommandServerHandler {
    private var server: CommandServer? = null
    private var tail: LogTail? = null

    val isRunning: Boolean get() = server != null

    /** Поднимает sing-box с [config]. Бросает исключение с текстом ошибки ядра. */
    @Synchronized
    fun start(config: String) {
        stop()
        ensureSetup(context)
        val logFile = File(context.filesDir, logName)
        val patched = withLogOutput(config, logFile)
        val tail = LogTail(logFile, onLog).also { it.start() }
        this.tail = tail
        val server = CommandServer(this, platform)
        try {
            server.startOrReloadService(patched, OverrideOptions())
        } catch (e: Exception) {
            runCatching { server.closeService() }
            runCatching { server.close() }
            tail.stop()
            this.tail = null
            throw e
        }
        this.server = server
    }

    @Synchronized
    fun stop() {
        val s = server ?: return
        server = null
        runCatching { s.closeService() }
        runCatching { s.close() }
        tail?.stop()
        tail = null
    }

    // CommandServerHandler: команды, которые ядро шлёт приложению.

    override fun serviceStop() = onStopRequest()

    override fun serviceReload() {}

    override fun getSystemProxyStatus(): SystemProxyStatus = SystemProxyStatus()

    override fun setSystemProxyEnabled(isEnabled: Boolean) {}

    override fun triggerNativeCrash() {}

    override fun writeDebugMessage(message: String?) {}

    override fun connectSSHAgent(): Int =
        throw UnsupportedOperationException("ssh-agent не поддерживается")

    companion object {
        @Volatile
        private var setupDone = false

        /** Глобальная настройка libbox: рабочие папки. Один раз на процесс. */
        @Synchronized
        fun ensureSetup(context: Context) {
            if (setupDone) return
            val app = context.applicationContext
            NetworkMonitor.init(app)
            val options = SetupOptions()
            options.basePath = app.filesDir.path
            // Относительные пути конфига (cache-файл и т.п.) sing-box считает
            // от рабочей папки.
            options.workingPath = File(app.filesDir, "box").apply { mkdirs() }.path
            options.tempPath = app.cacheDir.path
            options.logMaxLines = 3000
            options.crashReportSource = "Verge"
            Libbox.setup(options)
            setupDone = true
        }

        fun version(): String = Libbox.version()

        /**
         * Направляет лог sing-box в файл: так его читает [LogTail]. Цвета
         * в файле ядро не пишет само.
         */
        private fun withLogOutput(config: String, file: File): String {
            val json = JSONObject(config)
            val log = json.optJSONObject("log") ?: JSONObject().also { json.put("log", it) }
            log.put("output", file.path)
            return json.toString()
        }
    }
}
