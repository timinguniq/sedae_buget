import 'package:sedae_budget/entity/entity.dart';

CustomCategory customCategoryFromJson(Map<String, dynamic> json) => CustomCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      baseCategoryId: (json['baseCategoryId'] as num).toInt(),
    );

/// PUT 바디. id는 경로에 있으므로 보내지 않는다.
Map<String, dynamic> customCategoryToBody(CustomCategory c) => {
      'name': c.name,
      'baseCategoryId': c.baseCategoryId,
    };
