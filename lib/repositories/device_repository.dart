import 'package:weight_scale/core/result.dart';
import 'package:weight_scale/weight_scale_device.dart';

/// Repository interface for managing weight scale devices
abstract class WeightScaleDeviceRepository {
  /// Get all available USB devices
  Future<Result<List<WeightScaleDevice>>> getAvailableDevices();

  /// Connect to a specific device
  Future<Result<void>> connect(WeightScaleDevice device);

  /// Disconnect from current device
  Future<Result<void>> disconnect();

  /// Check if device is valid by attempting connection and data reception
  Future<Result<bool>> validateDevice(WeightScaleDevice device);

  /// Get current connection status
  bool get isConnected;

  /// Get currently connected device
  WeightScaleDevice? get connectedDevice;
}
