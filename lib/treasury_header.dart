import 'package:flutter/material.dart';
import 'brand.dart';

/// Encabezado institucional reutilizable: se adapta al ancho y al texto ampliado.
class TreasuryHeader extends StatelessWidget implements PreferredSizeWidget {
  const TreasuryHeader({super.key, required this.title, this.overline = 'TESORERÍA', this.busy = false});

  final String title;
  final String overline;
  final bool busy;

  @override
  Size get preferredSize => const Size.fromHeight(86);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final compact = width < 380 || scale > 1.25;
    return AppBar(
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff071832), brandNavy, Color(0xff1b497d)],
          ),
          border: Border(bottom: BorderSide(color: Color(0xffb99a5f), width: 1.4)),
        ),
        child: Align(
          alignment: Alignment.bottomRight,
        ),
      ),
      titleSpacing: 12,
      title: Row(children: [
        Material(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(14),
          child: IconButton(
            tooltip: 'Volver',
            onPressed: busy ? null : () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            color: Colors.white,
            disabledColor: Colors.white54,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!compact) Text(overline.toUpperCase(), maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: brandGold, fontSize: 10,
                fontWeight: FontWeight.w800, letterSpacing: 2)),
            if (!compact) const SizedBox(height: 3),
            Text(title, maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white,
                fontSize: compact ? 17 : 20, height: 1.18,
                fontWeight: FontWeight.w800)),
          ],
        )),
      ]),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(child: Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              border: Border.all(color: brandGold.withOpacity(.6)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 22),
              child: const ThemeButton(),
            ),
          )),
        ),
      ],
    );
  }
}
