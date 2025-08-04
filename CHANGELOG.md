# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-08-05

### Added

- Complete Flutter plugin for commercial weight scales via RS232
- Real-time weight data streaming using EventChannel
- Type-safe error handling with Result<T> pattern
- Automatic USB device discovery and validation
- Support for AUTO COMMUNICATE PROTOCOL (16-byte frames)
- Built-in BCC (Block Check Character) validation
- Comprehensive unit test suite with protocol validation
- Integration tests for real hardware testing
- Memory-efficient circular buffer implementation
- Clean architecture with repository and data stream patterns
- Configurable timeouts, logging, and device filtering
- Support for multiple scale models (Aclas and generic)
- Production-ready connection management
- Detailed documentation and usage examples
- **Complete CI/CD pipeline with GitHub Actions**
- **Automated security scanning and vulnerability management**
- **Code quality metrics and performance benchmarking**
- **Community management automation with auto-labeling**
- **Automated dependency updates with Dependabot**
- **Release automation with pub.dev publishing**
- **Comprehensive issue and PR templates**
- **Stale issue management and monthly reporting**
- **Repository setup scripts for easy contribution**

### Supported Platforms

- ✅ Android (full USB-Serial support)

### Technical Features

- Singleton WeightScaleManager for connection safety
- ScaleProtocol with robust frame parsing
- WeightScaleConfig for flexible configuration
- ConsoleLogger and SilentLogger implementations
- WeightScaleDevice model with JSON serialization
- Comprehensive error categorization
- Automatic resource cleanup and memory management
- Example app with platform detection and appropriate messaging

### Important Notes

- This plugin supports Android only
- Other platforms (iOS, Windows, macOS, Linux) are not supported due to technical limitations
- Example app includes platform detection and shows appropriate messages on unsupported platforms

## [0.3.1+2025040801] - 2025-04-08

### Added

- Initial plugin structure
- Basic Android USB-Serial implementation
- Prototype protocol parsing

## [0.0.1] - Initial Release

### Added

- Project scaffolding
- Basic plugin architecture
