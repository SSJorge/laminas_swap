import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/daily_limits.dart';
import '../services/daily_quota_repository.dart';

class DailyLimitsCard extends StatelessWidget {
  const DailyLimitsCard({super.key, required this.types});

  final List<DailyLimitType> types;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final repository = DailyQuotaRepository(FirebaseFirestore.instance);

    return StreamBuilder<DailyUsage>(
      stream: repository.watchToday(user.uid),
      builder: (context, snapshot) {
        final usage = snapshot.data ?? DailyUsage.empty(todayUsageDocId());

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in types)
                  _LimitChip(
                    type: type,
                    used: usage.used(type),
                    remaining: usage.remaining(type),
                    limit: usage.limit(type),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LimitChip extends StatelessWidget {
  const _LimitChip({
    required this.type,
    required this.used,
    required this.remaining,
    required this.limit,
  });

  final DailyLimitType type;
  final int used;
  final int remaining;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final definition = dailyLimitDefinitionFor(type);

    return Chip(
      label: Text(
        '${definition.label}: $remaining restantes ($used/$limit usados)',
      ),
    );
  }
}
