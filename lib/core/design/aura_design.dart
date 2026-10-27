import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'native_materials.dart';

const auraBlue = Color(0xffb486ff);
const auraViolet = Color(0xffac72fa);
const auraPink = Color(0xffe09bb9);

ThemeData auraTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff9750e8),
    brightness: brightness,
    surface: dark ? const Color(0xff100b18) : const Color(0xfffaf7ff),
    primary: dark ? auraBlue : const Color(0xff7435bc),
  );
  final family = defaultTargetPlatform == TargetPlatform.iOS
      ? '.SF Pro Text'
      : 'Roboto';
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: family,
  );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.onSurface.withValues(alpha: .07),
      thickness: .5,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.onSurface,
      thumbColor: scheme.onSurface,
      inactiveTrackColor: scheme.onSurface.withValues(alpha: .15),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.onSurface.withValues(alpha: .04),
      selectedColor: scheme.onSurface.withValues(alpha: .10),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.onSurface.withValues(alpha: .06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}

extension AuraContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get ink => Theme.of(this).colorScheme.onSurface;
  Color get muted => ink.withValues(alpha: .55);
}

/// Content cards are deliberately opaque surfaces, not imitation glass.
/// Native Liquid Glass is reserved for UIKit navigation and controls.
class AuraGlassSurface extends StatelessWidget {
  const AuraGlassSurface({
    super.key,
    required this.child,
    this.radius = 18,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.blur = 0,
  });
  final Widget child;
  final double radius, blur;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  @override
  Widget build(BuildContext context) => Material(
    color:
        tint?.withValues(alpha: .08) ??
        (context.isDark ? const Color(0xff21162f) : const Color(0xffeee6f8)),
    borderRadius: BorderRadius.circular(radius),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

String _symbol(IconData icon) {
  if (icon == Icons.search_rounded || icon == Icons.search) {
    return 'magnifyingglass';
  }
  if (icon == Icons.tune_rounded) return 'slider.horizontal.3';
  if (icon == Icons.add_rounded || icon == Icons.add) return 'plus';
  if (icon == Icons.keyboard_arrow_down_rounded) return 'chevron.down';
  if (icon == Icons.arrow_back_ios_new_rounded) return 'chevron.left';
  if (icon == Icons.favorite || icon == Icons.favorite_rounded) {
    return 'heart.fill';
  }
  if (icon == Icons.favorite_border) return 'heart';
  if (icon == Icons.close || icon == Icons.close_rounded) return 'xmark';
  if (icon == Icons.graphic_eq_rounded) return 'waveform';
  if (icon == Icons.lyrics_outlined) return 'text.quote';
  if (icon == Icons.mic_none_rounded) return 'mic';
  if (icon == Icons.queue_music_rounded) return 'list.bullet';
  if (icon == Icons.playlist_add_rounded) return 'text.badge.plus';
  if (icon == Icons.pause_rounded) return 'pause.fill';
  if (icon == Icons.play_arrow_rounded) return 'play.fill';
  if (icon == Icons.more_horiz) return 'ellipsis';
  return 'ellipsis';
}

class GlassIcon extends StatelessWidget {
  const GlassIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.size = 44,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: NativeMaterials.available
        ? NativeGlassControl(
            kind: 'button',
            config: {
              'symbol': _symbol(icon),
              'label': label,
              'active': active,
              'enabled': onPressed != null,
              'dark': context.isDark,
            },
            onEvent: (method, _) {
              if (method == 'pressed') onPressed?.call();
            },
          )
        : IconButton(
            onPressed: onPressed,
            tooltip: label,
            style: IconButton.styleFrom(
              backgroundColor: context.ink.withValues(alpha: .06),
            ),
            icon: Icon(
              icon,
              size: 20,
              color: active ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
  );
}

class AuraBackground extends StatelessWidget {
  const AuraBackground({
    super.key,
    required this.child,
    this.color = auraBlue,
    this.artwork = false,
  });
  final Widget child;
  final Color color;
  final bool artwork;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      gradient: RadialGradient(
        center: const Alignment(.9, -1),
        radius: 1.6,
        colors: [
          Color.alphaBlend(
            color.withValues(alpha: context.isDark ? .055 : .035),
            Theme.of(context).scaffoldBackgroundColor,
          ),
          Theme.of(context).scaffoldBackgroundColor,
        ],
        stops: const [0, .8],
      ),
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class CosmicCover extends StatelessWidget {
  const CosmicCover({
    super.key,
    this.color = auraBlue,
    this.size = 64,
    this.title,
    this.radius = 10,
    this.imageUrl,
  });
  final Color color;
  final double size, radius;
  final String? title, imageUrl;
  Widget _fallback() => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            color.withValues(alpha: .48),
            const Color(0xff14161f),
          ),
          const Color(0xff171922),
        ],
      ),
    ),
    child: Center(
      child: Icon(
        Icons.music_note_rounded,
        color: Colors.white.withValues(alpha: .65),
        size: size * .28,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          else
            _fallback(),
          if (title != null) ...[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                title!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size > 200 ? 26 : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -.5,
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: context.muted),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.muted),
        ),
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 18), child: action!),
      ],
    ),
  );
}
