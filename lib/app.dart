import 'package:flutter/material.dart';

import 'auth_gate.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const seedGreen = Color(0xFF0B7A3B);

    return MaterialApp(
      title: 'Intercambio de Láminas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedGreen),
      ),
      home: const AuthGate(),
    );
  }
}
