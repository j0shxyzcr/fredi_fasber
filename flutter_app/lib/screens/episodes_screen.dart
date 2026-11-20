import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../theme.dart';

class EpisodesScreen extends StatefulWidget {
  const EpisodesScreen({super.key});
  @override
  State<EpisodesScreen> createState() => _EpisodesScreenState();
}

class _EpisodesScreenState extends State<EpisodesScreen> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() { super.initState(); future = Api.instance.list('/episodes'); }
  Future<void> openVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) flash(context, 'No se pudo abrir el episodio');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Episodios del vlog')),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: future, builder: (ctx, snapshot) {
      if (!snapshot.hasData) return snapshot.hasError ? errorBox('${snapshot.error}') : const Center(child: CircularProgressIndicator());
      if (snapshot.data!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(25), child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.ondemand_video, size: 65, color: gold), SizedBox(height: 14),
          Text('Próximamente: los episodios de FNAF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 9),
          Text('El administrador podrá publicar aquí sus videos narrando la historia y teorías.',
            textAlign: TextAlign.center, style: TextStyle(color: muted)),
        ],
      )));
      return ListView(children: [
        sectionTitle('La historia contada en video', subtitle: 'Episodios del vlog por el equipo del proyecto'),
        ...snapshot.data!.map((e) => Card(margin: const EdgeInsets.fromLTRB(15, 5, 15, 7), child: ListTile(
          leading: const Icon(Icons.play_circle_fill, color: gold, size: 42),
          title: Text(e['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(e['description'] as String, maxLines: 3, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => openVideo(e['video_url'] as String),
        ))),
      ]);
    }),
  );
}
