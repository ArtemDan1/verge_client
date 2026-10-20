package com.singboxclient.verge

import java.io.File
import java.io.RandomAccessFile

/**
 * Читает лог sing-box, который тот пишет в файл (`log.output`), и отдаёт
 * строки по мере появления. Встроенный канал логов libbox работает через
 * gRPC-клиент — ради одного потока строк он здесь избыточен.
 */
class LogTail(private val file: File, private val onLine: (String) -> Unit) {
    @Volatile
    private var running = false
    private var thread: Thread? = null

    /** Экземпляр одноразовый: на каждый запуск движка — новый LogTail. */
    fun start() {
        // Лог прошлого запуска не нужен: экран «Логи» показывает текущую сессию.
        runCatching { file.writeText("") }
        running = true
        thread = Thread({ loop() }, "verge-log-tail").apply {
            isDaemon = true
            start()
        }
    }

    fun stop() {
        running = false
        thread?.interrupt()
        thread = null
    }

    private var position = 0L
    private val pending = StringBuilder()

    private fun loop() {
        position = 0L
        pending.setLength(0)
        while (running) {
            readOnce()
            try {
                Thread.sleep(250)
            } catch (_: InterruptedException) {
                break
            }
        }
        // Дочитываем хвост: последние строки часто и объясняют остановку.
        readOnce()
        if (pending.isNotBlank()) onLine(pending.toString().trimEnd())
    }

    private fun readOnce() {
        try {
            RandomAccessFile(file, "r").use { raf ->
                val length = raf.length()
                // Файл обрезали (новый старт) — читаем с начала.
                if (length < position) position = 0
                while (length > position) {
                    raf.seek(position)
                    val chunk = (length - position).coerceAtMost(256 * 1024L).toInt()
                    val bytes = ByteArray(chunk)
                    val read = raf.read(bytes)
                    if (read <= 0) break
                    position += read
                    pending.append(String(bytes, 0, read, Charsets.UTF_8))
                    emitLines(pending)
                }
            }
        } catch (_: java.io.FileNotFoundException) {
            // sing-box ещё не создал файл.
        } catch (_: Exception) {
        }
    }

    private fun emitLines(buffer: StringBuilder) {
        while (true) {
            val nl = buffer.indexOf("\n")
            if (nl < 0) return
            val line = buffer.substring(0, nl).trimEnd('\r')
            buffer.delete(0, nl + 1)
            if (line.isNotBlank()) onLine(line)
        }
    }
}
