package com.singboxclient.verge

import java.util.concurrent.CopyOnWriteArrayList

/**
 * Состояние VPN-туннеля, общее для сервиса и Flutter-каналов.
 *
 * Сервис и Activity живут в одном процессе, но независимо: пользователь может
 * смахнуть приложение из недавних, движок Flutter умрёт, а VPN продолжит
 * работать. Поэтому состояние держит не Activity, а этот объект — новый движок
 * при старте читает его и подхватывает уже поднятый туннель.
 */
object VpnState {
    enum class Status(val wire: String) {
        DISCONNECTED("disconnected"),
        CONNECTING("connecting"),
        CONNECTED("connected"),
        ERROR("error"),
    }

    interface Listener {
        fun onStatus(status: Status, message: String?)
        fun onLog(line: String)
    }

    @Volatile
    var status: Status = Status.DISCONNECTED
        private set

    @Volatile
    var lastError: String? = null
        private set

    /** Конфиг работающего туннеля: по нему Dart заново находит Clash API. */
    @Volatile
    var runningConfig: String? = null

    /** Конфиг, который сервис должен поднять при следующем старте. */
    @Volatile
    var pendingConfig: String? = null

    private val listeners = CopyOnWriteArrayList<Listener>()

    fun addListener(listener: Listener) {
        listeners.add(listener)
    }

    fun removeListener(listener: Listener) {
        listeners.remove(listener)
    }

    fun update(status: Status, message: String? = null) {
        this.status = status
        if (status == Status.ERROR) lastError = message
        if (status != Status.CONNECTED) runningConfig = null
        for (l in listeners) l.onStatus(status, message)
    }

    fun log(line: String) {
        for (l in listeners) l.onLog(line)
    }
}
