import 'package:flutter/material.dart';

abstract class Typo {
  const Typo({
    required this.name,
    required this.regular,
    required this.medium,
    required this.semiBold,
    required this.bold,
  });

  final String name;
  final FontWeight regular;
  final FontWeight medium;
  final FontWeight semiBold;
  final FontWeight bold;
}

class Pretendard implements Typo {
  const Pretendard();

  @override
  String get name => 'Pretendard';

  @override
  FontWeight get regular => FontWeight.w400;

  @override
  FontWeight get medium => FontWeight.w500;

  @override
  FontWeight get semiBold => FontWeight.w600;

  @override
  FontWeight get bold => FontWeight.w700;
}
