import 'package:flutter/material.dart';

const ink = Color(0xFF0C0914);
const surface = Color(0xFF1A1525);
const purple = Color(0xFF9D69FF);
const lavender = Color(0xFFDED0FF);
const gold = Color(0xFFFFC857);
const muted = Color(0xFFAFA7C1);

ThemeData makeTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ink,
    colorScheme: const ColorScheme.dark(primary: purple, secondary: gold, surface: surface),
    appBarTheme: const AppBarTheme(backgroundColor: ink, elevation: 0, centerTitle: false),
    cardTheme: CardThemeData(color: surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0xFF221B2F),
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFF383043))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: purple, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Colors.redAccent)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      backgroundColor: purple, foregroundColor: Colors.white,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    )),
  );
}

Widget sectionTitle(String title, {String? subtitle}) => Padding(
  padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
    if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: const TextStyle(color: muted))),
  ]),
);

Widget errorBox(String message) => Padding(
  padding: const EdgeInsets.all(24),
  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, color: gold, size: 35),
    const SizedBox(height: 14),
    Text(message, textAlign: TextAlign.center, style: const TextStyle(color: muted)),
  ])),
);

void flash(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

class CharacterIcon extends StatelessWidget {
  final String name;
  final double size;
  const CharacterIcon({super.key, required this.name, this.size = 55});
  @override
  Widget build(BuildContext context) {
    final lower = name.toLowerCase();
    final symbol = lower.contains('foxy') ? '🦊' : lower.contains('chica') ? '🐥' : lower.contains('bonnie') ? '🐰' : '🐻';
    return Container(width: size + 26, height: size + 24,
      decoration: BoxDecoration(color: purple.withOpacity(.14), borderRadius: BorderRadius.circular(18)),
      child: Center(child: Text(symbol, style: TextStyle(fontSize: size * .7))));
  }
}
