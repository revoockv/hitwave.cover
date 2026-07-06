sealed class Result<T> {
  const Result();

  factory Result.success([T value]) = SuccessResult;

  factory Result.failure(String error) = FailureResult;

  bool get isSuccess => this is SuccessResult;

  bool get isFailure => this is FailureResult;

  T? get value =>
      this is SuccessResult ? (this as SuccessResult).value : null;

  String? get errorMessage =>
      this is FailureResult ? (this as FailureResult).error : null;
}

class SuccessResult<T> extends Result<T> {
  @override
  final T? value;

  const SuccessResult([this.value]) : super();
}

class FailureResult<T> extends Result<T> {
  final String error;

  const FailureResult(this.error) : super();
}
