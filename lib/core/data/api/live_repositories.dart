import '../../models/models.dart';
import '../repositories.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'session_store.dart';

/// The GRID API's PascalCase enum strings (`Ecg`, `DataBundle`, `House`) for
/// the app's camelCase enum names, and back.
String _wire(Enum value) =>
    value.name[0].toUpperCase() + value.name.substring(1);

T _fromWire<T extends Enum>(List<T> values, Object? raw, T fallback) {
  final wanted = '$raw'.toLowerCase();
  for (final value in values) {
    if (value.name.toLowerCase() == wanted) return value;
  }
  return fallback;
}

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.parse(raw).toLocal() : null;

/// GHS money on the wire: `{ "amount": "100.00", "currency": "GHS" }`.
double? _money(Object? raw) =>
    raw is Map<String, dynamic> ? double.tryParse('${raw['amount']}') : null;

Map<String, String> _moneyJson(double amount) => {
  'amount': amount.toStringAsFixed(2),
  'currency': 'GHS',
};

class LiveAuthApi implements AuthApi {
  LiveAuthApi(this._client, this._sessions);

  final ApiClient _client;
  final SessionStore _sessions;

  @override
  AppUser? get currentUser {
    final user = _sessions.current?.user;
    return user == null ? null : AppUser.fromJson(user);
  }

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/auth/otp/request',
      body: {'phoneNumber': phoneNumber},
    );
    return OtpChallenge(
      phoneNumber: data['phoneNumber'] as String,
      resendAfterSeconds: (data['resendAfterSeconds'] as num?)?.toInt() ?? 60,
      developmentCode: data['developmentCode'] as String?,
    );
  }

  @override
  Future<AppUser> verifyOtp(String phoneNumber, String code) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/auth/otp/verify',
      body: {'phoneNumber': phoneNumber, 'code': code},
    );
    final session = Session.fromAuthResponse(data);
    await _sessions.save(session);
    return AppUser.fromJson(session.user);
  }

  @override
  Future<AppUser> refreshUser() async =>
      _remember(await _client.get<Map<String, dynamic>>('/auth/me'));

  @override
  Future<AppUser> updateProfile({
    required String firstName,
    String? lastName,
    String? email,
  }) async => _remember(
    await _client.put<Map<String, dynamic>>(
      '/consumers/me',
      body: {'firstName': firstName, 'lastName': lastName, 'email': email},
    ),
  );

  /// Keeps the cached user current so the next launch opens with it.
  Future<AppUser> _remember(Map<String, dynamic> user) async {
    final session = _sessions.current;
    if (session != null) {
      await _sessions.save(session.copyWith(user: {...session.user, ...user}));
    }
    return AppUser.fromJson(user);
  }

  @override
  Future<void> signOut() async {
    final session = await _sessions.load();
    if (session != null) {
      try {
        await _client.post<void>(
          '/auth/logout',
          body: {'refreshToken': session.refreshToken},
        );
      } on Object {
        // Signing out locally must succeed even when the server cannot be reached.
      }
    }
    await _sessions.clear();
  }
}

class LivePropertiesApi implements PropertiesApi {
  LivePropertiesApi(this._client);

  final ApiClient _client;

