sealed class Result<T> {}

class Nil {}

class Success<T> extends Result<T> {
  final T value;
  Success(this.value);
}

class Failure<T> extends Result<T> {
  final Exception error;
  final Object? value;

  Failure(this.error, [this.value]);
}

Result<Nil> successOfNil() => Success(Nil());