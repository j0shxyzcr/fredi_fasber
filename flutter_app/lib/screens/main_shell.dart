import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';
import 'lore_games.dart';
import 'feed_screen.dart';
import 'store_screen.dart';
import 'episodes_screen.dart';

class MainShell extends StatefulWidget {
  final Map<String, dynamic> user;
  final Future<void> Function() onLogout;
  const MainShell({super.key, required this.user, required this.onLogout});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  final tabs = const ['Inicio', 'Lore', 'Juegos', 'Comunidad', 'Tienda'];
  final icons = const [Icons.home_outlined, Icons.menu_book_outlined,
    Icons.sports_esports_outlined, Icons.groups_2_outlined, Icons.shopping_bag_outlined];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('FAZBEAR ARCHIVES', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
        Text(tabs[tab].toUpperCase(), style: const TextStyle(fontSize: 10, color: gold, letterSpacing: 2)),
      ]),
      actions: [
        IconButton(tooltip: 'Mi cuenta y pedidos', onPressed: () => _showProfile(context),
          icon: CircleAvatar(backgroundColor: purple.withOpacity(.22), child: Text((widget.user['username'] as String)[0].toUpperCase(), style: const TextStyle(color: lavender)))),
        const SizedBox(width: 10),
      ],
    ),
    body: IndexedStack(index: tab, children: [
      HomeScreen(username: widget.user['username'] as String, changeTab: (i) => setState(() => tab = i)),
      const LoreScreen(),
      const GamesScreen(),
      const FeedScreen(),
      const StoreScreen(),
    ]),
    bottomNavigationBar: NavigationBar(
      backgroundColor: surface,
      indicatorColor: purple.withOpacity(.25),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 72,
      selectedIndex: tab,
      onDestinationSelected: (i) => setState(() => tab = i),
      destinations: List.generate(tabs.length, (i) => NavigationDestination(
        icon: Icon(icons[i]), selectedIcon: Icon(icons[i], color: lavender), label: tabs[i],
      )),
    ),
  );

  void _showProfile(BuildContext context) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true,
      showDragHandle: true, builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mi perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 12),
          ListTile(leading: const Icon(Icons.person, color: purple),
            title: Text(widget.user['username'] as String), subtitle: Text(widget.user['email'] as String)),
          ListTile(leading: const Icon(Icons.receipt_long, color: gold), title: const Text('Mis pedidos'),
            onTap: () { Navigator.pop(sheetContext); _showOrders(context); }),
          ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text('Cerrar sesión'),
            onTap: () { Navigator.pop(sheetContext); widget.onLogout(); }),
        ]),
      )));
  }

  void _showOrders(BuildContext context) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true,
      builder: (_) => const FractionallySizedBox(heightFactor: .75, child: OrdersSheet()));
  }
}

class HomeScreen extends StatelessWidget {
  final String username;
  final ValueChanged<int> changeTab;
  const HomeScreen({super.key, required this.username, required this.changeTab});

  @override
  Widget build(BuildContext context) => ListView(children: [
    Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF44236A), Color(0xFF1E1733), Color(0xFF100E1A)]),
        border: Border.all(color: const Color(0xFF69508A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('BIENVENIDO A LA PIZZERÍA', style: TextStyle(fontSize: 11, letterSpacing: 2, color: gold)),
        const SizedBox(height: 9),
        Text('¡Hola, $username!', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('Descubre los misterios de Five Nights at Freddy’s. Comparte teorías, explora los juegos y visita la tienda.',
          style: TextStyle(color: lavender, height: 1.45)),
        const SizedBox(height: 21),
        FilledButton.icon(onPressed: () => changeTab(1), icon: const Icon(Icons.auto_stories), label: const Text('Explorar el lore')),
      ]),
    ),
    Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: Card(child: ListTile(
      leading: const CircleAvatar(backgroundColor: Color(0xFF51355E), child: Icon(Icons.play_circle_fill, color: gold)),
      title: const Text('Episodios del vlog', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('La historia de FNAF narrada en video'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EpisodesScreen())),
    ))),
    sectionTitle('Explora el universo', subtitle: 'Todo FNAF en un solo lugar'),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
      children: [
        _shortcut(Icons.menu_book, 'HISTORIA Y LORE', 'Misterios, personajes y pistas', 1),
        _shortcut(Icons.sports_esports, 'VIDEOJUEGOS', 'Conoce cada entrega', 2),
        _shortcut(Icons.forum, 'COMUNIDAD', 'Publica y reacciona', 3),
        _shortcut(Icons.shopping_bag, 'TIENDA', 'Peluches y carrito', 4),
      ],
    )),
    Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
        const Icon(Icons.info_outline, color: gold), const SizedBox(width: 12),
        Expanded(child: Text('App educativa creada por fans. Los artículos de la tienda son demostraciones hasta validar proveedor y licencia.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted))),
      ])))),
  ]);

  Widget _shortcut(IconData icon, String title, String subtitle, int target) => InkWell(
    onTap: () => changeTab(target), borderRadius: BorderRadius.circular(18),
    child: Container(padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF30283E))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: gold, size: 29), const Spacer(),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: .5)),
        const SizedBox(height: 4), Text(subtitle, maxLines: 2,
          style: const TextStyle(color: muted, fontSize: 11)),
      ])),
  );
}

class OrdersSheet extends StatefulWidget {
  const OrdersSheet({super.key});
  @override
  State<OrdersSheet> createState() => _OrdersSheetState();
}

class _OrdersSheetState extends State<OrdersSheet> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() { super.initState(); refresh(); }
  void refresh() => future = Api.instance.list('/orders');

  Future<void> verify(int id) async {
    try {
      final order = await Api.instance.post('/orders/$id/verify-payment', {});
      if (!mounted) return;
      flash(context, order['status'] == 'paid' ? 'Pago confirmado' : 'El pago aún no está confirmado');
      setState(refresh);
    } catch (e) { if (mounted) flash(context, '$e'); }
  }

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(children: [
      const Text('Mis pedidos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: future,
        builder: (context, snap) {
          if (!snap.hasData) return snap.hasError ? errorBox('${snap.error}') : const Center(child: CircularProgressIndicator());
          final data = snap.data!;
          if (data.isEmpty) return const Center(child: Text('Aún no tienes pedidos', style: TextStyle(color: muted)));
          return ListView.builder(itemCount: data.length, itemBuilder: (context, i) {
            final order = data[i];
            return Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pedido #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('\$${(order['total'] as num).toStringAsFixed(2)} MXN · ${order['status']}', style: const TextStyle(color: gold)),
              ...((order['items'] as List).map((item) => Text('${item['quantity']} x ${item['name']}',
                style: const TextStyle(color: muted, fontSize: 12)))),
              if (order['status'] == 'pending_payment') Align(alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => verify(order['id'] as int), child: const Text('Verificar pago'))),
            ])));
          });
        },
      )),
    ]));
}
