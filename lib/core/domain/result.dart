sealed class Result<T> {
  const Result();

  const factory Result.success([T? value]) = SuccessResult<T>;
  const factory Result.failure(String message) = FailureResult<T>;
}

final class SuccessResult<T> extends Result<T> {
  final T? value;
  const SuccessResult([this.value]);
}

final class FailureResult<T> extends Result<T> {
  final String message;
  const FailureResult(this.message);
}