  static Property _parse(Map<String, dynamic> json) => Property(
    id: json['id'] as String,
    nickname: json['nickname'] as String,
    area: json['area'] as String,
    city: json['city'] as String,
    address: json['address'] as String,
    kind: _fromWire(PropertyKind.values, json['kind'], PropertyKind.house),
    isPrimary: json['isPrimary'] as bool? ?? false,
    ghanaPostGps: json['ghanaPostGps'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  static Map<String, dynamic> _body(Property p) => {
    'nickname': p.nickname,
    'kind': _wire(p.kind),
    'area': p.area,
    'city': p.city,
    'address': p.address,
    'ghanaPostGps': p.ghanaPostGps,
    'latitude': p.latitude,
    'longitude': p.longitude,
  };

  @override
  Future<List<Property>> list() async {
    final data = await _client.get<List<dynamic>>('/properties');
    return [for (final row in data) _parse(row as Map<String, dynamic>)];
  }

  @override
  Future<Property> create(Property draft) async => _parse(
    await _client.post<Map<String, dynamic>>('/properties', body: _body(draft)),
  );

  @override
  Future<Property> update(Property property) async => _parse(
    await _client.put<Map<String, dynamic>>(
      '/properties/${property.id}',
      body: _body(property),
    ),
  );

  @override
  Future<void> archive(String id) => _client.delete<void>('/properties/$id');

  @override
  Future<void> makePrimary(String id) => _client.put<void>(
    '/consumers/me/default-property',
    body: {'propertyId': id},
  );
}

class LiveUtilityAccountsApi implements UtilityAccountsApi {
  LiveUtilityAccountsApi(this._client);

  final ApiClient _client;

  static UtilityAccount _parse(Map<String, dynamic> json) => UtilityAccount(
    id: json['id'] as String,
    type: _fromWire(UtilityType.values, json['type'], UtilityType.ecg),
    accountNumber: json['accountNumber'] as String,
    nickname: json['nickname'] as String,
    propertyId: json['propertyId'] as String?,
    isDefault: json['isDefault'] as bool? ?? false,
    lastPaidAt: _date(json['lastPaidAt']),
    lastAmount: (json['lastAmount'] as num?)?.toDouble(),
    dueDate: _date(json['dueDate']),
    network: json['network'] == null
        ? null
        : _fromWire(MobileNetwork.values, json['network'], MobileNetwork.mtn),
    ecgKind: json['ecgKind'] == null
        ? null
        : _fromWire(EcgKind.values, json['ecgKind'], EcgKind.prepaid),
  );

  static Map<String, dynamic> _body(UtilityAccount a) => {
    'type': _wire(a.type),
    'accountNumber': a.accountNumber,
    'nickname': a.nickname,
    'propertyId': a.propertyId,
    'isDefault': a.isDefault,
    // The server only accepts these on the utilities they apply to.
    if (a.type.isPhoneAccount && a.network != null)
      'network': _wire(a.network!),
    if (a.type == UtilityType.ecg && a.ecgKind != null)
      'ecgKind': _wire(a.ecgKind!),
  };

  @override
  Future<List<UtilityAccount>> list() async {
    final data = await _client.get<List<dynamic>>('/utility-accounts');
    return [for (final row in data) _parse(row as Map<String, dynamic>)];
  }

  @override
  Future<UtilityAccount> create(UtilityAccount draft) async => _parse(
    await _client.post<Map<String, dynamic>>(
      '/utility-accounts',
      body: _body(draft),
    ),
  );

  @override
  Future<UtilityAccount> update(UtilityAccount account) async => _parse(
    await _client.put<Map<String, dynamic>>(
      '/utility-accounts/${account.id}',
      body: _body(account),
    ),
  );

  @override
  Future<void> archive(String id) =>
      _client.delete<void>('/utility-accounts/$id');
}

class LiveBillPaymentsApi implements BillPaymentsApi {
  LiveBillPaymentsApi(this._client);

  final ApiClient _client;

  @override
  Future<BillLookup> lookup(BillTarget target) async {
    final Map<String, dynamic> data;
    try {
      data = await _client.post<Map<String, dynamic>>(
        '/bill-lookups',
        body: target.toJson(),
      );
    } on ApiException catch (error) {
      if (error.code == 'bills.meter_selection_required') {
        throw MeterSelectionRequired([
          for (final row in error.detailList.whereType<Map<String, dynamic>>())
            MeterChoice(
              meterNumber: row['meterNumber'] as String,
              customerName: row['customerName'] as String? ?? '',
              amountDue: _money(row['amountDue']),
            ),
        ]);
      }
      rethrow;
    }
    final rule = data['amountRule'] as Map<String, dynamic>? ?? const {};
    return BillLookup(
      productCode: data['productCode'] as String,
      accountNumber: data['accountNumber'] as String,
      customerName: data['customerName'] as String? ?? '',
      nameConfirmed: data['nameConfirmed'] as bool? ?? false,
      amountDue: _money(data['amountDue']),
      bundles: [
        for (final row
            in (data['bundles'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          BillBundle(
            value: row['value'] as String,
            label: row['label'] as String,
            amount: _money(row['amount']) ?? 0,
          ),
      ],
      minAmount: _money(rule['min']),
      maxAmount: _money(rule['max']),
      fixedPrice: rule['fixed'] as bool? ?? false,
      chargePercent: (data['chargePercent'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<BillOrder> placeOrder({
    required BillTarget target,
    required double amount,
    required String idempotencyKey,
    String? bundle,
    String? channel,
    String? savedAccountId,
    String? propertyId,
  }) async => _parse(
    await _client.post<Map<String, dynamic>>(
      '/orders',
      headers: {'Idempotency-Key': idempotencyKey},
      body: {
        ...target.toJson(),
        'amount': _moneyJson(amount),
        'bundle': ?bundle,
        'channel': ?channel,
        'savedAccountId': ?savedAccountId,
        'propertyId': ?propertyId,
      },
    ),
  );

  @override
  Future<BillOrder> order(String id) async =>
      _parse(await _client.get<Map<String, dynamic>>('/orders/$id'));

  @override
  Future<List<BillOrder>> history() async {
    final data = await _client.get<Map<String, dynamic>>(
      '/orders',
      query: {'limit': 50},
    );
    return [
      for (final row
          in (data['items'] as List<dynamic>).cast<Map<String, dynamic>>())
        _parse(row),
    ];
  }

  static BillOrder _parse(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>? ?? const {};
    final bill = json['bill'] as Map<String, dynamic>?;
    final refund = json['refund'] as Map<String, dynamic>?;
    final next = json['nextAction'] as Map<String, dynamic>?;
    return BillOrder(
      id: json['id'] as String,
      reference: json['reference'] as String,
      productCode: json['productCode'] as String,
      accountNumber: json['accountNumber'] as String,
      customerName: json['customerName'] as String? ?? '',
      principal: _money(json['principal']) ?? 0,
      fee: _money(json['fee']) ?? 0,
      total: _money(json['total']) ?? 0,
      status: _fromWire(
        BillOrderStatus.values,
        json['status'],
        BillOrderStatus.processing,
      ),
      needsReview: json['needsReview'] as bool? ?? false,
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      channel: payment['channel'] as String? ?? '',
      awaitingApproval: next?['kind'] == 'ApproveOnPhone',
      maskedPhone: (next?['maskedPhone'] ?? payment['maskedPhone']) as String?,
      charges: _money(payment['charges']),
      amountCharged: _money(payment['amountCharged']),
      paidAt: _date(payment['paidAt']),
      paymentError: payment['error'] as String?,
      billExternalReference: bill?['externalReference'] as String?,
      deliveredAt: _date(bill?['deliveredAt']),
      refundStatus: refund?['status'] as String?,
      refundAmount: _money(refund?['amount']),
      savedAccountId: json['savedAccountId'] as String?,
      propertyId: json['propertyId'] as String?,
    );
  }
}

class LiveServicesApi implements ServicesApi {
  LiveServicesApi(this._client);

  final ApiClient _client;

  @override
  Future<ServiceCatalogue> catalogue() async {
    final data = await _client.get<Map<String, dynamic>>('/service-catalogue');
    return ServiceCatalogue(
      sections: [
        for (final section
            in (data['sections'] as List<dynamic>).cast<Map<String, dynamic>>())
          ServiceSection(
            name: section['name'] as String,
            services: [
              for (final row
                  in (section['services'] as List<dynamic>)
                      .cast<Map<String, dynamic>>())
                _service(row, section['name'] as String),
            ],
          ),
      ],
    );
  }

  static ServiceItem _service(Map<String, dynamic> row, String section) =>
      ServiceItem(
        id: row['id'] as String,
        slug: row['slug'] as String,
        name: row['name'] as String,
        description: row['description'] as String? ?? '',
        section: section,
        bookingMode: _fromWire(
          BookingMode.values,
          row['bookingMode'],
          BookingMode.fixedPrice,
        ),
        fromPrice: (row['fromPrice'] as num?)?.toDouble() ?? 0,
        skills: [for (final s in (row['skills'] as List? ?? const [])) '$s'],
        packages: [
          for (final p
              in (row['packages'] as List<dynamic>? ?? const [])
                  .cast<Map<String, dynamic>>())
            ServicePackage(
              id: p['id'] as String,
              slug: p['slug'] as String,
              group: p['group'] as String,
              name: p['name'] as String,
              summary: p['summary'] as String?,
              includes: [
                for (final i in (p['includes'] as List? ?? const [])) '$i',
              ],
              excludes: [
                for (final i in (p['excludes'] as List? ?? const [])) '$i',
              ],
              price: (p['price'] as num).toDouble(),
              durationMinutes: (p['durationMinutes'] as num?)?.toInt() ?? 0,
              unitLabel: p['unitLabel'] as String?,
              maxQuantity: (p['maxQuantity'] as num?)?.toInt() ?? 1,
            ),
        ],
      );

  @override
  Future<ServiceAvailability> availability({
    required String serviceId,
    required String propertyId,
    required DateTime date,
  }) async {
    final day =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final data = await _client.get<Map<String, dynamic>>(
      '/service-requests/availability',
      query: {
        'serviceCategoryId': serviceId,
        'propertyId': propertyId,
        'date': day,
      },
    );
    return ServiceAvailability(
      served: data['served'] as bool? ?? false,
      area: data['area'] as String?,
      providersNearby: (data['providersNearby'] as num?)?.toInt() ?? 0,
      slots: [
        for (final slot
            in (data['slots'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          ServiceSlot(
            startsAt: _date(slot['startsAt'])!,
            available: slot['available'] as bool? ?? false,
          ),
      ],
    );
  }

  @override
  Future<ServiceRequest> book({
    required List<BookingLine> lines,
    required String propertyId,
    required DateTime scheduledAt,
    required String idempotencyKey,
    String? notes,
    List<String> items = const [],
    String? preferredProviderId,
  }) async => parseRequest(
    await _client.post<Map<String, dynamic>>(
      '/service-requests',
      headers: {'Idempotency-Key': idempotencyKey},
      body: {
        'lines': [
          for (final line in lines)
            {'packageId': line.package.id, 'quantity': line.quantity},
        ],
        'propertyId': propertyId,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'notes': ?notes,
        'items': items,
        'preferredProviderAccountId': ?preferredProviderId,
      },
    ),
  );

  @override
  Future<List<ServiceRequest>> requests() async => [
    for (final row in (await _client.get<List<dynamic>>(
      '/service-requests',
    )).cast<Map<String, dynamic>>())
      parseRequest(row),
  ];

  @override
  Future<ServiceRequest> request(String id) async => parseRequest(
    await _client.get<Map<String, dynamic>>('/service-requests/$id'),
  );

  @override
  Future<ServiceRequest> pay(String id) async => parseRequest(
    await _client.post<Map<String, dynamic>>('/service-requests/$id/pay'),
  );

  @override
  Future<ServiceRequest> cancel(String id, {String? reason}) async =>
      parseRequest(
        await _client.post<Map<String, dynamic>>(
          '/service-requests/$id/cancel',
          body: {'reason': ?reason},
        ),
      );

  @override
  Future<ServiceRequest> confirmCompletion(String id) async => parseRequest(
    await _client.post<Map<String, dynamic>>(
      '/service-requests/$id/confirm-completion',
    ),
  );

  @override
  Future<ServiceRequest> review(
    String id, {
    required int rating,
    String? comment,
  }) async => parseRequest(
    await _client.post<Map<String, dynamic>>(
      '/service-requests/$id/review',
      body: {'rating': rating, 'comment': ?comment},
    ),
  );

  static ServiceRequest parseRequest(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>?;
    final provider = json['provider'] as Map<String, dynamic>?;
    final review = json['review'] as Map<String, dynamic>?;
    return ServiceRequest(
      id: json['id'] as String,
      reference: json['reference'] as String,
      serviceSlug: json['serviceCategory'] as String,
      serviceName: json['serviceName'] as String? ?? '',
      bookingMode: _fromWire(
        BookingMode.values,
        json['bookingMode'],
        BookingMode.fixedPrice,
      ),
      title: json['title'] as String? ?? '',
      scope: json['scope'] as String?,
      lines: [
        for (final line
            in (json['lines'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          RequestLine(
            packageId: line['packageId'] as String,
            name: line['name'] as String,
            unitLabel: line['unitLabel'] as String?,
            unitPrice: (line['unitPrice'] as num).toDouble(),
            quantity: (line['quantity'] as num).toInt(),
            total: (line['total'] as num).toDouble(),
          ),
      ],
      total: (json['total'] as num?)?.toDouble() ?? 0,
      items: [for (final i in (json['items'] as List? ?? const [])) '$i'],
      notes: json['notes'] as String?,
      propertyId: json['propertyId'] as String?,
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      scheduledAt: _date(json['scheduledAt']) ?? DateTime.now(),
      status: _fromWire(
        ServiceRequestStatus.values,
        json['status'],
        ServiceRequestStatus.searching,
      ),
      payment: payment == null
          ? null
          : ServicePaymentInfo(
              status: _fromWire(
                ServicePaymentStatus.values,
                payment['status'],
                ServicePaymentStatus.awaitingApproval,
              ),
              amount: (payment['amount'] as num?)?.toDouble() ?? 0,
              channel: payment['channel'] as String? ?? '',
              payerPhone: payment['payerPhone'] as String? ?? '',
              error: payment['error'] as String?,
              paidAt: _date(payment['paidAt']),
              refundedAt: _date(payment['refundedAt']),
            ),
      jobCode: json['jobCode'] as String?,
      jobStage: json['jobStage'] as String?,
      provider: provider == null
          ? null
          : AssignedProvider(
              id: provider['id'] as String,
              name: provider['displayName'] as String? ?? '',
              phone: provider['phoneNumber'] as String? ?? '',
              completedJobs: (provider['completedJobs'] as num?)?.toInt() ?? 0,
              rating: (provider['rating'] as num?)?.toDouble(),
              reviews: (provider['reviews'] as num?)?.toInt() ?? 0,
            ),
      review: review == null
          ? null
          : RequestReview(
              rating: (review['rating'] as num).toInt(),
              comment: review['comment'] as String?,
            ),
      canCancel: json['canCancel'] as bool? ?? false,
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
    );
  }
}
