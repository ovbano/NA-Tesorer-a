import 'package:flutter/material.dart';
import 'package:na_tesoreria/core/theme/brand.dart';

/// Confirmaciones reutilizables sin depender de la lógica de tesorería.
/// `true` significa salir/descartar; `false`, continuar editando.
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  String title = '¿Descartar los cambios?',
  String description =
      'Hay información sin guardar. Si sales ahora, perderás los cambios realizados.',
  String continueLabel = 'Seguir editando',
  String discardLabel = 'Salir sin guardar',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;
      final dark = Theme.of(dialogContext).brightness == Brightness.dark;
      return _ResponsiveConfirmDialog(
        borderColor: dark
            ? brandGold.withOpacity(.35)
            : colors.outline.withOpacity(.20),
        header: Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [brandNavy, Color(0xFF174B83)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    color: brandGold, size: 27),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'CAMBIOS SIN GUARDAR',
                  softWrap: true,
                  style: TextStyle(
                    color: brandGold,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: title,
        description: description,
        continueLabel: continueLabel,
        discardLabel: discardLabel,
        continueIcon: Icons.edit_outlined,
        discardIcon: Icons.logout_outlined,
        continueColor: dark ? const Color(0xFF214E8C) : brandNavy,
        discardFilled: false,
      );
    },
  );
  return result ?? false;
}

Future<bool> confirmLeaveEditor(BuildContext context) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return _ResponsiveConfirmDialog(
        borderColor: scheme.outline.withOpacity(.22),
        header: Align(
          alignment: Alignment.center,
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit_note_rounded,
                color: scheme.onErrorContainer, size: 32),
          ),
        ),
        title: '¿Salir sin guardar?',
        description:
            'Hay cambios sin guardar. Si regresas, se perderán los datos '
            'que has ingresado. También puedes guardar un borrador.',
        centerText: true,
        continueLabel: 'Seguir editando',
        discardLabel: 'Salir sin guardar',
        continueIcon: Icons.edit_outlined,
        discardIcon: Icons.arrow_back_rounded,
        discardFilled: true,
      );
    },
  );
  return answer ?? false;
}

/// Un mismo contenedor responsivo para ambas confirmaciones.
/// Evita la fila de acciones de AlertDialog, que puede desbordarse.
class _ResponsiveConfirmDialog extends StatelessWidget {
  const _ResponsiveConfirmDialog({
    required this.header,
    required this.title,
    required this.description,
    required this.continueLabel,
    required this.discardLabel,
    required this.continueIcon,
    required this.discardIcon,
    required this.borderColor,
    this.continueColor,
    this.discardFilled = false,
    this.centerText = false,
  });

  final Widget header;
  final String title, description, continueLabel, discardLabel;
  final IconData continueIcon, discardIcon;
  final Color borderColor;
  final Color? continueColor;
  final bool discardFilled, centerText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screen = MediaQuery.sizeOf(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final accessibleText = MediaQuery.textScalerOf(context).scale(16) > 24;
    final sidePadding = screen.width < 360 ? 12.0 : 20.0;
    final contentPadding = screen.width < 360 ? 18.0 : 24.0;
    final usableHeight = (screen.height - inset - 32).clamp(120.0, screen.height);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 16),
      backgroundColor: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: usableHeight),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: centerText ? TextAlign.center : TextAlign.start,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: centerText ? TextAlign.center : TextAlign.start,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 24),
              // Ambas acciones utilizan el ancho disponible, incluso con texto grande.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: Icon(continueIcon),
                  label: Text(continueLabel, textAlign: TextAlign.center,
                      softWrap: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: continueColor ?? brandNavy,
                    foregroundColor: Colors.white,
                    iconColor: Colors.white,
                    minimumSize: Size(0, accessibleText ? 62 : 54),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: discardFilled
                    ? FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: Icon(discardIcon),
                        label: Text(discardLabel, textAlign: TextAlign.center,
                            softWrap: true),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                          iconColor: scheme.onError,
                          minimumSize: Size(0, accessibleText ? 62 : 54),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: Icon(discardIcon),
                        label: Text(discardLabel, textAlign: TextAlign.center,
                            softWrap: true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          iconColor: scheme.error,
                          side: BorderSide(color: scheme.error.withOpacity(.5)),
                          minimumSize: Size(0, accessibleText ? 62 : 54),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}