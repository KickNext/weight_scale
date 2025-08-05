# Настройка Codecov для Weight Scale Plugin

## Проблема

При выполнении CI pipeline получаем ошибку:

```
error - Upload failed: {"message":"Repository not found"}
```

## Решение

### 1. Настройка репозитория в Codecov

1. Перейдите на [codecov.io](https://codecov.io)
2. Войдите через GitHub
3. Добавьте репозиторий `nikitiser/weight_scale`:
   - Нажмите "Add a repository"
   - Найдите `weight_scale` в списке
   - Нажмите "Setup repo"

### 2. Получение токена Codecov

1. В настройках репозитория в Codecov найдите раздел "Settings"
2. Скопируйте "Repository Upload Token"
3. Добавьте токен в GitHub Secrets:
   - Перейдите в Settings → Secrets and variables → Actions
   - Нажмите "New repository secret"
   - Name: `CODECOV_TOKEN`
   - Value: скопированный токен

### 3. Альтернативный способ (для публичных репозиториев)

Если репозиторий публичный, Codecov может работать без токена. В этом случае:

1. Удалите секцию `env:` из CI workflow
2. Оставьте только параметр `token:` в `codecov-action`

```yaml
- name: 📊 Upload coverage to Codecov
  uses: codecov/codecov-action@v5
  with:
    files: ./coverage/lcov.info
    fail_ci_if_error: false
    verbose: true
```

### 4. Проверка локально

Запустите скрипт проверки coverage:

**Windows (PowerShell):**

```powershell
.\scripts\check_coverage.ps1
```

**Linux/macOS:**

```bash
chmod +x scripts/check_coverage.sh
./scripts/check_coverage.sh
```

### 5. Конфигурация Codecov

Файл `.codecov.yml` уже создан и настроен:

- Игнорирует android/ios/example папки
- Устанавливает разумные пороги покрытия (60-90%)
- Настраивает комментарии в PR

### 6. Проверка статуса

После настройки:

1. Запустите CI pipeline заново
2. Проверьте, что coverage загружается успешно
3. Badge в README должен показывать актуальное покрытие

### Текущий статус файлов

✅ `.codecov.yml` - конфигурация создана
✅ `ci.yml` - workflow обновлен с лучшей обработкой ошибок  
✅ Скрипты проверки coverage созданы
✅ Coverage генерируется корректно (2938 байт в lcov.info)

### Следующие шаги

1. Настройте репозиторий в Codecov
2. Добавьте `CODECOV_TOKEN` в GitHub Secrets
3. Запустите CI pipeline повторно
4. Проверьте badge в README
