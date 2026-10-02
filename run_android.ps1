Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EJECUTANDO PROYECTO CON CONFIGURACIÓN CORREGIDA" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "1. Limpiando proyecto..." -ForegroundColor Green
flutter clean

Write-Host ""
Write-Host "2. Eliminando cachés de Gradle..." -ForegroundColor Green
Remove-Item -Recurse -Force "android\.gradle" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "android\app\build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "3. Verificando emulador..." -ForegroundColor Green
$devices = flutter devices
if ($devices -match "emulator-5558") {
    Write-Host "   Emulador encontrado: emulator-5558" -ForegroundColor Green
} else {
    Write-Host "   Iniciando emulador..." -ForegroundColor Yellow
    flutter emulators --launch Pixel_7_API_34
    Write-Host "   Esperando 30 segundos..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

Write-Host ""
Write-Host "4. Obteniendo dependencias..." -ForegroundColor Green
flutter pub get

Write-Host ""
Write-Host "5. Ejecutando en Android..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
flutter run -d emulator-5558 --android-skip-build-dependency-validation