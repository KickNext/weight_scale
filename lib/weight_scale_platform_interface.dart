import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'weight_scale_method_channel.dart';

abstract class WeightScalePlatform extends PlatformInterface {
  /// Constructs a WeightScalePlatform.
  WeightScalePlatform() : super(token: _token);

  static final Object _token = Object();

  static WeightScalePlatform _instance = MethodChannelWeightScale();

  /// The default instance of [WeightScalePlatform] to use.
  ///
  /// Defaults to [MethodChannelWeightScale].
  static WeightScalePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WeightScalePlatform] when
  /// they register themselves.
  static set instance(WeightScalePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
