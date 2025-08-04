// ignore_for_file: dangling_library_doc_comments

/// Weight Scale Plugin - Flutter plugin for interfacing with commercial weight scales
/// via RS232 using the AUTO COMMUNICATE PROTOCOL.
///
/// This library provides:
/// - Real-time weight data streaming
/// - Type-safe error handling with `Result<T>` pattern
/// - Device auto-discovery and validation
/// - Protocol validation with BCC checking
/// - Memory-efficient data processing
///
/// Example usage:
/// ```dart
/// import 'package:weight_scale/weight_scale.dart';
///
/// final manager = WeightScaleManager();
/// final result = await manager.getAvailableDevices();
///
/// result.fold(
///   (devices) => print('Found ${devices.length} devices'),
///   (failure) => print('Error: ${failure.message}'),
/// );
/// ```
library;

// Core exports
export 'package:weight_scale/weight_scale_manager.dart';
export 'package:weight_scale/weight_scale_device.dart';
export 'package:weight_scale/protocol.dart';

// Configuration and utilities
export 'package:weight_scale/core/config.dart';
export 'package:weight_scale/core/logger.dart';
export 'package:weight_scale/core/result.dart';

// Data abstractions
export 'package:weight_scale/data/data_stream.dart';
export 'package:weight_scale/repositories/device_repository.dart';
