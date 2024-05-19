import android.content.Context
import android.hardware.usb.UsbManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.hoho.android.usbserial.driver.UsbSerialDriver
import com.hoho.android.usbserial.driver.UsbSerialPort
import com.hoho.android.usbserial.driver.UsbSerialProber
import com.hoho.android.usbserial.util.SerialInputOutputManager
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.concurrent.Executors
import java.util.HashMap

class WeightScaleService(private val context: Context) : SerialInputOutputManager.Listener {
    private val TAG = "WeightScaleService"
    private val usbManager: UsbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private var port: UsbSerialPort? = null
    private var usbIoManager: SerialInputOutputManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private val buffer = mutableListOf<Byte>()  // Буфер для накопления данных

    fun getDevices(result: MethodChannel.Result) {
        val availableDrivers = UsbSerialProber.getDefaultProber().findAllDrivers(usbManager)
        val devices = HashMap<String, String>()
        for (driver in availableDrivers) {
            val device = driver.device
            val deviceName = device.deviceName
            val vendorId = device.vendorId.toString()
            val productId = device.productId.toString()
            devices[deviceName] = "$vendorId:$productId"
        }
        result.success(devices)
    }

    fun connect(deviceId: String, result: MethodChannel.Result) {
        val availableDrivers = UsbSerialProber.getDefaultProber().findAllDrivers(usbManager)
        var driver: UsbSerialDriver? = null

        for (availableDriver in availableDrivers) {
            val device = availableDriver.device
            if (device.deviceName == deviceId) {
                driver = availableDriver
                break
            }
        }

        if (driver == null) {
            result.error("NO_WEIGHT_SCALE_DEVICE", "No matching serial device found", null)
            return
        }

        val connection = usbManager.openDevice(driver.device)
        if (connection == null) {
            Log.d(TAG, "Permission not granted for USB device.")
            return
        }

        port = driver.ports[0]
        try {
            port?.open(connection)
            port?.setParameters(9600, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)

            usbIoManager = SerialInputOutputManager(port, this)
            Executors.newSingleThreadExecutor().submit(usbIoManager)

            result.success("Connected to weight scale")
        } catch (e: IOException) {
            e.printStackTrace()
            result.error("CONNECTION_FAILED", "Failed to connect", e.message)
        }
    }

    fun disconnect(result: MethodChannel.Result) {
        try {
            usbIoManager?.stop()
            closePort()
            result.success("Disconnected and stopped reading")
        } catch (e: IOException) {
            result.error("DISCONNECTION_FAILED", "Failed to disconnect", e.message)
        }
    }

    fun closePort() {
        port?.close()
        port = null
    }

    fun setEventSink(eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
    }

    override fun onNewData(data: ByteArray) {
        Log.d(TAG, "Received data (length: ${data.size}):")

        // Логируем каждый байт
        data.forEach { byte ->
            Log.d(TAG, "Byte received: ${byte.toInt() and 0xFF} (${byte.toChar()})")
        }

        // Накопление данных
        buffer.addAll(data.toList())

        // Проверка накопленных данных на наличие полного пакета
        processBuffer()
    }

    override fun onRunError(e: Exception) {
        if (e.message?.contains("Connection closed") == true) {
            Log.i(TAG, "Connection closed normally")
        } else {
            Log.e(TAG, "Runner stopped due to an error", e)
        }
    }

    private fun processBuffer() {
        while (buffer.size >= 16) {  // Проверка на наличие достаточного количества данных для пакета
            val startIdx = buffer.indexOf(0x01.toByte())
            if (startIdx == -1) {
                buffer.clear()  // Очищаем буфер, если начало пакета не найдено
                break
            }

            val endIdx = startIdx + 15  // Позиция последнего символа в 16-байтовом пакете
            if (endIdx >= buffer.size) {
                break  // Выход из цикла, если конец пакета не найден
            }

            val dataPacket = buffer.subList(startIdx, endIdx + 1).toByteArray()
            Log.d(TAG, "Data packet candidate: ${dataPacket.joinToString()} (length: ${dataPacket.size})")

            if (dataPacket.size == 16 && dataPacket[0] == 0x01.toByte() && dataPacket[1] == 0x02.toByte()) {
                buffer.subList(0, endIdx + 1).clear()

                mainHandler.post {
                    processData(dataPacket)
                    eventSink?.success(dataPacket)
                }
            } else {
                Log.e(TAG, "Invalid data packet received: ${dataPacket.joinToString()} (length: ${dataPacket.size})")
                buffer.removeAt(0)
            }
        }
    }

    private fun processData(data: ByteArray) {
        Log.d(TAG, "Processed Data: ${data.joinToString()}")
    }
}


