// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_category_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomCategoryDto _$CustomCategoryDtoFromJson(Map<String, dynamic> json) =>
    CustomCategoryDto(
      id: json['id'] as String,
      name: json['name'] as String,
      baseCategoryId: (json['baseCategoryId'] as num).toInt(),
    );

Map<String, dynamic> _$CustomCategoryBodyDtoToJson(
  CustomCategoryBodyDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'baseCategoryId': instance.baseCategoryId,
};
