class BusinessProfile {
  const BusinessProfile({
    required this.businessName,
    required this.branchName,
    this.logoPath,
    this.email,
    this.phone,
    this.phoneCountryCode = '+20',
    this.commercialRegistration,
    this.city,
    this.region,
    this.country,
    this.postalCode,
    this.address,
  });

  final String businessName;
  final String branchName;
  final String? logoPath;

  /// Company-information fields surfaced in Settings → Company information.
  final String? email;
  final String? phone;
  final String phoneCountryCode;
  final String? commercialRegistration;
  final String? city;
  final String? region;
  final String? country;
  final String? postalCode;
  final String? address;

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
    String? email,
    String? phone,
    String? phoneCountryCode,
    String? commercialRegistration,
    String? city,
    String? region,
    String? country,
    String? postalCode,
    String? address,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      branchName: branchName ?? this.branchName,
      logoPath: logoPath ?? this.logoPath,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      commercialRegistration:
          commercialRegistration ?? this.commercialRegistration,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      address: address ?? this.address,
    );
  }
}
