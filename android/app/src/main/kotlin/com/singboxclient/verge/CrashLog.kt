package com.singboxclient.verge

import android.content.Context
import java.io.File

/**
 * Записывает необработанное исключение Kotlin/Java в файл, чтобы после
 * перезапуска показать его на экране «Логи» — без компьютера и logcat.
 * Затем передаёт исключение стандартному обработчику (приложение падает как
 * обычно).
 */
object CrashLog {
    @Volatile
    private var installed = false

    fun file(context: Context) = File(context.filesDir, "crash-java.log")

    fun install(context: Context) {
        if (installed) return
        installed = true
        val target = file(context.applicationContext)
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            runCatching {
                target.writeText("поток ${thread.name}: ${error.stackTraceToString()}")
            }
            previous?.uncaughtException(thread, error)
        }
    }
}
