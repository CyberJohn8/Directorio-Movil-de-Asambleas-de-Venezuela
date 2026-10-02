@echo off
setlocal
set "FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com"
set "PUB_HOSTED_URL=https://pub.dev"
set "PUGETS_RECEIVE_TIMEOUT=600"

echo ========================================
echo Limpiando proyecto Flutter...
echo ========================================
for %%p in (dart.exe java.exe gradle.exe adb.exe) do (
    taskkill /F /IM %%p >nul 2>&1
)

flutter clean

echo.
echo ========================================
echo Eliminando carpetas build...
echo ========================================
if exist build rmdir /s /q build
if exist android\app\build rmdir /s /q android\app\build
if exist android\.gradle rmdir /s /q android\.gradle
if exist .dart_tool rmdir /s /q .dart_tool

echo.
echo ========================================
echo Obteniendo dependencias...
echo ========================================
flutter pub get

echo.
echo ========================================
echo Generando iconos...
echo ========================================
flutter pub run flutter_launcher_icons:main

echo.
echo ========================================
echo Ejecutando la aplicación...
echo ========================================
flutter run

endlocal
pause