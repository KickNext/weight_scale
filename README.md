# Weight Scale Plugin

Это новый плагин Flutter для использования весов с интерфейсом RS232.

## Начало работы

Для начала работы с плагином выполните следующие шаги:

1. Вставьте следующий код в раздел `allprojects/repositories` вашего файла `build.gradle` на уровне проекта:

```groovy
maven { 
    url 'https://www.jitpack.io' 
}
```
```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { 
            url 'https://www.jitpack.io' 
        }
    }
}
```