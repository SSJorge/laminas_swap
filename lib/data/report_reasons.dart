class ReportReasonDefinition {
  const ReportReasonDefinition({required this.value, required this.label});

  final String value;
  final String label;
}

const reportReasons = <ReportReasonDefinition>[
  ReportReasonDefinition(
    value: 'inappropriate_contact',
    label: 'Contacto inapropiado',
  ),
  ReportReasonDefinition(value: 'scam', label: 'Estafa'),
  ReportReasonDefinition(value: 'spam', label: 'Spam'),
  ReportReasonDefinition(value: 'fake_profile', label: 'Perfil falso'),
  ReportReasonDefinition(value: 'other', label: 'Otro'),
];

bool isValidReportReason(String value) {
  return reportReasons.any((reason) => reason.value == value);
}
