class CompanyProfile {
  final int id;
  final String companyName;
  final String tagline;
  final String phone;
  final String email;
  final String facebookId;
  final String instagramId;
  final String address;
  final String logoPath;

  CompanyProfile({
    this.id = 1,
    this.companyName = 'ARHAM ENTERPRISE',
    this.tagline = 'INVISIBLE GRILL - Secure, Stylish & Invisible',
    this.phone = '+91 98765 43210',
    this.email = 'contact@arhamenterprise.com',
    this.facebookId = 'Arham Invisible Grill',
    this.instagramId = '@arham_enterprise',
    this.address = '',
    this.logoPath = 'assets/images/logo.png',
  });

  CompanyProfile copyWith({
    int? id,
    String? companyName,
    String? tagline,
    String? phone,
    String? email,
    String? facebookId,
    String? instagramId,
    String? address,
    String? logoPath,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      tagline: tagline ?? this.tagline,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      facebookId: facebookId ?? this.facebookId,
      instagramId: instagramId ?? this.instagramId,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'tagline': tagline,
      'phone': phone,
      'email': email,
      'facebook_id': facebookId,
      'instagram_id': instagramId,
      'address': address,
      'logo_path': logoPath,
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: map['id'] as int? ?? 1,
      companyName: map['company_name'] as String? ?? 'ARHAM ENTERPRISE',
      tagline: map['tagline'] as String? ?? 'INVISIBLE GRILL - Secure, Stylish & Invisible',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      facebookId: map['facebook_id'] as String? ?? '',
      instagramId: map['instagram_id'] as String? ?? '',
      address: map['address'] as String? ?? '',
      logoPath: map['logo_path'] as String? ?? 'assets/images/logo.png',
    );
  }
}
