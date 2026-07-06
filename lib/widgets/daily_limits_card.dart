import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/daily_limits.dart';
import '../services/daily_quota_repository.dart';

class DailyLimitsCard extends StatelessWidget {
  const DailyLimitsCard({
    super.key,
    required this.types,
  });

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Límites diarios',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estos límites se reinician cada día.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                for (final type in types) ...[
                  _DailyLimitRow(
                    type: type,
                    used: usage.used(type),
                    remaining: usage.remaining(type),
                    limit: usage.limit(type),
                  ),
                  if (type != types.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DailyLimitRow extends StatelessWidget {
  const _DailyLimitRow({
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
    final reachedLimit = remaining <= 0;

    return Row(
      children: [
        Expanded(
          child: Text(
            definition.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            reachedLimit
                ? 'Límite diario alcanzado ($used/$limit usados hoy)'
                : '$remaining disponibles hoy ($used/$limit usados hoy)',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}