import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:weight_scale/protocol.dart';

void main() {
  group('ScaleProtocol', () {
    group('parseData validation', () {
      test('throws ArgumentError for empty data', () {
        expect(
          () => ScaleProtocol.parseData(Uint8List(0)),
          throwsA(isA<ArgumentError>()
              .having((e) => e.message, 'message', 'No data received')),
        );
      });

      test('throws ArgumentError for insufficient data', () {
        expect(
          () => ScaleProtocol.parseData(Uint8List(10)),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Insufficient data received: 10 bytes'),
          )),
        );
      });

      test('throws FormatException for invalid headers', () {
        final invalidData = Uint8List.fromList(List.filled(16, 0));
        expect(
          () => ScaleProtocol.parseData(invalidData),
          throwsA(isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Invalid frame headers'),
          )),
        );
      });

      test('throws FormatException for invalid sign byte', () {
        final invalidSignData = Uint8List.fromList([
          0x01, 0x02, 0x53, 0xFF, // Invalid sign byte
          0x30, 0x30, 0x2E, 0x30, 0x30, 0x30,
          0x6B, 0x67, 0x6A, 0x03, 0x04, 0x10
        ]);
        expect(
          () => ScaleProtocol.parseData(invalidSignData),
          throwsA(isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Invalid sign character'),
          )),
        );
      });

      test('throws FormatException for BCC mismatch', () {
        final invalidBccData = Uint8List.fromList([
          0x01, 0x02, 0x53, 0x20,
          0x30, 0x30, 0x2E, 0x30, 0x30, 0x30,
          0x6B, 0x67, 0xFF, // Invalid BCC
          0x03, 0x04, 0x10
        ]);
        expect(
          () => ScaleProtocol.parseData(invalidBccData),
          throwsA(isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('BCC validation failed'),
          )),
        );
      });
    });

    group('parseData success cases', () {
      test('parses positive weight correctly', () {
        final validData = Uint8List.fromList([
          0x01, 0x02, 0x53, 0x20, // SOH, STX, Status, Sign
          0x30, 0x30, 0x2E, 0x30, 0x30, 0x30, // Weight: "00.000"
          0x6B, 0x67, // Units: "kg"
          0x61, 0x03, 0x04, 0x10 // BCC (corrected), ETX, EOT, Status2
        ]);

        final scaleData = ScaleProtocol.parseData(validData);

        expect(scaleData.status, Status.stable);
        expect(scaleData.weight, '00.000');
        expect(scaleData.weightUnits, 'kg');
        expect(scaleData.status2, Status2.zero);
        expect(scaleData.isPositive, true);
        expect(scaleData.numericWeight, 0.0);
        expect(scaleData.isStable, true);
        expect(scaleData.isZero, true);
      });

      test('parses negative weight correctly', () {
        final validData = Uint8List.fromList([
          0x01, 0x02, 0x53, 0x2D, // SOH, STX, Status, Sign (negative)
          0x30, 0x31, 0x2E, 0x32, 0x33, 0x34, // Weight: "01.234"
          0x6B, 0x67, // Units: "kg"
          0x68, 0x03, 0x04, 0x10 // BCC (corrected), ETX, EOT, Status2
        ]);

        final scaleData = ScaleProtocol.parseData(validData);

        expect(scaleData.status, Status.stable);
        expect(scaleData.weight, '-01.234');
        expect(scaleData.weightUnits, 'kg');
        expect(scaleData.status2, Status2.zero);
        expect(scaleData.isPositive, false);
        expect(scaleData.numericWeight, -1.234);
      });

      test('parses unstable status correctly', () {
        final validData = Uint8List.fromList([
          0x01, 0x02, 0x55, 0x20, // SOH, STX, Unstable, Sign
          0x30, 0x35, 0x2E, 0x36, 0x37, 0x38, // Weight: "05.678"
          0x6C, 0x62, // Units: "lb"
          0x69, 0x03, 0x04, 0x20 // BCC (corrected), ETX, EOT, Tare
        ]);

        final scaleData = ScaleProtocol.parseData(validData);

        expect(scaleData.status, Status.unstable);
        expect(scaleData.weight, '05.678');
        expect(scaleData.weightUnits, 'lb');
        expect(scaleData.status2, Status2.tare);
        expect(scaleData.isStable, false);
        expect(scaleData.isTareActive, true);
        expect(scaleData.numericWeight, 5.678);
      });
    });

    group('BCC calculation', () {
      test('calculateBcc returns correct value', () {
        final data = Uint8List.fromList([
          0x01,
          0x02,
          0x53,
          0x20,
          0x30,
          0x30,
          0x2E,
          0x30,
          0x30,
          0x30,
          0x6B,
          0x67
        ]);
        final bcc = ScaleProtocol.calculateBcc(data);
        expect(bcc, 0x61); // Corrected expected value
      });

      test('calculateBcc handles different data patterns', () {
        final data1 = Uint8List.fromList([0x01, 0x02, 0x53, 0x2D]);
        final data2 = Uint8List.fromList([0x01, 0x02, 0x55, 0x20]);

        expect(ScaleProtocol.calculateBcc(data1),
            isNot(equals(ScaleProtocol.calculateBcc(data2))));
      });
    });

    group('ScaleData', () {
      test('equality works correctly', () {
        const data1 = ScaleData(
          status: Status.stable,
          weight: '01.234',
          weightUnits: 'kg',
          status2: Status2.zero,
          isPositive: true,
        );

        const data2 = ScaleData(
          status: Status.stable,
          weight: '01.234',
          weightUnits: 'kg',
          status2: Status2.zero,
          isPositive: true,
        );

        const data3 = ScaleData(
          status: Status.unstable,
          weight: '01.234',
          weightUnits: 'kg',
          status2: Status2.zero,
          isPositive: true,
        );

        expect(data1, equals(data2));
        expect(data1, isNot(equals(data3)));
        expect(data1.hashCode, equals(data2.hashCode));
      });

      test('copyWith works correctly', () {
        const original = ScaleData(
          status: Status.stable,
          weight: '01.234',
          weightUnits: 'kg',
          status2: Status2.zero,
          isPositive: true,
        );

        final modified =
            original.copyWith(status: Status.unstable, weight: '05.678');

        expect(modified.status, Status.unstable);
        expect(modified.weight, '05.678');
        expect(modified.weightUnits, 'kg'); // unchanged
        expect(modified.status2, Status2.zero); // unchanged
        expect(modified.isPositive, true); // unchanged
      });

      test('numericWeight parsing handles various formats', () {
        const data1 = ScaleData(
          status: Status.stable,
          weight: '01.234',
          weightUnits: 'kg',
          status2: Status2.zero,
          isPositive: true,
        );

        const data2 = ScaleData(
          status: Status.stable,
          weight: '-05.678',
          weightUnits: 'kg',
          status2: Status2.zero,
          isPositive: false,
        );

        const data3 = ScaleData(
          status: Status.stable,
          weight: '00.000',
          weightUnits: 'kg',
          status2: Status2.zero,
          isPositive: true,
        );

        expect(data1.numericWeight, 1.234);
        expect(data2.numericWeight, -5.678);
        expect(data3.numericWeight, 0.0);
      });
    });

    group('Status enums', () {
      test('Status.fromByte handles all cases', () {
        expect(Status.fromByte(0x46), Status.overload);
        expect(Status.fromByte(0x53), Status.stable);
        expect(Status.fromByte(0x55), Status.unstable);
        expect(Status.fromByte(0xFF), Status.unknown);
      });

      test('Status2.fromByte handles all cases', () {
        expect(Status2.fromByte(0x00), Status2.none);
        expect(Status2.fromByte(0x10), Status2.zero);
        expect(Status2.fromByte(0x20), Status2.tare);
        expect(Status2.fromByte(0x40), Status2.overload);
        expect(Status2.fromByte(0xFF), Status2.unknown);
      });
    });
  });
}
