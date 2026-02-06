import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Utility class for optimized image loading and caching
class ImageUtils {
  /// Build a cached network image with smooth loading
  static Widget buildCachedImage({
    required String? imageUrl,
    Widget? placeholder,
    Widget? errorWidget,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              ),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }

  /// Build an optimized circular avatar
  static Widget buildAvatarImage({
    required String? imageUrl,
    required double radius,
    Widget? placeholder,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: ClipOval(
        child: buildCachedImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder:
              placeholder ??
              Container(
                width: radius * 2,
                height: radius * 2,
                color: Colors.grey[800],
                child: Icon(Icons.person, size: radius, color: Colors.white54),
              ),
        ),
      ),
    );
  }

  /// Build a skeleton shimmer for image loading
  static Widget buildImageSkeleton({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!],
        ),
        borderRadius: borderRadius,
      ),
    );
  }
}
