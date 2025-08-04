package com.kicknext.weight_scale

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

/**
 * Flutter plugin for weight scale communication via USB-Serial
 */
class WeightScalePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val METHOD_CHANNEL = "com.kicknext.weight_scale"
        private const val EVENT_CHANNEL = "com.kicknext.weight_scale/events"
        
        // Method names
        private const val METHOD_GET_DEVICES = "getDevices"
        private const val METHOD_CONNECT = "connect"
        private const val METHOD_DISCONNECT = "disconnect"
        
        // Parameter names
        private const val PARAM_DEVICE_NAME = "deviceName"
        private const val PARAM_VENDOR_ID = "vendorID"
        private const val PARAM_PRODUCT_ID = "productID"
    }
    
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var weightScaleService: WeightScaleService? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

        weightScaleService = WeightScaleService(flutterPluginBinding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        weightScaleService?.cleanup()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        weightScaleService = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val service = weightScaleService
        if (service == null) {
            result.error("SERVICE_UNAVAILABLE", "WeightScaleService not initialized", null)
            return
        }

        when (call.method) {
            METHOD_GET_DEVICES -> {
                service.getDevices(result)
            }
            METHOD_CONNECT -> {
                handleConnect(call, result, service)
            }
            METHOD_DISCONNECT -> {
                service.disconnect(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleConnect(call: MethodCall, result: MethodChannel.Result, service: WeightScaleService) {
        val deviceName = call.argument<String>(PARAM_DEVICE_NAME)
        val vendorID = call.argument<String>(PARAM_VENDOR_ID)
        val productID = call.argument<String>(PARAM_PRODUCT_ID)
        
        when {
            deviceName.isNullOrBlank() -> {
                result.error("INVALID_ARGUMENT", "deviceName is required and cannot be empty", null)
            }
            vendorID.isNullOrBlank() -> {
                result.error("INVALID_ARGUMENT", "vendorID is required and cannot be empty", null)
            }
            productID.isNullOrBlank() -> {
                result.error("INVALID_ARGUMENT", "productID is required and cannot be empty", null)
            }
            else -> {
                service.connect(deviceName, vendorID, productID, result)
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        weightScaleService?.setEventSink(events)
    }

    override fun onCancel(arguments: Any?) {
        weightScaleService?.setEventSink(null)
    }
}
