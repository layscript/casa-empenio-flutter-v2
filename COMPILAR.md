# Cómo compilar la app (APK Android)

Guía probada el 2026-10-08 (build OK en macOS Apple Silicon).

## Versiones exactas

| Herramienta | Versión | Dónde se define |
|---|---|---|
| Flutter | **3.19.5** (Dart 3.3.3) | `.fvmrc` |
| Java (JDK) | **17** (Temurin) | — el JDK 21+ es demasiado nuevo para Gradle 8.2 |
| Gradle | 8.2 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin | 8.0.2 | `android/build.gradle` |
| Kotlin | 1.7.10 | `android/build.gradle` |
| Android SDK | compileSdk 34 | `android/app/build.gradle` |

Usar SIEMPRE Flutter vía **FVM**. Con un Flutter más nuevo (3.29+, 3.41) la compilación falla.

## Requisitos (una sola vez)

```bash
brew install fvm                      # gestor de versiones de Flutter
brew install --cask temurin@17        # JDK 17
# Android SDK con la plataforma android-34 (Android Studio > SDK Manager)
```

## Compilar

```bash
cd casa-empenio-flutter-v2

# 1. Usar JDK 17 en esta terminal
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH="$JAVA_HOME/bin:$PATH"

# 2. Instalar/usar la versión de Flutter del proyecto
fvm install 3.19.5 --setup
fvm use 3.19.5 --force
fvm flutter --version        # debe decir: Flutter 3.19.5

# 3. Dependencias y build
fvm flutter pub get
fvm flutter build apk --release
```

Resultado: `build/app/outputs/flutter-apk/app-release.apk` (~36 MB). El build tarda ~3 min.

## Backend al que apunta la app

La URL está fija en el código: `lib/presentation/app/config/constants.dart`

```dart
const endPointPrincipal = 'http://86.48.22.211:3000';   // producción (Coolify)
```

Para comprobar qué URL quedó dentro de un APK ya compilado:

```bash
unzip -p build/app/outputs/flutter-apk/app-release.apk lib/arm64-v8a/libapp.so | strings | grep -E "^https?://"
```

## Problemas conocidos

- **"fvm dice 3.19.5 pero compila con otra versión":** alguien corrió `flutter upgrade` dentro de
  la carpeta de FVM y la "3.19.5" quedó con otra versión. Revisar con `fvm list` (columna de versión
  real) y, si no coincide, reinstalar: `fvm remove 3.19.5 && fvm install 3.19.5 --setup`.
- **Errores de Gradle/Java al compilar:** casi siempre es el JDK. Verificar `java -version` = 17.
- **Firma:** el release se firma con la clave *debug* de la máquina que compila
  (`signingConfigs.debug`). Un APK compilado en otra máquina no se instala encima del anterior:
  hay que **desinstalar la app vieja** antes de instalar el nuevo.
- Los avisos `source value 8 is obsolete` y `packages have newer versions` son normales.
