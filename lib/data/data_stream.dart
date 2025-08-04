import 'package:weight_scale/protocol.dart';

/// Interface for handling weight scale data streams
abstract class WeightScaleDataStream {
  /// Stream of parsed scale data
  Stream<ScaleData>? get dataStream;

  /// Initialize data stream
  void initialize();

  /// Dispose resources
  Future<void> dispose();

  /// Set error callback
  void setErrorCallback(
      void Function(Object error, StackTrace stackTrace)? callback);
}
