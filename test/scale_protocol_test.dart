import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:weight_scale/protocol.dart';

void main() {
  group('ScaleProtocol', () {
    test('parseData throws error for empty data', () {
      expect(() => ScaleProtocol.parseData(Uint8List(0)), throwsArgumentError);
    });

    test('parseData throws error for insufficient data', () {
      expect(() => ScaleProtocol.parseData(Uint8List(10)), throwsArgumentError);
    });

    test('parseData throws error for invalid headers', () {
      var invalidData = Uint8List.fromList(List.filled(16, 0));
      expect(() => ScaleProtocol.parseData(invalidData), throwsFormatException);
    });

    test('parseData returns correct ScaleData for positive weight', () {
      var validData = Uint8List.fromList(
          [0x01, 0x02, 0x53, 0x20, 0x30, 0x30, 0x2E, 0x30, 0x30, 0x30, 0x6B, 0x67, 0x6A, 0x03, 0x04, 0x10]);
      var scaleData = ScaleProtocol.parseData(validData);
      expect(scaleData.status, Status.stable);
      expect(scaleData.weight, '00.000');
      expect(scaleData.weightUnits, 'kg');
      expect(scaleData.status2, Status2.zero);
      expect(scaleData.isPositive, true);
    });

    test('parseData returns correct ScaleData for negative weight', () {
      var validData = Uint8List.fromList(
          [0x01, 0x02, 0x53, 0x2D, 0x30, 0x30, 0x2E, 0x30, 0x30, 0x30, 0x6B, 0x67, 0x6A, 0x03, 0x04, 0x10]);
      var scaleData = ScaleProtocol.parseData(validData);
      expect(scaleData.status, Status.stable);
      expect(scaleData.weight, '-00.000');
      expect(scaleData.weightUnits, 'kg');
      expect(scaleData.status2, Status2.zero);
      expect(scaleData.isPositive, false);
    });

    test('calculateBcc returns correct value', () {
      var data = Uint8List.fromList([0x01, 0x02, 0x53, 0x2B, 0x30, 0x30, 0x2E, 0x30, 0x30, 0x30, 0x6B, 0x67]);
      var bcc = ScaleProtocol.calculateBcc(data);
      expect(bcc, 0x6A); // Expected BCC value
    });
  });
}
