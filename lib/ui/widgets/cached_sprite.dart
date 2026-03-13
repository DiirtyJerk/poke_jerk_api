import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Shared wrapper around [CachedNetworkImage] for sprite / artwork loading.
///
/// Handles null/empty URLs, provides a consistent faded Poké Ball placeholder
/// and error icon, and applies a short fade-in for smooth appearance.
class CachedSprite extends StatelessWidget {
  const CachedSprite({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  /// Image URL. When null or empty the [placeholder] (or the default icon) is
  /// shown instead.
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Custom placeholder widget. When omitted a faded [Icons.catching_pokemon]
  /// icon is used for both loading and error states.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final fallback = placeholder ?? _defaultIcon;

    if (url == null || url!.isEmpty) {
      return SizedBox(width: width, height: height, child: Center(child: fallback));
    }

    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) => Center(child: fallback),
      errorWidget: (_, _, _) => Center(child: fallback),
    );
  }

  Widget get _defaultIcon {
    final iconSize = _iconSize;
    return Icon(
      Icons.catching_pokemon,
      size: iconSize,
      color: Colors.grey.shade300,
    );
  }

  double get _iconSize {
    if (width != null && height != null) return (width! < height! ? width! : height!) * 0.5;
    if (width != null) return width! * 0.5;
    if (height != null) return height! * 0.5;
    return 40;
  }
}
