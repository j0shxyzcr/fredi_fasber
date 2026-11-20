import 'package:flutter/material.dart';
import 'api.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FazbearArchivesApp());
}

class FazbearArchivesApp extends StatefulWidget {
  const FazbearArchivesApp({super.key});
  @override
  State<FazbearArchivesApp> createState() => _FazbearArchivesAppState();
}

class _FazbearArchivesAppState extends State<FazbearArchivesApp> {
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await Api.instance.init();
    final result = await Api.instance.whoAmI();
    if (mounted) setState(() { user = result; loading = false; });
  }

  Future<void> _logout() async {
    await Api.instance.logout();
    if (mounted) setState(() => user = null);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fazbear Archives', theme: makeTheme(), debugShowCheckedModeBanner: false,
    home: loading
      ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : user == null
        ? AuthScreen(onAuthenticated: (value) => setState(() => user = value))
        : MainShell(user: user!, onLogout: _logout),
  );
}
