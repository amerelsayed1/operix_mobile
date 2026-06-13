class BusinessProfile {
  const BusinessProfile({
    required this.businessName,
    required this.branchName,
    this.logoPath,
  });

  final String businessName;
  final String branchName;
  final String? logoPath;

  String get initials {
    final parts = businessName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'OP';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  BusinessProfile copyWith({
    String? businessName,
    String? branchName,
    String? logoPath,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      branchName: branchName ?? this.branchName,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}
