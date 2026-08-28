import 'api_exception.dart';

/// Target-shaped `Result<T>` per docs/10 §4. Small and sealed — no dartz.
sealed class Result<T> {
  const Result();

  factory Result.ok(T value) = Ok<T>;
  factory Result.err(ApiException error) = Err<T>;

  R when<R>({
    required R Function(T value) ok,
    required R Function(ApiException error) err,
  }) {
    final self = this;
    if (self is Ok<T>) return ok(self.value);
    return err((self as Err<T>).error);
  }

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final ApiException error;
}
