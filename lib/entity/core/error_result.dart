class ErrorResult<T> {
  ErrorResult({
    this.resultCode = 'SUCCESS',
    this.message,
    this.data,
  });

  final String? resultCode;
  final String? message;
  final T? data;

  @override
  String toString() {
    return '{'
        ' resultCode: $resultCode,'
        ' message: $message,'
        ' data: $data,'
        '}';
  }
}
