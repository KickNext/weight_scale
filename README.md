# Weight Scale Plugin

Это новый плагин Flutter для использования весов с интерфейсом RS232.

## Начало работы

Для начала работы с плагином выполните следующие шаги:

1. Добавьте следующий код в файл `build.gradle` на уровне проекта:

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