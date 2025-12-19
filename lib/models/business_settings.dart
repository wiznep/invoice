/// Business settings model for company information
class BusinessSettings {
  final String? businessName;
  final String? address;
  final String? email;
  final String? phone;
  final String? website;
  final String? taxNumber;
  final String currency;
  final String invoicePrefix;
  final String estimatePrefix;
  final int nextInvoiceNumber;
  final int nextEstimateNumber;
  final int defaultDueDays;
  final int defaultValidDays;

  BusinessSettings({
    this.businessName,
    this.address,
    this.email,
    this.phone,
    this.website,
    this.taxNumber,
    this.currency = 'USD',
    this.invoicePrefix = 'INV-',
    this.estimatePrefix = 'EST-',
    this.nextInvoiceNumber = 1,
    this.nextEstimateNumber = 1,
    this.defaultDueDays = 30,
    this.defaultValidDays = 30,
  });

  String get nextInvoiceNumberFormatted =>
      '$invoicePrefix${nextInvoiceNumber.toString().padLeft(5, '0')}';

  String get nextEstimateNumberFormatted =>
      '$estimatePrefix${nextEstimateNumber.toString().padLeft(5, '0')}';

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'address': address,
      'email': email,
      'phone': phone,
      'website': website,
      'taxNumber': taxNumber,
      'currency': currency,
      'invoicePrefix': invoicePrefix,
      'estimatePrefix': estimatePrefix,
      'nextInvoiceNumber': nextInvoiceNumber,
      'nextEstimateNumber': nextEstimateNumber,
      'defaultDueDays': defaultDueDays,
      'defaultValidDays': defaultValidDays,
    };
  }

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      businessName: map['businessName'] as String?,
      address: map['address'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      website: map['website'] as String?,
      taxNumber: map['taxNumber'] as String?,
      currency: map['currency'] as String? ?? 'USD',
      invoicePrefix: map['invoicePrefix'] as String? ?? 'INV-',
      estimatePrefix: map['estimatePrefix'] as String? ?? 'EST-',
      nextInvoiceNumber: map['nextInvoiceNumber'] as int? ?? 1,
      nextEstimateNumber: map['nextEstimateNumber'] as int? ?? 1,
      defaultDueDays: map['defaultDueDays'] as int? ?? 30,
      defaultValidDays: map['defaultValidDays'] as int? ?? 30,
    );
  }

  BusinessSettings copyWith({
    String? businessName,
    String? address,
    String? email,
    String? phone,
    String? website,
    String? taxNumber,
    String? currency,
    String? invoicePrefix,
    String? estimatePrefix,
    int? nextInvoiceNumber,
    int? nextEstimateNumber,
    int? defaultDueDays,
    int? defaultValidDays,
  }) {
    return BusinessSettings(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      taxNumber: taxNumber ?? this.taxNumber,
      currency: currency ?? this.currency,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      estimatePrefix: estimatePrefix ?? this.estimatePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      nextEstimateNumber: nextEstimateNumber ?? this.nextEstimateNumber,
      defaultDueDays: defaultDueDays ?? this.defaultDueDays,
      defaultValidDays: defaultValidDays ?? this.defaultValidDays,
    );
  }
}
