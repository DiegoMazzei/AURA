import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

const auraBlue = Color(0xff87b7ff);
const auraViolet = Color(0xffad96ff);
const auraPink = Color(0xffec9bc5);

ThemeData auraTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff6476e6),
    brightness: brightness,
    surface: dark ? const Color(0xff0a1120) : const Color(0xfff2f4fc),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Roboto',
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: dark ? const Color(0xfff1f3fc) : const Color(0xff14213b),
      displayColor: dark ? const Color(0xfff1f3fc) : const Color(0xff14213b),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: dark ? auraBlue : const Color(0xff4d61c5),
      thumbColor: dark ? Colors.white : const Color(0xff4d61c5),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: scheme.onSurface.withValues(alpha: .06),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
  );
}

extension AuraContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get ink => Theme.of(this).colorScheme.onSurface;
  Color get muted => ink.withValues(alpha: .65);
}

class AuraGlassSurface extends StatelessWidget {
  const AuraGlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.blur = 16,
  });
  final Widget child;
  final double radius, blur;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (tint ?? (context.isDark ? Colors.white : Colors.white))
                  .withValues(alpha: context.isDark ? .12 : .72),
              (tint ??
                      (context.isDark ? const Color(0xff101c36) : Colors.white))
                  .withValues(alpha: context.isDark ? .62 : .43),
            ],
          ),
          border: Border.all(
            color: context.isDark
                ? Colors.white.withValues(alpha: .18)
                : Colors.white.withValues(alpha: .9),
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class GlassIcon extends StatelessWidget {
  const GlassIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.size = 48,
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
    child: AuraGlassSurface(
      radius: size / 2,
      tint: active ? auraBlue : null,
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        icon: Icon(
          icon,
          size: 21,
          color: active
              ? (context.isDark ? Colors.white : const Color(0xff324791))
              : null,
        ),
      ),
    ),
  );
}

class AuraBackground extends StatefulWidget {
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
  State<AuraBackground> createState() => _AuraBackgroundState();
}

class _AuraBackgroundState extends State<AuraBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  );
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    if (_foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        if (widget.artwork)
          Positioned.fill(
            child: Opacity(
              opacity: context.isDark ? .8 : .32,
              child: Image.asset(
                'assets/images/cosmic-ribbon.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(.8, -.65),
              radius: 1.3,
              colors: [
                widget.color.withValues(alpha: context.isDark ? .22 : .15),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .48, 1],
              colors: [
                base.withValues(alpha: .1),
                base.withValues(alpha: .5),
                base.withValues(alpha: .99),
              ],
            ),
          ),
        ),
        RepaintBoundary(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _Particles(
                  _motion,
                  widget.color,
                  context.isDark ? .7 : .35,
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Particles extends CustomPainter {
  _Particles(this.motion, this.color, this.opacity) : super(repaint: motion);
  final Animation<double> motion;
  final Color color;
  final double opacity;
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (var i = 0; i < 36; i++) {
      final x = random.nextDouble() * size.width;
      final y = ((random.nextDouble() + motion.value * .15) % 1) * size.height;
      final radius = random.nextDouble() * 1.2 + .3;
      canvas.drawCircle(
        Offset(x + math.sin(motion.value * math.pi * 2 + i) * 9, y),
        radius,
        Paint()
          ..color = color.withValues(
            alpha: opacity * (.3 + random.nextDouble() * .6),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_Particles old) =>
      old.color != color || old.opacity != opacity;
}

class CosmicCover extends StatelessWidget {
  const CosmicCover({
    super.key,
    required this.color,
    this.size = 64,
    this.title,
    this.radius = 18,
    this.imageUrl,
  });
  final Color color;
  final double size, radius;
  final String? title;
  final String? imageUrl;
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
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/cosmic-ribbon.png',
                fit: BoxFit.cover,
              ),
            )
          else
            Image.asset(
              'assets/images/cosmic-ribbon.png',
              fit: BoxFit.cover,
              alignment: color == auraPink
                  ? Alignment.bottomLeft
                  : Alignment.centerRight,
            ),
          if (imageUrl == null) ColoredBox(color: color.withValues(alpha: .22)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xff070d20)
                      .withValues(alpha: imageUrl == null ? .85 : .1),
                ],
              ),
            ),
          ),
          if (imageUrl == null)
            Center(
              child: Container(
                width: size * .57,
                height: size * .57,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: .65),
                    width: 1.2,
                  ),
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: .05),
                      color.withValues(alpha: .28),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: .22),
                      blurRadius: size * .15,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: size * .23,
                  color: Colors.white.withValues(alpha: .9),
                ),
              ),
            ),
          if (title != null)
            Positioned(
              left: 13,
              right: 10,
              bottom: 13,
              child: Text(
                title!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size > 200 ? 28 : 15,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ),
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
