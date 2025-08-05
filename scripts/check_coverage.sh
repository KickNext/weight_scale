#!/bin/bash

# Скрипт для локальной проверки coverage
set -e

echo "🧪 Запуск тестов с генерацией coverage..."
flutter test --coverage --reporter expanded

echo ""
echo "📊 Проверка файла coverage..."
if [ -f "coverage/lcov.info" ]; then
    echo "✅ Файл coverage/lcov.info найден"
    echo "📈 Размер файла: $(wc -l < coverage/lcov.info) строк"
    echo ""
    echo "🔍 Первые 10 строк coverage:"
    head -10 coverage/lcov.info
    echo ""
    echo "📊 Статистика coverage:"
    grep -E "^(SF|LF|LH):" coverage/lcov.info | head -20
else
    echo "❌ Файл coverage/lcov.info не найден!"
    echo "📁 Содержимое директории coverage:"
    ls -la coverage/ 2>/dev/null || echo "Директория coverage не существует"
    exit 1
fi

echo ""
echo "✅ Coverage готов для отправки в Codecov"
