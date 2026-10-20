# Правила R8 для release-сборки (Flutter включает минификацию по умолчанию).

# libbox (sing-box через gomobile): нативный код находит эти классы и методы
# по имени через JNI. Переименованные или вырезанные — падение при старте
# ядра.
-keep class go.** { *; }
-keep class io.nekohasekai.libbox.** { *; }

# Наши реализации интерфейсов libbox (PlatformInterface, CommandServerHandler
# и т.п.): Go вызывает их методы по имени.
-keep class com.singboxclient.verge.** { *; }

# Сканер QR (ML Kit / Google Code Scanner) создаёт свои компоненты через
# рефлексию; без этого — «getClass() on a null object reference».
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_code_scanner.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
-dontwarn com.google.mlkit.**
