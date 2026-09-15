# Flutter's own embedding + generated plugin registrant. Each plugin AAR
# (shared_preferences, url_launcher, file_picker, share_plus,
# path_provider, image_picker) already ships its own consumer-rules.txt
# that AGP merges in automatically, so this file only needs to cover the
# generic framework glue rather than duplicate every plugin's rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep annotation info so reflection-based plugin lookups (e.g. PluginRegistry)
# don't get stripped.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Standard Kotlin metadata used by some plugins for coroutine/reflection support.
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Google Play Core / deferred-components support. Flutter's engine
# embedding references these classes (SplitCompat,
# PlayStoreDeferredComponentManager) even in a build that never actually
# uses split APKs / dynamic feature delivery — Play Core itself isn't a
# declared dependency by default, so R8 flags them as missing and, with
# newer AGP/R8, can hard-fail the release minify step rather than just
# warn. Silencing the warning and keeping the classes (as no-ops, since
# they're unused here) is the standard fix rather than pulling in the
# actual Play Core library for a feature this app doesn't use.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
