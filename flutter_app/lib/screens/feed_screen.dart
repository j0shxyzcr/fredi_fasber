import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';

const reactionOptions = <String, String>{
  'like': '👍', 'love': '❤️', 'haha': '😆', 'wow': '😮', 'sad': '😢', 'angry': '😡',
};

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() { super.initState(); refresh(); }
  void refresh() => future = Api.instance.list('/posts');
  void reload() => setState(refresh);

  Future<void> createPost() async {
    final controller = TextEditingController();
    final content = await showDialog<String>(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva publicación'),
        content: TextField(controller: controller, minLines: 4, maxLines: 8, maxLength: 1500,
          decoration: const InputDecoration(hintText: 'Comparte una teoría, historia o comentario sobre FNAF...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Publicar')),
        ],
      ),
    );
    controller.dispose();
    if (content == null || content.isEmpty) return;
    try {
      await Api.instance.post('/posts', {'content': content});
      if (!mounted) return;
      reload(); flash(context, '¡Publicación creada!');
    } catch (e) { if (mounted) flash(context, '$e'); }
  }

  Future<void> react(Map<String, dynamic> post, String? choice) async {
    try {
      await Api.instance.post('/posts/${post['id']}/reactions', {'kind': choice});
      if (mounted) reload();
    } catch (e) { if (mounted) flash(context, '$e'); }
  }

  Future<void> chooseReaction(Map<String, dynamic> post) async {
    final selection = await showModalBottomSheet<String>(context: context, showDragHandle: true,
      builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(15),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('¿Cómo reaccionas?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(spacing: 12, runSpacing: 10,
            children: reactionOptions.entries.map((r) => InkWell(onTap: () => Navigator.pop(ctx, r.key),
              borderRadius: BorderRadius.circular(12),
              child: Padding(padding: const EdgeInsets.all(9), child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(r.value, style: const TextStyle(fontSize: 32)),
                Text(r.key, style: const TextStyle(fontSize: 11, color: muted)),
              ])))).toList()),
          const SizedBox(height: 18),
          TextButton(onPressed: () => Navigator.pop(ctx, 'remove'), child: const Text('Quitar mi reacción')),
        ]))));
    if (selection != null) await react(post, selection == 'remove' ? null : selection);
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Comunidad Fazbear', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Text('Teorías, debates y publicaciones', style: TextStyle(color: muted, fontSize: 12)),
      ])),
      IconButton(tooltip: 'Actualizar', onPressed: reload, icon: const Icon(Icons.refresh)),
    ])),
    Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: SizedBox(width: double.infinity,
      child: FilledButton.icon(onPressed: createPost, icon: const Icon(Icons.edit_square), label: const Text('¿Qué teoría quieres compartir?')))),
    Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: future, builder: (context, snapshot) {
      if (!snapshot.hasData) return snapshot.hasError ? errorBox('${snapshot.error}') : const Center(child: CircularProgressIndicator());
      if (snapshot.data!.isEmpty) return RefreshIndicator(onRefresh: () async => reload(), child: ListView(children: [
        const SizedBox(height: 90), const Icon(Icons.forum_outlined, size: 55, color: muted),
        const SizedBox(height: 15), const Center(child: Text('Sé el primero en publicar una teoría')),
      ]));
      return RefreshIndicator(onRefresh: () async => reload(), child: ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          final post = snapshot.data![index];
          final counts = Map<String, dynamic>.from(post['reactions'] as Map);
          final total = counts.values.fold<int>(0, (a, b) => a + (b as num).toInt());
          final mine = post['my_reaction'] as String?;
          return Card(margin: const EdgeInsets.fromLTRB(13, 5, 13, 10), child: Padding(
            padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(backgroundColor: purple.withOpacity(.25), child: Text((post['author'] as String)[0].toUpperCase(),
                  style: const TextStyle(color: lavender, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post['author'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('Miembro de la comunidad', style: TextStyle(color: muted, fontSize: 11)),
                ])),
                const Icon(Icons.more_horiz, color: muted),
              ]),
              Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: Text(post['content'] as String,
                style: const TextStyle(fontSize: 14, height: 1.5))),
              Row(children: [
                Text(total == 0 ? 'Sin reacciones' : '$total reacciones', style: const TextStyle(color: muted, fontSize: 12)),
                const Spacer(),
                Text('${post['comments_count']} comentarios', style: const TextStyle(color: muted, fontSize: 12)),
              ]),
              const Divider(height: 25, color: Color(0xFF393044)),
              Row(children: [
                Expanded(child: TextButton.icon(onPressed: () => chooseReaction(post),
                  icon: Text(mine == null ? '👍' : reactionOptions[mine] ?? '👍', style: const TextStyle(fontSize: 18)),
                  label: Text(mine == null ? 'Reaccionar' : 'Reaccionaste', style: TextStyle(color: mine == null ? muted : gold)))),
                Expanded(child: TextButton.icon(onPressed: () async {
                  await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true,
                    builder: (_) => CommentsSheet(postId: post['id'] as int));
                  if (mounted) reload();
                }, icon: const Icon(Icons.mode_comment_outlined, size: 19),
                  label: const Text('Comentar'), style: TextButton.styleFrom(foregroundColor: muted))),
              ]),
            ]),
          ));
        },
      ));
    })),
  ]);
}

class CommentsSheet extends StatefulWidget {
  final int postId;
  const CommentsSheet({super.key, required this.postId});
  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final controller = TextEditingController();
  late Future<List<Map<String, dynamic>>> comments;
  bool sending = false;
  @override
  void initState() { super.initState(); load(); }
  void load() => comments = Api.instance.list('/posts/${widget.postId}/comments');
  @override
  void dispose() { controller.dispose(); super.dispose(); }

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await Api.instance.post('/posts/${widget.postId}/comments', {'content': text});
      controller.clear();
      if (mounted) setState(load);
    } catch (e) { if (mounted) flash(context, '$e'); }
    finally { if (mounted) setState(() => sending = false); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: SizedBox(height: MediaQuery.sizeOf(context).height * .7,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: Column(children: [
        const Text('Comentarios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: comments, builder: (context, snap) {
          if (!snap.hasData) return snap.hasError ? errorBox('${snap.error}') : const Center(child: CircularProgressIndicator());
          if (snap.data!.isEmpty) return const Center(child: Text('Todavía no hay comentarios', style: TextStyle(color: muted)));
          return ListView.builder(itemCount: snap.data!.length, itemBuilder: (ctx, i) {
            final item = snap.data![i];
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(item['author'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text(item['content'] as String),
            ));
          });
        })),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: controller, maxLength: 700, maxLines: 2, minLines: 1,
            decoration: const InputDecoration(hintText: 'Escribe un comentario...', counterText: ''))),
          IconButton(onPressed: sending ? null : send, icon: const Icon(Icons.send, color: gold)),
        ]),
        const SizedBox(height: 14),
      ])),
    ),
  );
}
