
import 'weight_scale_platform_interface.dart';

class WeightScale {
  Future<String?> getPlatformVersion() {
    return WeightScalePlatform.instance.getPlatformVersion();
  }
}
