@echo off
echo ========================================
echo   REPARACION Y EJECUCION DE FLUTTER
echo ========================================
echo.

:: Configurar variables de entorno PARA SIEMPRE
setx FLUTTER_STORAGE_BASE_URL "https://storage.googleapis.com/flutter_infra/"
setx PUB_HOSTED_URL "https://pub.dev"
setx JAVA_HOME "C:\Program Files\Android\Android Studio\jbr"

:: Establecer variables para la sesión actual
set FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com/flutter_infra/
set PUB_HOSTED_URL=https://pub.dev
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=%JAVA_HOME%\bin;%PATH%

echo [1/7] Variables de entorno configuradas
echo   FLUTTER_STORAGE_BASE_URL=%FLUTTER_STORAGE_BASE_URL%
echo   PUB_HOSTED_URL=%PUB_HOSTED_URL%
echo   JAVA_HOME=%JAVA_HOME%
echo.

:: Ir al proyecto
cd /d C:\Users\johnd\directorio_asambleas

echo [2/7] Desactivando mirror chino...
flutter config --no-enable-http-proxy 2>nul
flutter config --flutter-storage-base-url=https://storage.googleapis.com/flutter_infra/ 2>nul
echo.

echo [3/7] Limpiando proyecto...
flutter clean
echo.

echo [4/7] Eliminando cachés...
if exist android\.gradle rmdir /s /q android\.gradle
if exist android\app\build rmdir /s /q android\app\build
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
if exist C:\Users\johnd\.gradle\caches rmdir /s /q C:\Users\johnd\.gradle\caches
echo.

echo [5/7] Obteniendo dependencias...
flutter pub get
echo.

echo [6/7] Verificando dispositivos...
flutter devices
echo.

echo [7/7] Ejecutando aplicación...
flutter run -d emulator-5554

echo.
echo ========================================
pause