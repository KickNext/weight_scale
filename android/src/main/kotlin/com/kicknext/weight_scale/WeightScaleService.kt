package com.kicknext.weight_scale

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.hoho.android.usbserial.driver.UsbSerialDriver
import com.hoho.android.usbserial.driver.UsbSerialPort
import com.hoho.android.usbserial.driver.UsbSerialProber
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.HashMap

class UsbSerialService(private val context: Context) {
    private val TAG = "UsbSerialService"
    private val ACTION_USB_PERMISSION = "com.kicknext.USB_PERMISSION"
    private val usbManager: UsbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private var device: UsbDevice? = null
    private var port: UsbSerialPort? = null
    private var readThread: ReadThread? = null
    private val mainHandler = Handler(Looper.getMainLooper())

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
            result.error("NO_weight_scale_DEVICE", "No matching serial device found", null)
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

            // Запуск потока для чтения данных
            readThread = ReadThread(port!!)
            readThread!!.start()

        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    fun disconnect(result: MethodChannel.Result) {
        closePort()
    }

    fun closePort(){
        port?.close()
        readThread?.interrupt()
    }

    private inner class ReadThread(private val port: UsbSerialPort) : Thread() {
        override fun run() {
            val buffer = ByteArray(16)

            while (!isInterrupted) {
                try {
                    val numBytesRead = port.read(buffer, 1000)
                    if (numBytesRead > 0) {
                        val receivedData = String(buffer, 0, numBytesRead)
                        Log.d(TAG, "Read $numBytesRead bytes: $receivedData")

                        // Отправка данных в основной поток для обработки
                        mainHandler.post { processData(receivedData) }
                    }
                } catch (e: IOException) {
                    e.printStackTrace()
                }
            }
        }
    }

    private fun processData(data: String) {
        // Обработка полученных данных
        Log.d(TAG, "Processed Data: $data")
    }
}
