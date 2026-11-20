import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Pantalla vacía: ilustración sencilla (icono sobre círculos suaves),
/// título, explicación y, si hay, una acción.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = context.cs;
    final app = context.app;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(color: app.accentSoft.withValues(alpha: 0.45), shape: BoxShape.circle),
                  ),
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(color: app.accentSoft, shape: BoxShape.circle),
                  ),
                  Icon(icon, size: 44, color: app.accentText),
                  Positioned(top: 10, right: 18, child: _dot(cs.primary, 10)),
                  Positioned(bottom: 16, left: 12, child: _dot(app.accent, 7)),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpace.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _dot(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.5), shape: BoxShape.circle),
      );
}
