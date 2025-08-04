# Weight Scale Flutter Plugin - AI Agent Instructions

## Project Overview

This is a Flutter plugin for Android that interfaces with commercial weight scales via RS232 using the AUTO COMMUNICATE PROTOCOL. The plugin provides real-time weight data streaming from USB-connected scales.

## Core Architecture (Refactored)

### Key Components

- **`WeightScaleManager`**: Singleton implementing both `WeightScaleDeviceRepository` and `WeightScaleDataStream` interfaces
- **`WeightScaleConfig`**: Configuration class with serial parameters, device IDs, and timeouts
- **`Result<T>`**: Type-safe result wrapper for success/failure handling instead of exceptions
- **`WeightScaleLogger`**: Logging abstraction with `ConsoleLogger` and `SilentLogger` implementations
- **`ScaleProtocol`**: Enhanced protocol parser with better error messages and validation
- **`ScaleData`**: Immutable data model with convenience methods and equality support

### Clean Architecture Pattern

```
├── core/                    # Shared utilities and types
│   ├── result.dart         # Result<T> for type-safe error handling
│   ├── config.dart         # Configuration and device identifiers
│   └── logger.dart         # Logging abstraction
├── repositories/           # Data access interfaces
│   └── device_repository.dart
├── data/                   # Data handling interfaces
│   └── data_stream.dart
└── examples/               # Usage examples and patterns
    └── usage_examples.dart
```

### Data Flow Pattern

1. **Discovery**: `getAvailableDevices()` → `Result<List<WeightScaleDevice>>`
2. **Filtering**: Known VID/PID validation → `validateDevice()` with timeout
3. **Connection**: Type-safe `connect()` → `Result<void>`
4. **Streaming**: EventChannel → `ScaleProtocol.parseData()` → `ScaleData` with rich metadata

## Critical Development Patterns

### Result-Based Error Handling

```dart
final result = await manager.getAvailableDevices();
result.fold(
  (devices) => print('Found ${devices.length} devices'),
  (failure) => print('Error: ${failure.message}'),
);
```

### Configuration-Driven Setup

```dart
final manager = WeightScaleManager(
  config: WeightScaleConfig(
    deviceCheckTimeout: Duration(seconds: 1),
    knownScaleDevices: [...WeightScaleConfig.defaultKnownScales, customDevice],
  ),
  logger: SilentLogger(), // For production
);
```

### Device Filtering Strategy

VID/PID whitelisting prevents conflicts with other USB devices. Use `ScaleDeviceIdentifier` for type-safe device matching:

```dart
static const List<ScaleDeviceIdentifier> defaultKnownScales = [
  ScaleDeviceIdentifier(vendorID: '6790', productID: '29987', name: 'Aclas'),
];
```

### Enhanced Protocol Implementation

- **Frame Structure**: 16-byte RS232 frames with SOH/STX/ETX/EOT headers
- **BCC Validation**: Automatic Block Check Character validation with detailed error messages
- **Type Safety**: Strong typing for Status/Status2 enums with `fromByte()` factories
- **Rich Data Model**: `ScaleData` with convenience methods (`isStable`, `numericWeight`, `copyWith()`)

### Native Android Improvements

- **CircularBuffer**: Efficient data buffering preventing memory issues
- **Connection State**: Thread-safe connection management with `AtomicBoolean`
- **Error Categorization**: Detailed error types for USB communication failures
- **Resource Management**: Proper cleanup in `WeightScaleService.cleanup()`

## Development Workflows

### Testing Commands

```bash
# Run comprehensive unit tests
flutter test

# Calculate BCC values for test data
dart test/bcc_calculator.dart

# Run example app with real hardware
cd example && flutter run
```

### Adding New Scale Models

1. Create `ScaleDeviceIdentifier` with decimal VID/PID strings
2. Add to `WeightScaleConfig.knownScaleDevices`
3. Test with `validateDevice()` method
4. Update protocol parsing if frame structure differs

### Error Handling Best Practices

- Use `Result<T>` for all async operations that can fail
- Implement custom error callbacks via `setErrorCallback()`
- Log with appropriate levels using `WeightScaleLogger`
- Handle platform-specific errors in native layer

## Key Files Reference

- `lib/weight_scale_manager.dart` - Main API implementing clean interfaces
- `lib/core/` - Shared utilities (Result, Config, Logger)
- `lib/protocol.dart` - Enhanced RS232 protocol with rich data models
- `lib/examples/usage_examples.dart` - Comprehensive usage patterns
- `android/src/main/kotlin/` - Native implementation with circular buffer
- `test/scale_protocol_test.dart` - Protocol parsing and BCC validation tests

## Refactoring Benefits

- **Type Safety**: Result<T> eliminates exception-based error handling
- **Testability**: Interface-based design enables easy mocking
- **Configuration**: Centralized configuration reduces magic numbers
- **Memory Efficiency**: Circular buffer in native layer prevents memory leaks
- **Error Transparency**: Detailed error messages aid debugging
- **Legacy Compatibility**: Maintains backward compatibility with existing APIs

## Plugin-Specific Conventions

- VID/PID stored as decimal strings (not hex integers)
- Singleton pattern with dependency injection for testing
- Result<T> pattern for all fallible operations
- Interface segregation (Repository/DataStream separation)
- Immutable data models with rich behavior methods
