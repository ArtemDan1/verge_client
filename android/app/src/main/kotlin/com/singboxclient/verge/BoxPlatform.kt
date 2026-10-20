package com.singboxclient.verge

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Process
import android.system.OsConstants
import io.nekohasekai.libbox.BridgeOptions
import io.nekohasekai.libbox.BridgeSession
import io.nekohasekai.libbox.ConnectionOwner
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.LocalDNSTransport
import io.nekohasekai.libbox.NeighborUpdateListener
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.Notification
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.PlatformUser
import io.nekohasekai.libbox.ShellSession
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.WIFIState
import java.net.Inet6Address
import java.net.InetSocketAddress
import java.net.InterfaceAddress
import java.net.NetworkInterface
import io.nekohasekai.libbox.NetworkInterface as BoxNetworkInterface

/**
 * Платформенная часть sing-box на Android: сеть, владельцы соединений и т.п.
 *
 * Сам TUN открывает только [VergeVpnService] (переопределяет [openTun]); этот
 * базовый класс используется и тестовым экземпляром автовыбора, которому TUN
 * не нужен.
 *
 * Возможности, которых у Verge нет (Tailscale, SSH, мосты, соседи по сети),
 * честно отвечают «не поддерживается»: конфиги, которые собирает приложение,
 * их не включают.
 */
open class BoxPlatform(context: Context) : PlatformInterface {
    protected val appContext: Context = context.applicationContext
    private val connectivity = appContext.getSystemService(ConnectivityManager::class.java)

    override fun localDNSTransport(): LocalDNSTransport? = null

    override fun usePlatformAutoDetectInterfaceControl(): Boolean = true

    /** Своё приложение исключено из VPN, так что сокеты и так идут мимо туннеля. */
    override fun autoDetectInterfaceControl(fd: Int) {}

    override fun openTun(options: TunOptions): Int =
        throw IllegalStateException("TUN доступен только VPN-сервису")

    override fun useProcFS(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q

    override fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String,
        sourcePort: Int,
        destinationAddress: String,
        destinationPort: Int,
    ): ConnectionOwner {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw IllegalStateException("android: используется procfs")
        }
        val uid = connectivity.getConnectionOwnerUid(
            ipProtocol,
            InetSocketAddress(sourceAddress, sourcePort),
            InetSocketAddress(destinationAddress, destinationPort),
        )
        if (uid == Process.INVALID_UID) throw IllegalStateException("android: владелец не найден")
        val packages = appContext.packageManager.getPackagesForUid(uid)?.toList().orEmpty()
        val owner = ConnectionOwner()
        owner.userId = uid
        // Имя пакета уходит в Clash API как processPath — его и показывает
        // экран «Соединения».
        owner.setAndroidPackageNames(StringList(packages))
        return owner
    }

    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        NetworkMonitor.addListener(listener)
    }

    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        NetworkMonitor.removeListener(listener)
    }

    override fun getInterfaces(): NetworkInterfaceIterator {
        val system = NetworkInterface.getNetworkInterfaces()?.toList().orEmpty()
        val result = mutableListOf<BoxNetworkInterface>()
        @Suppress("DEPRECATION")
        for (network in connectivity.allNetworks) {
            val props = connectivity.getLinkProperties(network) ?: continue
            val caps = connectivity.getNetworkCapabilities(network) ?: continue
            val iface = system.find { it.name == props.interfaceName } ?: continue
            val box = BoxNetworkInterface()
            box.name = props.interfaceName
            box.index = iface.index
            runCatching { box.mtu = iface.mtu }
            box.dnsServer = StringList(props.dnsServers.mapNotNull { it.hostAddress })
            box.gateway = StringList(
                props.routes
                    .filter { it.destination.prefixLength == 0 }
                    .mapNotNull { it.gateway }
                    .filterNot { it.isAnyLocalAddress }
                    .mapNotNull { it.hostAddress },
            )
            box.type = when {
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> Libbox.InterfaceTypeWIFI
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> Libbox.InterfaceTypeCellular
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> Libbox.InterfaceTypeEthernet
                else -> Libbox.InterfaceTypeOther
            }
            box.addresses = StringList(iface.interfaceAddresses.map { it.toPrefix() })
            var flags = 0
            if (caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
                flags = OsConstants.IFF_UP or OsConstants.IFF_RUNNING
            }
            if (iface.isLoopback) flags = flags or OsConstants.IFF_LOOPBACK
            if (iface.isPointToPoint) flags = flags or OsConstants.IFF_POINTOPOINT
            if (iface.supportsMulticast()) flags = flags or OsConstants.IFF_MULTICAST
            box.flags = flags
            box.metered = !caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
            result.add(box)
        }
        return InterfaceList(result)
    }

    override fun underNetworkExtension(): Boolean = false

    override fun includeAllNetworks(): Boolean = false

    override fun clearDNSCache() {}

    /** Правил по Wi-Fi в конфигах Verge нет, а SSID требует геолокации. */
    override fun readWIFIState(): WIFIState? = null

    override fun sendNotification(notification: Notification) {}

    override fun cancelNotification(identifier: String, typeID: Int) {}

    override fun startNeighborMonitor(listener: NeighborUpdateListener?) {}

    override fun closeNeighborMonitor(listener: NeighborUpdateListener?) {}

    override fun registerMyInterface(name: String?) {}

    override fun usePlatformShell(): Boolean = false

    override fun checkPlatformShell() {
        throw UnsupportedOperationException("shell не поддерживается")
    }

    override fun openShellSession(
        user: PlatformUser?,
        command: String?,
        environ: StringIterator?,
        term: String?,
        rows: Int,
        cols: Int,
    ): ShellSession = throw UnsupportedOperationException("shell не поддерживается")

    override fun lookupUser(username: String?): PlatformUser =
        throw UnsupportedOperationException("не поддерживается")

    override fun lookupSFTPServer(): String =
        throw UnsupportedOperationException("не поддерживается")

    override fun readSystemSSHHostKey(): String =
        throw UnsupportedOperationException("не поддерживается")

    override fun tailscaleHostname(): String = "${Build.MANUFACTURER} ${Build.MODEL}"

    override fun usePlatformBridge(): Boolean = false

    override fun createBridge(options: BridgeOptions?): BridgeSession =
        throw UnsupportedOperationException("не поддерживается")

    private fun InterfaceAddress.toPrefix(): String {
        val addr = address
        return if (addr is Inet6Address) {
            // Без scope id: sing-box ждёт голый адрес.
            "${Inet6Address.getByAddress(addr.address).hostAddress}/$networkPrefixLength"
        } else {
            "${addr.hostAddress}/$networkPrefixLength"
        }
    }
}

class StringList(values: List<String>) : StringIterator {
    private val size = values.size
    private val iterator = values.iterator()

    override fun len(): Int = size

    override fun hasNext(): Boolean = iterator.hasNext()

    override fun next(): String = iterator.next()
}

private class InterfaceList(values: List<BoxNetworkInterface>) : NetworkInterfaceIterator {
    private val iterator = values.iterator()

    override fun hasNext(): Boolean = iterator.hasNext()

    override fun next(): BoxNetworkInterface = iterator.next()
}
