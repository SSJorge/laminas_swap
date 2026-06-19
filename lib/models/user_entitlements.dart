class UserEntitlements {
  const UserEntitlements({
    required this.adsRemoved,
    required this.premiumEnabled,
    required this.founderPlan,
  });

  final bool adsRemoved;
  final bool premiumEnabled;
  final String founderPlan;

  factory UserEntitlements.free() {
    return const UserEntitlements(
      adsRemoved: false,
      premiumEnabled: false,
      founderPlan: 'none',
    );
  }

  factory UserEntitlements.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return UserEntitlements.free();
    }

    return UserEntitlements(
      adsRemoved: data['adsRemoved'] == true,
      premiumEnabled: data['premiumEnabled'] == true,
      founderPlan: data['founderPlan'] is String
          ? data['founderPlan'] as String
          : 'none',
    );
  }

  bool get hasAnyPaidFeature => adsRemoved || premiumEnabled;

  bool get hasBundle => adsRemoved && premiumEnabled;

  String get planLabel {
    if (hasBundle) {
      return 'Pack fundador';
    }

    if (premiumEnabled) {
      return 'Premium';
    }

    if (adsRemoved) {
      return 'Sin anuncios';
    }

    return 'Gratis';
  }
}
