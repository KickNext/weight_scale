// import 'package:flutter_test/flutter_test.dart';
// import 'package:weight_scale/weight_scale.dart';
// import 'package:weight_scale/weight_scale_platform_interface.dart';
// import 'package:weight_scale/weight_scale_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockWeightScalePlatform
//     with MockPlatformInterfaceMixin
//     implements WeightScalePlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final WeightScalePlatform initialPlatform = WeightScalePlatform.instance;

//   test('$MethodChannelWeightScale is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelWeightScale>());
//   });

//   test('getPlatformVersion', () async {
//     WeightScale weightScalePlugin = WeightScale();
//     MockWeightScalePlatform fakePlatform = MockWeightScalePlatform();
//     WeightScalePlatform.instance = fakePlatform;

//     expect(await weightScalePlugin.getPlatformVersion(), '42');
//   });
// }
