import 'package:json_annotation/json_annotation.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'custom_category_dto.g.dart';

/// `/v1/categories` 응답 한 건.
@JsonSerializable(createToJson: false)
class CustomCategoryDto {
  const CustomCategoryDto({required this.id, required this.name, required this.baseCategoryId});

  factory CustomCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CustomCategoryDtoFromJson(json);

  final String id;
  final String name;
  final int baseCategoryId;

  CustomCategory toEntity() => CustomCategory(id: id, name: name, baseCategoryId: baseCategoryId);
}

/// PUT 바디. id는 경로에 있으므로 보내지 않는다.
@JsonSerializable(createFactory: false)
class CustomCategoryBodyDto {
  const CustomCategoryBodyDto({required this.name, required this.baseCategoryId});

  factory CustomCategoryBodyDto.fromEntity(CustomCategory c) =>
      CustomCategoryBodyDto(name: c.name, baseCategoryId: c.baseCategoryId);

  final String name;
  final int baseCategoryId;

  Map<String, dynamic> toJson() => _$CustomCategoryBodyDtoToJson(this);
}
