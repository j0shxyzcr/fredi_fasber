import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../theme.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late Future<List<Map<String, dynamic>>> future;
  final Map<int, int> cart = {};
  @override
  void initState() { super.initState(); future = Api.instance.list('/products'); }
  int get count => cart.values.fold<int>(0, (a, b) => a + b);

  void add(Map<String, dynamic> product) {
    final id = product['id'] as int;
    final stock = product['stock'] as int;
    if ((cart[id] ?? 0) >= stock) { flash(context, 'No hay más existencias'); return; }
    setState(() => cart[id] = (cart[id] ?? 0) + 1);
    flash(context, '${product['character']} agregado al carrito');
  }

  void showCart(List<Map<String, dynamic>> products) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true,
      builder: (_) => FractionallySizedBox(heightFactor: .85,
        child: CartSheet(products: products, selected: Map<int, int>.from(cart), onDone: () {
          if (mounted) setState(cart.clear);
        })),
    ).then((_) { if (mounted) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(future: future,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return snapshot.hasError ? errorBox('${snapshot.error}') : const Center(child: CircularProgressIndicator());
      final items = snapshot.data!;
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fazbear Store', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text('Catálogo de peluches · MXN', style: TextStyle(color: muted, fontSize: 12)),
          ])),
          Badge(label: Text('$count'), isLabelVisible: count > 0,
            child: IconButton(onPressed: () => showCart(items), tooltip: 'Ver carrito',
              icon: const Icon(Icons.shopping_cart_outlined, size: 28))),
        ])),
        Container(margin: const EdgeInsets.fromLTRB(15, 8, 15, 12), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF33251D), borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: gold), SizedBox(width: 9),
            Expanded(child: Text('DEMO ESCOLAR: precios, stock y productos de ejemplo. No son ofertas reales ni artículos oficiales verificados.',
              style: TextStyle(color: gold, fontSize: 11))),
          ])),
        Expanded(child: ListView.builder(itemCount: items.length, itemBuilder: (ctx, i) {
          final item = items[i];
          final stock = item['stock'] as int;
          return Card(margin: const EdgeInsets.fromLTRB(13, 5, 13, 9),
            child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
              CharacterIcon(name: item['character'] as String, size: 57),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Text(item['description'] as String, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 11)),
                const SizedBox(height: 8),
                Text('\$${(item['price'] as num).toStringAsFixed(2)} MXN',
                  style: const TextStyle(color: gold, fontWeight: FontWeight.w800, fontSize: 15)),
                Text(stock > 0 ? 'Disponibles (demo): $stock' : 'Agotado',
                  style: const TextStyle(color: muted, fontSize: 11)),
              ])),
              const SizedBox(width: 5),
              IconButton.filledTonal(tooltip: 'Agregar al carrito', onPressed: stock > 0 ? () => add(item) : null,
                icon: const Icon(Icons.add_shopping_cart)),
            ])),
          );
        })),
      ]);
    },
  );
}

class CartSheet extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Map<int, int> selected;
  final VoidCallback onDone;
  const CartSheet({super.key, required this.products, required this.selected, required this.onDone});
  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  late Map<int, int> selected;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    selected = Map<int, int>.from(widget.selected);
  }

  double get total => widget.products.fold(0.0, (sum, p) =>
    sum + ((p['price'] as num).toDouble() * (selected[p['id']] ?? 0)));

  Future<void> order() async {
    if (selected.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      final result = await Api.instance.post('/orders', {'items': selected.entries.map(
        (e) => {'product_id': e.key, 'quantity': e.value}).toList()});
      final id = result['id'] as int;
      widget.onDone();
      if (!mounted) return;
      String message = 'Pedido de prueba #$id guardado. No se realizó ningún cargo.';
      try {
        final checkout = await Api.instance.post('/orders/$id/checkout', {});
        final link = Uri.tryParse(checkout['url'] as String? ?? '');
        if (link != null && link.isScheme('https')) {
          final opened = await launchUrl(link, mode: LaunchMode.externalApplication);
          message = opened ? 'Pedido #$id creado. Verifica el estado de tu pago en Mi perfil.' : 'No se pudo abrir el enlace de pago.';
        }
      } on ApiException catch (error) {
        // La API no permite cobrar productos DEMO ni pedidos sin configurar Mercado Pago.
        message = 'Pedido DEMO #$id guardado. ${error.message}';
      }
      if (!mounted) return;
      Navigator.pop(context);
      flash(context, message);
    } catch (e) {
      if (mounted) flash(context, '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: const EdgeInsets.all(18), child: Column(children: [
      const Text('Tu carrito', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Expanded(child: selected.isEmpty
        ? const Center(child: Text('Tu carrito está vacío', style: TextStyle(color: muted)))
        : ListView(children: widget.products.where((p) => selected.containsKey(p['id'])).map((p) {
            final id = p['id'] as int;
            return Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              CharacterIcon(name: p['character'] as String, size: 38),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('\$${(p['price'] as num).toStringAsFixed(2)}', style: const TextStyle(color: gold)),
              ])),
              IconButton(onPressed: () => setState(() {
                selected[id] = selected[id]! - 1;
                if (selected[id] == 0) selected.remove(id);
              }), icon: const Icon(Icons.remove_circle_outline)),
              Text('${selected[id]}'),
              IconButton(onPressed: selected[id]! < (p['stock'] as int)
                ? () => setState(() => selected[id] = selected[id]! + 1) : null,
                icon: const Icon(Icons.add_circle_outline)),
            ])));
          }).toList())),
      const Divider(),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Total (demo)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        Text('\$${total.toStringAsFixed(2)} MXN', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: gold)),
      ]),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: selected.isEmpty || busy ? null : order,
        icon: const Icon(Icons.receipt_long), label: Text(busy ? 'Procesando...' : 'Crear pedido / continuar al pago'))),
      const SizedBox(height: 10),
      const Text('Solo se cobran productos verificados cuando configuras Mercado Pago. La tienda inicial es de demostración.',
        textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11)),
    ]),
  ));
}
