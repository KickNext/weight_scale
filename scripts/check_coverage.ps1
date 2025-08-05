# PowerShell скрипт для локальной проверки coverage
$ErrorActionPreference = "Stop"

Write-Host "🧪 Запуск тестов с генерацией coverage..." -ForegroundColor Green
flutter test --coverage --reporter expanded

Write-Host ""
Write-Host "📊 Проверка файла coverage..." -ForegroundColor Yellow
if (Test-Path "coverage/lcov.info") {
    Write-Host "✅ Файл coverage/lcov.info найден" -ForegroundColor Green
    $lineCount = (Get-Content "coverage/lcov.info" | Measure-Object -Line).Lines
    Write-Host "📈 Размер файла: $lineCount строк" -ForegroundColor Blue
    Write-Host ""
    Write-Host "🔍 Первые 10 строк coverage:" -ForegroundColor Yellow
    Get-Content "coverage/lcov.info" | Select-Object -First 10
    Write-Host ""
    Write-Host "📊 Статистика coverage:" -ForegroundColor Yellow
    Get-Content "coverage/lcov.info" | Select-String -Pattern "^(SF|LF|LH):" | Select-Object -First 20
} else {
    Write-Host "❌ Файл coverage/lcov.info не найден!" -ForegroundColor Red
    Write-Host "📁 Содержимое директории coverage:" -ForegroundColor Yellow
    if (Test-Path "coverage") {
        Get-ChildItem "coverage" -Force
    } else {
        Write-Host "Директория coverage не существует" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""
Write-Host "✅ Coverage готов для отправки в Codecov" -ForegroundColor Green
