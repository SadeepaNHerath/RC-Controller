class BleTxOption {
  const BleTxOption({
    required this.id,
    required this.serviceId,
    required this.label,
    required this.fast,
  });

  final String id;
  final String serviceId;
  final String label;
  final bool fast;
}
