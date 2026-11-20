import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Brillo que recorre las siluetas mientras carga el contenido. Un solo
/// [Shimmer] anima todos los [SkeletonBox] que contiene. Si el sistema pide
/// reducir animaciones, las siluetas quedan quietas.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final base = cs.surfaceContainerHighest;
    final highlight = Color.lerp(base, cs.onSurface, 0.07)!;
    if (MediaQuery.of(context).disableAnimations) {
      return ColorFiltered(colorFilter: ColorFilter.mode(base, BlendMode.srcIn), child: widget.child);
    }
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [base, highlight, base],
          stops: const [0.35, 0.5, 0.65],
          transform: _Slide(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

class _Slide extends GradientTransform {
  final double t;
  const _Slide(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

/// Bloque de una silueta (dentro de un [Shimmer]).
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  const SkeletonBox({super.key, this.width, required this.height, this.radius = AppRadius.sm, this.circle = false});

  @override
  Widget build(BuildContext context) => Container(
        width: circle ? height : width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
        ),
      );
}

/// Un bloque suelto con su propio brillo.
class SkeletonLoader extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;

  const SkeletonLoader({super.key, this.height, this.width, this.borderRadius = 12});

  @override
  Widget build(BuildContext context) =>
      Shimmer(child: SkeletonBox(width: width, height: height ?? 16, radius: borderRadius));
}

/// Silueta de la biblioteca: tarjetas de libro (portada + textos + progreso).
class LibrarySkeleton extends StatelessWidget {
  final int count;
  const LibrarySkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: AppSpace.xs),
              child: Row(
                children: [
                  const SkeletonBox(width: 64, height: 96, radius: 10),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonBox(width: 72, height: 18, radius: AppRadius.pill),
                        const SizedBox(height: AppSpace.sm),
                        FractionallySizedBox(widthFactor: i.isEven ? 0.85 : 0.65, child: const SkeletonBox(height: 16)),
                        const SizedBox(height: AppSpace.xs),
                        const FractionallySizedBox(widthFactor: 0.45, child: SkeletonBox(height: 12)),
                        const SizedBox(height: AppSpace.md),
                        const SkeletonBox(height: 6, radius: 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Silueta del cuerpo de los detalles del libro (progreso, datos, sesión).
class BookDetailsSkeleton extends StatelessWidget {
  const BookDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 90, height: 14),
          SizedBox(height: AppSpace.xs),
          SkeletonBox(width: 140, height: 40),
          SizedBox(height: AppSpace.sm),
          SkeletonBox(height: 8, radius: 4),
          SizedBox(height: AppSpace.xl),
          Row(children: [
            Expanded(child: SkeletonBox(height: 72, radius: AppRadius.lg)),
            SizedBox(width: AppSpace.xs),
            Expanded(child: SkeletonBox(height: 72, radius: AppRadius.lg)),
            SizedBox(width: AppSpace.xs),
            Expanded(child: SkeletonBox(height: 72, radius: AppRadius.lg)),
          ]),
          SizedBox(height: AppSpace.md),
          SkeletonBox(height: 180, radius: AppRadius.xxl),
        ],
      ),
    );
  }
}

/// Silueta de las estadísticas: fila de datos y bloques de gráficas.
class StatsSkeleton extends StatelessWidget {
  const StatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Padding(
        padding: EdgeInsets.all(AppSpace.screen),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: SkeletonBox(height: 88, radius: AppRadius.xl)),
              SizedBox(width: AppSpace.sm),
              Expanded(child: SkeletonBox(height: 88, radius: AppRadius.xl)),
              SizedBox(width: AppSpace.sm),
              Expanded(child: SkeletonBox(height: 88, radius: AppRadius.xl)),
            ]),
            SizedBox(height: AppSpace.lg),
            SkeletonBox(height: 48, radius: AppRadius.pill),
            SizedBox(height: AppSpace.lg),
            SkeletonBox(height: 220, radius: AppRadius.xxl),
            SizedBox(height: AppSpace.md),
            SkeletonBox(height: 160, radius: AppRadius.xxl),
          ],
        ),
      ),
    );
  }
}

/// Silueta de Mis citas: tarjetas de cita.
class QuotesSkeleton extends StatelessWidget {
  const QuotesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: Column(
          children: [
            const SkeletonBox(height: 48, radius: AppRadius.pill),
            const SizedBox(height: AppSpace.md),
            for (var i = 0; i < 4; i++) ...[
              SkeletonBox(height: i.isEven ? 132 : 104, radius: AppRadius.xl),
              const SizedBox(height: AppSpace.sm),
            ],
          ],
        ),
      ),
    );
  }
}
