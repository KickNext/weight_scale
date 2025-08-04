/// Result type for handling success and failure cases in a type-safe manner
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.error, this.stackTrace});

  @override
  String toString() =>
      'Failure: $message${error != null ? ' (${error.toString()})' : ''}';
}

/// Extension methods for Result
extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => isSuccess ? (this as Success<T>).data : null;
  Failure<T>? get failureOrNull => isFailure ? (this as Failure<T>) : null;

  R fold<R>(
      R Function(T data) onSuccess, R Function(Failure<T> failure) onFailure) {
    return switch (this) {
      final Success<T> success => onSuccess(success.data),
      final Failure<T> failure => onFailure(failure),
    };
  }
}
