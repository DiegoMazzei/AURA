import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../app/aura_controller.dart';
import '../design/aura_design.dart';

/// Keeps remote artwork on disk and falls back to the original track thumbnail.
class MusicImage extends StatefulWidget {
  const MusicImage({
    super.key,
    required this.controller,
    required this.artist,
    this.album = '',
    this.portrait = false,
    this.fallbackUrl,
    this.size = 56,
    this.radius = 12,
  });
  final AuraController controller;
  final String artist, album;
  final bool portrait;
  final String? fallbackUrl;
  final double size, radius;
  @override
  State<MusicImage> createState() => _MusicImageState();
}

class _MusicImageState extends State<MusicImage> {
  late Future<File?> _image = _load();
  Future<File?> _load() async {
    final repository = widget.controller.artwork;
    if (repository == null) return null;
    final url = widget.portrait
        ? await repository.artist(widget.artist)
        : await repository.album(widget.artist, widget.album);
    for (final source in {
      ?url,
      if (widget.fallbackUrl != null) widget.fallbackUrl!,
    }) {
      try {
        return await DefaultCacheManager().getSingleFile(source);
      } catch (_) {
        /* Try the original image when a cover is missing. */
      }
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant MusicImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.artist != widget.artist ||
        oldWidget.album != widget.album ||
        oldWidget.fallbackUrl != widget.fallbackUrl ||
        oldWidget.portrait != widget.portrait) {
      _image = _load();
    }
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(widget.radius),
    child: SizedBox(
      width: widget.size,
      height: widget.size,
      child: FutureBuilder<File?>(
        key: ValueKey(_image),
        future: _image,
        builder: (_, snapshot) {
          if (snapshot.data != null) {
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => _fallback(),
            );
          }
          return _fallback();
        },
      ),
    ),
  );
  Widget _fallback() => widget.portrait
      ? ColoredBox(
          color: const Color(0xff30233e),
          child: Center(
            child: Icon(
              Icons.person_rounded,
              color: const Color(0xffb99ed0),
              size: widget.size * .42,
            ),
          ),
        )
      : CosmicCover(
          size: widget.size,
          radius: widget.radius,
          imageUrl: widget.fallbackUrl,
          color: const Color(0xff9b62ef),
        );
}
