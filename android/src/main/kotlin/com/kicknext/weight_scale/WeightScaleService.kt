package com.kicknext.weight_scale

import android.content.Context
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresApi
import com.hoho.android.usbserial.driver.UsbSerialDriver
import com.hoho.android.usbserial.driver.UsbSerialPort
import com.hoho.android.usbserial.driver.UsbSerialProber
import com.hoho.android.usbserial.util.SerialInputOutputManager
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.concurrent.Executors
import java.util.HashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Service for managing USB-Serial communication with weight scales
 */
class WeightScaleService(private val context: Context) : SerialInputOutputManager.Listener {
    companion object {
        private const val TAG = "WeightScaleService"
        private const val BUFFER_CAPACITY = 1024
        private const val FRAME_SIZE = 16
        private const val SOH_BYTE = 0x01.toByte()
        private const val STX_BYTE = 0x02.toByte()
        
        // Serial connection parameters
        private const val BAUD_RATE = 9600
        private const val DATA_BITS = 8
        private const val STOP_BITS = UsbSerialPort.STOPBITS_1
        private const val PARITY = UsbSerialPort.PARITY_NONE
    }

    private val usbManager: UsbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    
    // Connection state
    private var port: UsbSerialPort? = null
    private var usbIoManager: SerialInputOutputManager? = null
    private val isConnected = AtomicBoolean(false)
    
    // Data handling
    private var eventSink: EventChannel.EventSink? = null
    private val dataBuffer = CircularBuffer(BUFFER_CAPACITY)

