# Проверка настройки Codecov
# PowerShell скрипт для финальной проверки всех компонентов

$ErrorActionPreference = "Stop"
$allChecksPass = $true

Write-Host "🔍 Проверка настройки Codecov для Weight Scale Plugin" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

# 1. Проверка .codecov.yml
Write-Host "1. Проверка файла .codecov.yml..." -ForegroundColor Yellow
if (Test-Path ".codecov.yml") {
    Write-Host "   ✅ .codecov.yml найден" -ForegroundColor Green
    $lines = (Get-Content ".codecov.yml" | Measure-Object -Line).Lines
    Write-Host "   📄 Содержит $lines строк конфигурации" -ForegroundColor Blue
} else {
    Write-Host "   ❌ .codecov.yml не найден!" -ForegroundColor Red
    $allChecksPass = $false
}

# 2. Проверка CI workflow
Write-Host "2. Проверка CI workflow..." -ForegroundColor Yellow
if (Test-Path ".github/workflows/ci.yml") {
    Write-Host "   ✅ ci.yml найден" -ForegroundColor Green
    $content = Get-Content ".github/workflows/ci.yml" -Raw
    if ($content -match "codecov/codecov-action@v5") {
        Write-Host "   ✅ Codecov action настроен" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Codecov action не найден в workflow" -ForegroundColor Red
        $allChecksPass = $false
    }
} else {
    Write-Host "   ❌ ci.yml не найден!" -ForegroundColor Red
    $allChecksPass = $false
}

# 3. Проверка coverage файла
Write-Host "3. Проверка coverage файла..." -ForegroundColor Yellow
if (Test-Path "coverage/lcov.info") {
    Write-Host "   ✅ coverage/lcov.info найден" -ForegroundColor Green
    $size = (Get-Item "coverage/lcov.info").Length
    Write-Host "   📊 Размер: $size байт" -ForegroundColor Blue
} else {
    Write-Host "   ⚠️  coverage/lcov.info не найден (будет создан при тестах)" -ForegroundColor Yellow
}

# 4. Проверка README badge
Write-Host "4. Проверка README badge..." -ForegroundColor Yellow
if (Test-Path "README.md") {
    $readme = Get-Content "README.md" -Raw
    if ($readme -match "codecov\.io") {
        Write-Host "   ✅ Codecov badge найден в README.md" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Codecov badge не найден в README.md" -ForegroundColor Red
        $allChecksPass = $false
    }
} else {
    Write-Host "   ❌ README.md не найден!" -ForegroundColor Red
    $allChecksPass = $false
}

# 5. Проверка документации
Write-Host "5. Проверка документации..." -ForegroundColor Yellow
if (Test-Path "docs/CODECOV_SETUP.md") {
    Write-Host "   ✅ Документация по настройке создана" -ForegroundColor Green
} else {
    Write-Host "   ❌ docs/CODECOV_SETUP.md не найден!" -ForegroundColor Red
    $allChecksPass = $false
}

# Итоговый результат
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Gray
if ($allChecksPass) {
    Write-Host "✅ Все проверки пройдены успешно!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Следующие шаги:" -ForegroundColor Cyan
    Write-Host "   1. Настройте репозиторий на codecov.io" -ForegroundColor White
    Write-Host "   2. Добавьте CODECOV_TOKEN в GitHub Secrets" -ForegroundColor White
    Write-Host "   3. Запустите CI pipeline" -ForegroundColor White
    Write-Host "   4. Проверьте badge в README" -ForegroundColor White
} else {
    Write-Host "❌ Некоторые проверки не пройдены" -ForegroundColor Red
    Write-Host "   Исправьте ошибки и запустите скрипт снова" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "📚 Подробная инструкция: docs/CODECOV_SETUP.md" -ForegroundColor Blue
