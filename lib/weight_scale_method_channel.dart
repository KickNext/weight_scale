import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'weight_scale_platform_interface.dart';

/// An implementation of [WeightScalePlatform] that uses method channels.
class MethodChannelWeightScale extends WeightScalePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('weight_scale');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
