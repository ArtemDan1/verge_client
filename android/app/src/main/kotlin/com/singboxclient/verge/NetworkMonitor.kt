package com.singboxclient.verge

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import io.nekohasekai.libbox.InterfaceUpdateListener
import java.net.NetworkInterface
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Следит за «настоящей» сетью устройства (Wi-Fi, мобильная) и сообщает
 * sing-box, через какой интерфейс выходить наружу.
 *
 * Слушателей может быть два одновременно: боевой туннель и тестовый экземпляр
 * автовыбора, — поэтому список, а не одно поле.
 */
object NetworkMonitor {
    private const val TAG = "VergeNetwork"

    private lateinit var connectivity: ConnectivityManager
    private val listeners = CopyOnWriteArrayList<InterfaceUpdateListener>()
    private var registered = false

    @Volatile
    private var current: Network? = null

    private val handler by lazy {
        Handler(HandlerThread("verge-network").apply { start() }.looper)
    }

    private val request: NetworkRequest =
        NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED)
            .build()

    private val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            current = network
            notifyAll(network)
        }

        override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
            if (network == current) notifyAll(network)
        }

        override fun onLinkPropertiesChanged(network: Network, props: LinkProperties) {
            if (network == current) notifyAll(network)
        }

        override fun onLost(network: Network) {
            if (network == current) {
                current = null
                notifyAll(null)
            }
        }
    }

    fun init(context: Context) {
        if (::connectivity.isInitialized) return
        connectivity = context.applicationContext
            .getSystemService(ConnectivityManager::class.java)
    }

    @Synchronized
    fun addListener(listener: InterfaceUpdateListener) {
        listeners.add(listener)
        if (!registered) register()
        // Сеть уже известна — сообщаем сразу, не дожидаясь следующего события.
        handler.post { notifyOne(listener, current ?: connectivity.activeNetwork) }
    }

    @Synchronized
    fun removeListener(listener: InterfaceUpdateListener) {
        listeners.remove(listener)
        if (listeners.isEmpty() && registered) {
            runCatching { connectivity.unregisterNetworkCallback(callback) }
            registered = false
            current = null
        }
    }

    /**
     * registerDefaultNetworkCallback с Android 9 отдаёт сам VPN, поэтому где
     * можно — запрос лучшей подходящей сети (как в официальном клиенте
     * sing-box).
     */
    private fun register() {
        try {
            when {
                Build.VERSION.SDK_INT >= 31 ->
                    connectivity.registerBestMatchingNetworkCallback(request, callback, handler)
                Build.VERSION.SDK_INT >= 28 ->
                    connectivity.requestNetwork(request, callback, handler)
                else ->
                    connectivity.registerDefaultNetworkCallback(callback, handler)
            }
            registered = true
        } catch (e: RuntimeException) {
            Log.e(TAG, "register network callback", e)
        }
    }

    private fun notifyAll(network: Network?) {
        for (l in listeners) notifyOne(l, network)
    }

    private fun notifyOne(listener: InterfaceUpdateListener, network: Network?) {
        if (network == null) {
            listener.updateDefaultInterface("", -1, false, false)
            return
        }
        // Свойства сети и сам интерфейс появляются не мгновенно — несколько
        // коротких попыток, как в официальном клиенте.
        repeat(10) {
            val props = connectivity.getLinkProperties(network)
            val name = props?.interfaceName
            if (name != null) {
                val index = runCatching { NetworkInterface.getByName(name)?.index }.getOrNull()
                if (index != null) {
                    val caps = connectivity.getNetworkCapabilities(network)
                    val metered = caps?.hasCapability(
                        NetworkCapabilities.NET_CAPABILITY_NOT_METERED,
                    ) == false
                    listener.updateDefaultInterface(name, index, metered, false)
                    return
                }
            }
            Thread.sleep(100)
        }
    }
}
