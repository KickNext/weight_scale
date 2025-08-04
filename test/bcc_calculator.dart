// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:weight_scale/protocol.dart';

void main() {
  // Test data 1: Positive weight
  final data1 = Uint8List.fromList(
      [0x01, 0x02, 0x53, 0x20, 0x30, 0x30, 0x2E, 0x30, 0x30, 0x30, 0x6B, 0x67]);
  final bcc1 = ScaleProtocol.calculateBcc(data1);
  print('BCC for positive weight test: 0x${bcc1.toRadixString(16)}');

  // Test data 2: Negative weight
  final data2 = Uint8List.fromList(
      [0x01, 0x02, 0x53, 0x2D, 0x30, 0x31, 0x2E, 0x32, 0x33, 0x34, 0x6B, 0x67]);
  final bcc2 = ScaleProtocol.calculateBcc(data2);
  print('BCC for negative weight test: 0x${bcc2.toRadixString(16)}');

  // Test data 3: Unstable status
  final data3 = Uint8List.fromList(
      [0x01, 0x02, 0x55, 0x20, 0x30, 0x35, 0x2E, 0x36, 0x37, 0x38, 0x6C, 0x62]);
  final bcc3 = ScaleProtocol.calculateBcc(data3);
  print('BCC for unstable status test: 0x${bcc3.toRadixString(16)}');
}
