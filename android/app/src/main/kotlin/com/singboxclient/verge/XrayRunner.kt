package com.singboxclient.verge

import android.content.Context
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Дочерний процесс Xray-core — второй движок (hysteria2, vless+xhttp), как на
 * десктопе. Бинарник лежит в APK под видом `libxray.so`: из nativeLibraryDir
 * Android разрешает запуск исполняемых файлов, а из папки данных — нет.
 *
 * VPN-сервис исключает своё приложение из туннеля, поэтому соединения Xray
 * идут мимо TUN без отдельной защиты сокетов.
 *
 * @param name имя для конфига и сообщений («xray» или «xray-test»).
 */
class XrayRunner(
    private val context: Context,
    private val name: String,
    private val onLog: (String) -> Unit,
    private val onCrash: (String) -> Unit = {},
) {
    @Volatile
    private var process: Process? = null

    @Volatile
    private var stopping = false
    private val tailLock = Any()
    private val tail = ArrayDeque<String>()

    @Synchronized
    fun start(config: String) {
        stop()
        val bin = binary(context)
            ?: throw IllegalStateException("Xray недоступен для этой архитектуры устройства")
        val cfg = File(context.cacheDir, "$name-config.json")
        cfg.writeText(config)
        synchronized(tailLock) { tail.clear() }
        stopping = false

        val p = ProcessBuilder(bin.path, "run", "-config", cfg.path)
            .directory(context.filesDir)
            .redirectErrorStream(true)
            .apply { environment()["XRAY_LOCATION_ASSET"] = context.filesDir.path }
            .start()
        process = p

        Thread({
            p.inputStream.bufferedReader().useLines { lines ->
                for (line in lines) {
                    synchronized(tailLock) {
                        tail.addLast(line)
                        while (tail.size > 40) tail.removeFirst()
                    }
                    onLog(line)
                }
            }
            val code = runCatching { p.waitFor() }.getOrDefault(-1)
            if (!stopping && process === p) {
                process = null
                onCrash("$name завершился (код $code)")
            }
        }, "verge-$name").apply {
            isDaemon = true
            start()
        }

        // Как на десктопе: даём процессу время упасть на кривом конфиге, прежде
        // чем считать старт успешным.
        if (p.waitFor(800, TimeUnit.MILLISECONDS)) {
            process = null
            val output = synchronized(tailLock) { tail.joinToString("\n") }
            throw IllegalStateException(
                "$name завершился сразу (код ${p.exitValue()})" +
                    if (output.isNotBlank()) ":\n$output" else "",
            )
        }
    }

    @Synchronized
    fun stop() {
        val p = process ?: return
        stopping = true
        process = null
        p.destroy()
        if (!p.waitFor(2, TimeUnit.SECONDS)) p.destroyForcibly()
    }

    companion object {
        fun binary(context: Context): File? {
            val file = File(context.applicationInfo.nativeLibraryDir, "libxray.so")
            return if (file.exists()) file else null
        }

        /** "Xray 26.3.27 (Xray, Penetrates Everything.) ..." → "26.3.27". */
        fun version(context: Context): String {
            val bin = binary(context) ?: return "недоступен"
            return try {
                val p = ProcessBuilder(bin.path, "version").redirectErrorStream(true).start()
                val first = p.inputStream.bufferedReader().readLine().orEmpty()
                p.waitFor(3, TimeUnit.SECONDS)
                first.split(' ').getOrNull(1) ?: "unknown"
            } catch (_: Exception) {
                "unknown"
            }
        }
    }
}
