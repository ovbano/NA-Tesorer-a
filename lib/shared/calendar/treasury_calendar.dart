import 'package:flutter/material.dart';
import 'package:na_tesoreria/core/theme/brand.dart';

/// Calendario compartido para movimientos, aportes y actividades.
/// Conserva los límites de fecha y la apariencia del dispositivo.
Future<DateTime?> showTreasuryCalendar(
  BuildContext context, {
  required DateTime selected,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Seleccionar fecha',
}) {
  return _showCalendar(
    context,
    selected: selected,
    firstDate: firstDate,
    lastDate: lastDate,
    title: title,
    confirmText: 'Elegir fecha',
    uppercaseTitle: true,
  );
}

/// Variante compatible con los editores existentes.
/// Se mantiene el nombre para no cambiar ninguna llamada actual.
Future<DateTime?> showTreasuryCalendaredit(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Seleccionar fecha',
}) {
  return _showCalendar(
    context,
    selected: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    title: title,
    confirmText: 'Seleccionar',
  );
}

Future<DateTime?> _showCalendar(
  BuildContext context, {
  required DateTime selected,
  required DateTime firstDate,
  required DateTime lastDate,
  required String title,
  required String confirmText,
  bool uppercaseTitle = false,
}) async {
  // Comparar solo fechas evita errores cuando los valores incluyen horas.
  DateTime day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  final first = day(firstDate);
  final last = day(lastDate);
  if (first.isAfter(last)) {
    throw ArgumentError('firstDate no puede ser posterior a lastDate.');
  }
  final desired = day(selected);
  final initial = desired.isBefore(first)
      ? first
      : desired.isAfter(last)
          ? last
          : desired;

  return showDatePicker(
    context: context,
    locale: const Locale('es', 'EC'),
    initialDate: initial,
    firstDate: first,
    lastDate: last,
    initialEntryMode: DatePickerEntryMode.calendar,
    initialDatePickerMode: DatePickerMode.day,
    helpText: uppercaseTitle ? title.toUpperCase() : title,
    cancelText: 'Cancelar',
    confirmText: confirmText,
    fieldLabelText: 'Fecha',
    fieldHintText: 'dd/mm/aaaa',
    errorFormatText: 'Ingresa una fecha válida.',
    errorInvalidText: 'La fecha está fuera del período permitido.',
    builder: (dialogContext, child) {
      final theme = Theme.of(dialogContext);
      final scheme = theme.colorScheme;
      final dark = theme.brightness == Brightness.dark;
      final ink = scheme.onSurface;
      final muted = scheme.onSurfaceVariant;
      final accent = dark ? brandGold : brandNavy;
      const selectedColor = brandNavy;

      final dateTheme = DatePickerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(dark ? .30 : .12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: scheme.outline.withOpacity(.24)),
        ),
        headerBackgroundColor: brandNavy,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        headerHelpStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: .7,
          color: Color(0xFFE5EDFA),
        ),
        weekdayStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
        dayStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
        yearStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
        dayShape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return muted.withOpacity(.42);
          if (states.contains(WidgetState.selected)) return Colors.white;
          return ink;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? selectedColor : null),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return muted.withOpacity(.42);
          if (states.contains(WidgetState.selected)) return Colors.white;
          return ink;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? selectedColor : null),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return muted.withOpacity(.42);
          return accent;
        }),
        todayBorder: BorderSide(color: accent, width: 1.7),
        dayOverlayColor: WidgetStatePropertyAll(accent.withOpacity(.10)),
        yearOverlayColor: WidgetStatePropertyAll(accent.withOpacity(.10)),
        dividerColor: scheme.outline.withOpacity(.25),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: muted),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );

      // El calendario nativo de Flutter adapta su contenido en pantallas
      // estrechas y se desplaza cuando se incrementa la escala del texto.
      return Theme(
        data: theme.copyWith(datePickerTheme: dateTheme),
        child: child!,
      );
    },
  );
}