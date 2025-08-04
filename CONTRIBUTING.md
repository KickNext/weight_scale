# Contributing to Weight Scale Plugin

We love your input! We want to make contributing to Weight Scale Plugin as easy and transparent as possible, whether it's:

- 🐛 Reporting a bug
- 📱 Adding support for a new scale device
- 💬 Discussing the current state of the code
- ✨ Submitting a feature request
- 📝 Proposing changes to documentation
- 🔄 Becoming a maintainer

## 🚀 Quick Start for Contributors

### Prerequisites

- Flutter SDK (3.27.0 or later)
- Android development environment
- Git
- A compatible scale device (for device-specific contributions)

### Setup

1. **Fork the repository**

   ```bash
   git clone https://github.com/YOUR_USERNAME/weight_scale.git
   cd weight_scale
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   cd example && flutter pub get
   ```

3. **Run tests**

   ```bash
   flutter test
   ```

4. **Run the example app**
   ```bash
   cd example
   flutter run
   ```

## Development Process

We use GitHub to host code, track issues and feature requests, as well as accept pull requests.

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code follows the existing style
6. Issue that pull request!

## Pull Requests

1. Ensure any install or build dependencies are removed before the end of the layer when doing a build
2. Update the README.md with details of changes to the interface
3. Update the CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/) format
4. The PR will be merged once you have the sign-off of a maintainer

## Any contributions you make will be under the MIT Software License

When you submit code changes, your submissions are understood to be under the same [MIT License](LICENSE) that covers the project.

## Report bugs using GitHub's [issue tracker](https://github.com/nikitiser/weight_scale/issues)

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/nikitiser/weight_scale/issues/new).

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Development Setup

1. Install Flutter SDK
2. Clone this repository
3. Run `flutter pub get` in the root directory
4. Run `cd example && flutter pub get` for the example app

## Testing

- Run `flutter test` for unit tests
- Run `cd example && flutter test integration_test/` for integration tests
- Test on real hardware when possible

## Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter format` to format your code
- Follow existing patterns in the codebase
- Add documentation for public APIs

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
