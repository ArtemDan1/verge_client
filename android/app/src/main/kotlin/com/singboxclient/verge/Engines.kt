package com.singboxclient.verge

import android.content.Context

/**
 * Движки, которые живут дольше Activity: Xray боевого подключения и тестовые
 * экземпляры автовыбора. Activity только подписывается на их логи.
 *
 * Логи приходят из фоновых потоков; переносом на главный поток занимается
 * подписчик ([MainActivity]).
 */
object Engines {
    @Volatile
    var xrayLog: ((String) -> Unit)? = null

    @Volatile
    var singboxTestLog: ((String) -> Unit)? = null

    @Volatile
    var xrayTestLog: ((String) -> Unit)? = null

    private lateinit var appContext: Context

    fun init(context: Context) {
        if (::appContext.isInitialized) return
        appContext = context.applicationContext
        BoxEngine.ensureSetup(appContext)
    }

    val xray: XrayRunner by lazy {
        XrayRunner(
            appContext,
            "xray",
            onLog = { xrayLog?.invoke(it) },
            onCrash = { xrayLog?.invoke("xray crashed: $it") },
        )
    }

    val xrayTest: XrayRunner by lazy {
        XrayRunner(
            appContext,
            "xray-test",
            onLog = { xrayTestLog?.invoke(it) },
            onCrash = { xrayTestLog?.invoke("xray-test crashed: $it") },
        )
    }

    val singboxTest: BoxEngine by lazy {
        BoxEngine(
            appContext,
            BoxPlatform(appContext),
            "sing-box-test.log",
            onLog = { singboxTestLog?.invoke(it) },
        )
    }
}
