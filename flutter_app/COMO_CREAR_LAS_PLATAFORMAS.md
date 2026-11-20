El SDK Flutter no está instalado en el entorno de creación de esta entrega.

Para crear los archivos de Android y Web que Flutter genera por proyecto, ejecuta desde este directorio:

```powershell
flutter create --platforms=android,web .
flutter pub get
```

Conserva `pubspec.yaml` y el directorio `lib/` de esta entrega.

Para pruebas locales en Android: habilita INTERNET y temporalmente `usesCleartextTraffic` en `android/app/src/main/AndroidManifest.xml`.

Lee el README raíz para los comandos completos.
