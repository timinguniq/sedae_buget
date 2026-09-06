import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/theme/theme.dart';

final _logger = CustomLogger.create(tag: (CCachedNetworkImage).toString());

class CCachedNetworkImage extends StatelessWidget {
  const CCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _ErrorWidget(width: width, height: height, error: 'imageUrl is empty');
    }

    try {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        placeholder: placeholder ?? (_, __) => CircularIndicator(size: width),
        errorWidget: errorWidget ?? (_, __, error) => _ErrorWidget(width: width, height: height, error: error),
        //cacheManager: CCacheManager.instance,
        memCacheHeight: height?.toInt(),
        memCacheWidth: width?.toInt(),
        imageBuilder: (context, imageProvider) {
          final aspectRatio = width != null && height != null ? width! / height! : null;
          return aspectRatio == null
              ? Image(image: imageProvider, fit: fit)
              : AspectRatio(
            aspectRatio: aspectRatio,
            child: Image(image: imageProvider, fit: fit),
          );
        },
      );
    } catch (e, st) {
      _logger.e('error=$e', error: e, stackTrace: st);
      return _ErrorWidget(width: width, height: height);
    }
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({
    this.width,
    this.height,
    this.error,
  });

  final double? width;
  final double? height;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      _logger.e('error=$error');
    }
    return SizedBox(
      width: width,
      height: height,
      child: const CIcon(icon: CIcons.circleExclamation),
    );
  }
}
