import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool registering = false;
  bool busy = false;
  bool showPass = false;
  String? error;

  @override
  void dispose() {
    username.dispose(); email.dispose(); password.dispose(); super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() { busy = true; error = null; });
    try {
      final account = registering
        ? await Api.instance.register(username.text.trim(), email.text.trim(), password.text)
        : await Api.instance.login(email.text.trim(), password.text);
      widget.onAuthenticated(account);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Form(
        key: formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Center(child: Text('🐻', style: TextStyle(fontSize: 70))),
          const SizedBox(height: 14),
          const Text('FAZBEAR\nARCHIVES', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2.5, height: 1.0)),
          const SizedBox(height: 12),
          const Text('HISTORIA · LORE · COMUNIDAD · TIENDA', textAlign: TextAlign.center,
            style: TextStyle(color: gold, fontSize: 11, letterSpacing: 1.6)),
          const SizedBox(height: 35),
          Text(registering ? 'Crea tu cuenta' : 'Bienvenido de nuevo',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
          const SizedBox(height: 16),
          if (registering) ...[
            TextFormField(controller: username, decoration: const InputDecoration(labelText: 'Nombre de usuario', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v == null || !RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(v.trim()) ? 'Usa 3-30 letras, números o _' : null),
            const SizedBox(height: 12),
          ],
          TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.alternate_email)),
            validator: (v) => v == null || !v.contains('@') || !v.contains('.') ? 'Correo no válido' : null),
          const SizedBox(height: 12),
          TextFormField(controller: password, obscureText: !showPass,
            decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(icon: Icon(showPass ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => showPass = !showPass))),
            validator: (v) => v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
          const SizedBox(height: 22),
          FilledButton(onPressed: busy ? null : submit,
            child: busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(registering ? 'Registrarme' : 'Iniciar sesión')),
          TextButton(onPressed: busy ? null : () => setState(() { registering = !registering; error = null; }),
            child: Text(registering ? '¿Ya tienes cuenta? Iniciar sesión' : '¿No tienes cuenta? Regístrate')),
          const SizedBox(height: 18),
          const Text('Proyecto escolar hecho por fans. No afiliado a la franquicia FNAF.',
            textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11)),
        ]),
      )),
    ))),
  );
}
