import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_entitlements.dart';
import '../screens/plans_screen.dart';
import '../services/daily_quota_repository.dart';

class PlanStatusCard extends StatelessWidget {
  const PlanStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final repository = DailyQuotaRepository(FirebaseFirestore.instance);

    return StreamBuilder<UserEntitlements>(
      stream: repository.watchEntitlements(user.uid),
      builder: (context, snapshot) {
        final entitlements = snapshot.data ?? UserEntitlements.free();

        return Card(
          child: ListTile(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PlansScreen()));
            },
            leading: Icon(
              entitlements.hasAnyPaidFeature
                  ? Icons.workspace_premium
                  : Icons.lock_open,
            ),
            title: Text('Plan actual: ${entitlements.planLabel}'),
            subtitle: Text(_subtitleFor(entitlements)),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  String _subtitleFor(UserEntitlements entitlements) {
    if (entitlements.hasBundle) {
      return 'Sin anuncios y con funciones premium activas.';
    }

    if (entitlements.premiumEnabled) {
      return 'Funciones premium activas. Los anuncios siguen activos.';
    }

    if (entitlements.adsRemoved) {
      return 'Sin anuncios. Mantienes límites extendidos por no ver anuncios.';
    }

    return 'Gratis. Toca para ver planes y beneficios.';
  }
}
