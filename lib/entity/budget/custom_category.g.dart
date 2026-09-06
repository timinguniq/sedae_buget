// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CustomCategory _$CustomCategoryFromJson(Map<String, dynamic> json) =>
    _CustomCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      baseCategoryId: (json['baseCategoryId'] as num).toInt(),
    );

Map<String, dynamic> _$CustomCategoryToJson(_CustomCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'baseCategoryId': instance.baseCategoryId,
    };
