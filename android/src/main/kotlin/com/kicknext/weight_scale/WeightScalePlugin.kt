package com.kicknext.weight_scale

import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.hardware.usb.UsbDeviceConnection
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import com.android.usbserial.driver.UsbSerialDriver
import com.hoho.android.usbserial.driver.UsbSerialPort
import com.hoho.android.usbserial.driver.UsbSerialProber

import java.io.IOException
import java.util.HashMap

class WeightScalePlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var port: UsbSerialPort? = null
  private lateinit var usbManager: UsbManager

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.kicknext.weight_scale/serial")
    channel.setMethodCallHandler(this)
    usbManager = flutterPluginBinding.applicationContext.getSystemService(Context.USB_SERVICE) as UsbManager
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    when (call.method) {
      "getDevices" -> getDevices(result)
      "connect" -> {
        val deviceId = call.argument<String>("deviceId")
        if (deviceId != null) {
          connect(deviceId, result)
        } else {
          result.error("INVALID_ARGUMENT", "Device ID is required", null)
        }
      }
      "disconnect" -> disconnect(result)
      "write" -> {
        val data = call.argument<String>("data")
        if (data != null) {
          write(data, result)
        } else {
          result.error("INVALID_ARGUMENT", "Data is required", null)
        }
      }
      "read" -> read(result)
      else -> result.notImplemented()
    }
  }

  private fun getDevices(result: MethodChannel.Result) {
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

  private fun connect(deviceId: String, result: MethodChannel.Result) {
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
      result.error("NO_DEVICE", "No matching serial device found", null)
      return
    }

    val connection = usbManager.openDevice(driver.device)
    if (connection == null) {
      result.error("NO_CONNECTION", "Could not open connection", null)
      return
    }

    port = driver.ports[0]
    try {
      port?.open(connection)
      port?.setParameters(9600, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)
      result.success("Connected")
    } catch (e: IOException) {
      result.error("CONNECTION_FAILED", "Failed to connect", e.message)
    }
  }

  private fun disconnect(result: MethodChannel.Result) {
    try {
      port?.close()
      port = null
      result.success("Disconnected")
    } catch (e: IOException) {
      result.error("DISCONNECTION_FAILED", "Failed to disconnect", e.message)
    }
  }

  private fun write(data: String, result: MethodChannel.Result) {
    try {
      port?.write(data.toByteArray(), 1000)
      result.success("Data sent")
    } catch (e: IOException) {
      result.error("WRITE_FAILED", "Failed to write", e.message)
    }
  }

  private fun read(result: MethodChannel.Result) {
    try {
      val buffer = ByteArray(16)
      val numBytesRead = port?.read(buffer, 1000) ?: 0
      result.success(String(buffer, 0, numBytesRead))
    } catch (e: IOException) {
      result.error("READ_FAILED", "Failed to read", e.message)
    }
  }
}

