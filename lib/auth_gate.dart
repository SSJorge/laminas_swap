import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/direct_match_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  String? _displayNameKeyFromUri() {
    final segments = Uri.base.pathSegments;

    if (segments.length < 2) {
      return null;
    }

    if (segments.first != 'u') {
      return null;
    }

    final key = Uri.decodeComponent(segments[1]).trim().toLowerCase();

    if (key.isEmpty) {
      return null;
    }

    return key;
  }

  @override
  Widget build(BuildContext context) {
    final displayNameKey = _displayNameKeyFromUri();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LandingScreen();
        }

        if (displayNameKey != null) {
          return DirectMatchScreen(displayNameKey: displayNameKey);
        }

        return const HomeScreen();
      },
    );
  }
}