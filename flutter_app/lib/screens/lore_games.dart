import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';

class LoreScreen extends StatefulWidget {
  const LoreScreen({super.key});
  @override
  State<LoreScreen> createState() => _LoreScreenState();
}

class _LoreScreenState extends State<LoreScreen> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() { super.initState(); future = Api.instance.list('/lore'); }
  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: () async => setState(() { future = Api.instance.list('/lore'); }),
    child: FutureBuilder<List<Map<String, dynamic>>>(future: future, builder: (context, snapshot) {
      if (!snapshot.hasData) return snapshot.hasError ? errorBox('${snapshot.error}') : const Center(child: CircularProgressIndicator());
      return ListView(children: [
        sectionTitle('El misterio de FNAF', subtitle: 'Historia, personajes y teorías del universo Fazbear'),
        const Padding(padding: EdgeInsets.fromLTRB(18, 0, 18, 16), child: Text(
          'Algunas partes de la cronología son teorías de fans. Aquí separamos las pistas de las interpretaciones.', style: TextStyle(color: muted))),
        ...snapshot.data!.map((item) => Card(margin: const EdgeInsets.fromLTRB(14, 5, 14, 8), child: ExpansionTile(
          leading: CircleAvatar(backgroundColor: purple.withOpacity(.18), child: Text('${item['position']}', style: const TextStyle(color: gold))),
          title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(item['summary'] as String, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 12)),
          children: [Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
            child: Text(item['body'] as String, style: const TextStyle(height: 1.55)))],
        ))),
        const SizedBox(height: 30),
      ]);
    }),
  );
}

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});
  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() { super.initState(); future = Api.instance.list('/games'); }
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(future: future,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return snapshot.hasError ? errorBox('${snapshot.error}') : const Center(child: CircularProgressIndicator());
      return ListView(children: [
        sectionTitle('Los videojuegos', subtitle: 'Una guía de las entregas principales por lanzamiento'),
        ...snapshot.data!.asMap().entries.map((entry) {
          final game = entry.value;
          return Card(margin: const EdgeInsets.fromLTRB(14, 5, 14, 8), child: Padding(
            padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 60, height: 74, decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF503075), Color(0xFF241A35)]),
                borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.videogame_asset, color: gold, size: 32)),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${game['year']} · JUEGO ${entry.key + 1}', style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(game['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(game['description'] as String, style: const TextStyle(color: muted, fontSize: 12, height: 1.4)),
              ])),
            ]),
          ));
        }),
        const SizedBox(height: 20),
      ]);
    },
  );
}