    @RequiresApi(Build.VERSION_CODES.HONEYCOMB_MR1)
    fun getDevices(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Getting available USB devices")
            val availableDrivers = UsbSerialProber.getDefaultProber().findAllDrivers(usbManager)
            val devices = HashMap<String, String>()
            
            for (driver in availableDrivers) {
                val device = driver.device
                val deviceName = device.deviceName
                val vendorId = device.vendorId.toString()
                val productId = device.productId.toString()
                devices[deviceName] = "$vendorId:$productId"
                Log.d(TAG, "Found USB device: $deviceName (VID: $vendorId, PID: $productId)")
            }
            
            Log.d(TAG, "Returning ${devices.size} USB devices")
            result.success(devices)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting devices", e)
            result.error("GET_DEVICES_FAILED", "Failed to get USB devices", e.message)
        }
    }

    fun connect(deviceName: String, vendorID: String, productID: String, result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Attempting to connect to device: $deviceName (VID: $vendorID, PID: $productID)")
            
            // Check if already connected
            if (isConnected.get()) {
                Log.w(TAG, "Already connected to a device")
                result.error("ALREADY_CONNECTED", "Already connected to a device", null)
                return
            }

            val driver = findMatchingDriver(deviceName, vendorID, productID)
            if (driver == null) {
                Log.e(TAG, "No matching driver found for device: $deviceName")
                result.error("NO_WEIGHT_SCALE_DEVICE", "No matching serial device found", null)
                return
            }

            val connection = usbManager.openDevice(driver.device)
            if (connection == null) {
                Log.e(TAG, "Permission not granted for USB device: $deviceName")
                result.error("PERMISSION_DENIED", "Permission not granted for USB device", null)
                return
            }

            port = driver.ports.firstOrNull()
            if (port == null) {
                Log.e(TAG, "No serial ports found on device: $deviceName")
                result.error("NO_SERIAL_PORT", "No serial ports found on device", null)
                return
            }

            establishConnection(connection, result, deviceName)
            
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error during connection", e)
            cleanup()
            result.error("CONNECTION_FAILED", "Unexpected error during connection", e.message)
        }
    }

    private fun findMatchingDriver(deviceName: String, vendorID: String, productID: String): UsbSerialDriver? {
        val availableDrivers = UsbSerialProber.getDefaultProber().findAllDrivers(usbManager)
        return availableDrivers.find { driver ->
            val device = driver.device
            device.deviceName == deviceName &&
            device.vendorId.toString() == vendorID &&
            device.productId.toString() == productID
        }
    }

    private fun establishConnection(connection: android.hardware.usb.UsbDeviceConnection, result: MethodChannel.Result, deviceName: String) {
        try {
            port?.open(connection)
            port?.setParameters(BAUD_RATE, DATA_BITS, STOP_BITS, PARITY)

            // Clear any existing buffer data
            dataBuffer.clear()

            usbIoManager = SerialInputOutputManager(port, this)
            executor.submit(usbIoManager)

            isConnected.set(true)
            Log.i(TAG, "Successfully connected to weight scale: $deviceName")
            result.success("Connected to weight scale: $deviceName")
            
        } catch (e: IOException) {
            Log.e(TAG, "Failed to establish connection", e)
            cleanup()
            result.error("CONNECTION_FAILED", "Failed to establish connection", e.message)
        }
    }

    fun disconnect(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Disconnecting from weight scale")
            cleanup()
            result.success("Disconnected from weight scale")
        } catch (e: Exception) {
            Log.e(TAG, "Error during disconnect", e)
            result.error("DISCONNECTION_FAILED", "Failed to disconnect cleanly", e.message)
        }
    }

    fun cleanup() {
        try {
            isConnected.set(false)
            usbIoManager?.stop()
            usbIoManager = null
            
            port?.close()
            port = null
            
            dataBuffer.clear()
            Log.d(TAG, "Cleanup completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup", e)
        }
    }

    fun setEventSink(eventSink: EventChannel.EventSink?) {
        Log.d(TAG, if (eventSink != null) "Event sink connected" else "Event sink disconnected")
        this.eventSink = eventSink
    }

    override fun onNewData(data: ByteArray) {
        if (!isConnected.get()) {
            Log.w(TAG, "Received data while not connected, ignoring")
            return
        }

        Log.v(TAG, "Received ${data.size} bytes of raw data")
        dataBuffer.write(data)
        processDataBuffer()
    }

    override fun onRunError(e: Exception) {
        Log.e(TAG, "USB communication error", e)
        
        if (e.message?.contains("Connection closed") == true) {
            Log.i(TAG, "USB connection closed")
            mainHandler.post {
                eventSink?.error("CONNECTION_LOST", "USB connection was closed", e.message)
            }
        } else {
            Log.e(TAG, "Unexpected USB error: ${e.message}")
            mainHandler.post {
                eventSink?.error("USB_ERROR", "USB communication error", e.message)
            }
        }
        
        cleanup()
    }

    private fun processDataBuffer() {
        while (true) {
            val frameData = extractCompleteFrame() ?: break
            
            Log.v(TAG, "Processing complete 16-byte frame")
            mainHandler.post {
                eventSink?.success(frameData)
            }
        }
    }

    private fun extractCompleteFrame(): ByteArray? {
        // Look for SOH byte (start of frame)
        val startIndex = dataBuffer.indexOf(SOH_BYTE)
        if (startIndex == -1) {
            // No SOH found, clear buffer to prevent accumulation of garbage data
            if (dataBuffer.size() > 0) {
                Log.v(TAG, "No SOH found, clearing ${dataBuffer.size()} bytes from buffer")
                dataBuffer.clear()
            }
            return null
        }

        // Remove any data before SOH
        if (startIndex > 0) {
            Log.v(TAG, "Removing $startIndex bytes of garbage data before SOH")
            dataBuffer.consume(startIndex)
        }

        // Check if we have enough data for a complete frame
        if (dataBuffer.size() < FRAME_SIZE) {
            Log.v(TAG, "Insufficient data for complete frame: ${dataBuffer.size()}/$FRAME_SIZE bytes")
            return null
        }

        // Extract the frame
        val frameData = dataBuffer.peek(FRAME_SIZE)
        
        // Validate frame structure (SOH + STX at start)
        if (frameData[0] == SOH_BYTE && frameData[1] == STX_BYTE) {
            // Valid frame, consume it from buffer
            dataBuffer.consume(FRAME_SIZE)
            Log.v(TAG, "Extracted valid frame of $FRAME_SIZE bytes")
            return frameData
        } else {
            // Invalid frame, remove SOH and try again
            Log.v(TAG, "Invalid frame structure, removing SOH and retrying")
            dataBuffer.consume(1)
            return extractCompleteFrame()
        }
    }

    /**
     * Circular buffer implementation for efficient data handling
     */
    private class CircularBuffer(private val capacity: Int) {
        private val buffer = ByteArray(capacity)
        private var head = 0
        private var tail = 0
        private var count = 0

        fun write(data: ByteArray) {
            for (byte in data) {
                if (count < capacity) {
                    buffer[tail] = byte
                    tail = (tail + 1) % capacity
                    count++
                } else {
                    // Buffer is full, overwrite oldest data
                    buffer[tail] = byte
                    tail = (tail + 1) % capacity
                    head = (head + 1) % capacity
                }
            }
        }

        fun peek(length: Int): ByteArray {
            val result = ByteArray(minOf(length, count))
            var current = head
            for (i in result.indices) {
                result[i] = buffer[current]
                current = (current + 1) % capacity
            }
            return result
        }

        fun consume(length: Int) {
            val toConsume = minOf(length, count)
            head = (head + toConsume) % capacity
            count -= toConsume
        }

        fun indexOf(byte: Byte): Int {
            var current = head
            for (i in 0 until count) {
                if (buffer[current] == byte) {
                    return i
                }
                current = (current + 1) % capacity
            }
            return -1
        }

        fun size(): Int = count

        fun clear() {
            head = 0
            tail = 0
            count = 0
        }
    }
}
