package com.kicknext.weight_scale

import WeightScaleService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class WeightScalePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var weightScaleSerialService: WeightScaleService? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.kicknext.weight_scale")
    methodChannel.setMethodCallHandler(this)

    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.kicknext.weight_scale/events")
    eventChannel.setStreamHandler(this)

    weightScaleSerialService = WeightScaleService(flutterPluginBinding.applicationContext)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    weightScaleSerialService?.closePort()
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getDevices" -> weightScaleSerialService?.getDevices(result)
      "connect" -> {
        val deviceId = call.argument<String>("deviceId")
        if (deviceId != null) {
          weightScaleSerialService?.connect(deviceId, result)
        } else {
          result.error("INVALID_ARGUMENT", "Device ID is required", null)
        }
      }
      "disconnect" -> weightScaleSerialService?.disconnect(result)
      else -> result.notImplemented()
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    weightScaleSerialService?.setEventSink(events)
  }

  override fun onCancel(arguments: Any?) {
    weightScaleSerialService?.setEventSink(null)
  }
}
