package com.kicknext.weight_scale

import android.content.Context
import android.hardware.usb.UsbManager
import android.os.Handler
import android.os.Looper
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
    private val usbManager: UsbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private var port: UsbSerialPort? = null
    private var usbIoManager: SerialInputOutputManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private val buffer = mutableListOf<Byte>()

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
        Logger.d("getDevices: $devices")
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
            Logger.d("Permission not granted for USB device.")
            result.error("PERMISSION_DENIED", "Permission not granted for USB device", null)
            return
        }

        port = driver.ports[0]
        try {
            port?.open(connection)
            port?.setParameters(9600, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)

            usbIoManager = SerialInputOutputManager(port, this)
            Executors.newSingleThreadExecutor().submit(usbIoManager)

            Logger.d("Connected to weight scale")
            result.success("Connected to weight scale")
        } catch (e: IOException) {
            Logger.e("Failed to connect to the weight scale", e)
            result.error("CONNECTION_FAILED", "Failed to connect", e.message)
        }
    }

    fun disconnect(result: MethodChannel.Result) {
        try {
            usbIoManager?.stop()
            closePort()
            Logger.d("Disconnected and stopped reading")
            result.success("Disconnected and stopped reading")
        } catch (e: IOException) {
            Logger.e("Failed to disconnect from the weight scale", e)
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
        Logger.d("Received data (length: ${data.size}): ${data.joinToString { byte -> "%02X".format(byte) }}")

        buffer.addAll(data.toList())

        processBuffer()
    }

    override fun onRunError(e: Exception) {
        if (e.message?.contains("Connection closed") == true) {
            Logger.i("Connection closed normally")
        } else {
            Logger.e("Runner stopped due to an error", e)
        }
    }

    private fun processBuffer() {
        while (buffer.size >= 16) {
            val startIdx = buffer.indexOf(0x01.toByte())
            if (startIdx == -1) {
                buffer.clear()
                break
            }

            val endIdx = startIdx + 15
            if (endIdx >= buffer.size) {
                break
            }

            val dataPacket = buffer.subList(startIdx, endIdx + 1).toByteArray()
            Logger.d("Data packet candidate: ${dataPacket.joinToString { byte -> "%02X".format(byte) }} (length: ${dataPacket.size})")

            if (dataPacket.size == 16 && dataPacket[0] == 0x01.toByte() && dataPacket[1] == 0x02.toByte()) {
                buffer.subList(0, endIdx + 1).clear()

                mainHandler.post {
                    processData(dataPacket)
                    eventSink?.success(dataPacket)
                }
            } else {
                Logger.e("Invalid data packet received: ${dataPacket.joinToString { byte -> "%02X".format(byte) }} (length: ${dataPacket.size})")
                buffer.removeAt(0)
            }
        }
    }

    private fun processData(data: ByteArray) {
        Logger.d("Processed Data: ${data.joinToString { byte -> "%02X".format(byte) }}")
    }
}
