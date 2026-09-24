import 'package:sedae_budget/entity/entity.dart';

/// 실패면 사용자에게 보여줄 문구, 성공이면 null.
String? categoryErrorMessage(Result<CustomCategory> res) {
  final error = res.failureOrNull;
  if (error == null) return null;
  return error.message.isEmpty ? '저장하지 못했어요' : error.message;
}
