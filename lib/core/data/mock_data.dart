import '../models/models.dart';

/// Seed data for the demo. Dates are computed relative to `now` so labels
/// like "Due tomorrow" stay believable no matter when the app runs.
abstract final class MockData {
  static final DateTime _now = DateTime.now();

  static DateTime _daysAgo(int days, [int hour = 10, int minute = 30]) {
    final d = _now.subtract(Duration(days: days));
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  static DateTime _daysAhead(int days, [int hour = 9]) {
    final d = _now.add(Duration(days: days));
    return DateTime(d.year, d.month, d.day, hour);
  }

  static const AppUser user = AppUser(
    id: 'u1',
    name: 'Kwame Mensah',
    phone: '+233551234567',
    email: 'kwame.m@example.com',
  );

  static const List<Property> properties = [
    Property(
      id: 'p1',
      nickname: 'My Home',
      area: 'East Legon',
      city: 'Accra',
      address: '45 Mensah Wood Ave, East Legon',
      kind: PropertyKind.house,
      isPrimary: true,
    ),
    Property(
      id: 'p2',
      nickname: "Mum's House",
      area: 'Ahodwo',
      city: 'Kumasi',
      address: 'Plot 12, Ahodwo Daban Rd',
      kind: PropertyKind.house,
    ),
    Property(
      id: 'p3',
      nickname: 'Tenant Apartment',
      area: 'Spintex',
      city: 'Accra',
      address: 'Apt 4B, Palm Court, Spintex Rd',
      kind: PropertyKind.apartment,
    ),
  ];

  static final List<UtilityAccount> accounts = [
    UtilityAccount(
      id: 'a1',
      type: UtilityType.ecg,
      accountNumber: '14258901334',
      nickname: 'My Home Meter',
      propertyId: 'p1',
      isDefault: true,
      lastPaidAt: _daysAgo(6),
      lastAmount: 200,
    ),
    UtilityAccount(
      id: 'a2',
      type: UtilityType.ecg,
      accountNumber: '14202447761',
      nickname: "Mum's Meter",
      propertyId: 'p2',
      lastPaidAt: _daysAgo(21),
      lastAmount: 100,
    ),
    UtilityAccount(
      id: 'a3',
      type: UtilityType.water,
      accountNumber: '040218837',
      nickname: 'GWCL — My Home',
      propertyId: 'p1',
      isDefault: true,
      lastPaidAt: _daysAgo(14),
      dueDate: _daysAhead(5),
      lastAmount: 120.50,
    ),
    UtilityAccount(
      id: 'a4',
      type: UtilityType.dstv,
      accountNumber: '7024561890',
      nickname: 'DStv — Living Room',
      propertyId: 'p1',
      isDefault: true,
      lastPaidAt: _daysAgo(29),
      dueDate: _daysAhead(1),
      lastAmount: 590,
    ),
    UtilityAccount(
      id: 'a5',
      type: UtilityType.airtime,
      accountNumber: '0551234567',
      nickname: 'My MTN',
      isDefault: true,
      lastPaidAt: _daysAgo(2),
      lastAmount: 20,
    ),
    UtilityAccount(
      id: 'a6',
      type: UtilityType.dataBundle,
      accountNumber: '0244098812',
      nickname: "Mum's Phone",
      propertyId: 'p2',
      lastPaidAt: _daysAgo(9),
      lastAmount: 50,
    ),
    UtilityAccount(
      id: 'a7',
      type: UtilityType.internet,
      accountNumber: '88014522',
      nickname: 'Home Fibre',
      propertyId: 'p1',
      isDefault: true,
      lastPaidAt: _daysAgo(24),
      dueDate: _daysAhead(6),
      lastAmount: 499,
    ),
  ];

  static const List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: 'm1',
      kind: PaymentMethodKind.momo,
      label: 'MTN Mobile Money',
      maskedNumber: '•••• 4567',
      isDefault: true,
    ),
    PaymentMethod(
      id: 'm2',
      kind: PaymentMethodKind.card,
      label: 'Visa Debit',
      maskedNumber: '•••• 9876',
    ),
    PaymentMethod(
      id: 'm3',
      kind: PaymentMethodKind.card,
      label: 'Demo Declined Card',
      maskedNumber: '•••• 0000',
      alwaysFails: true,
    ),
  ];

  static const Map<UtilityType, List<UtilityPlan>> plans = {
    UtilityType.dstv: [
      UtilityPlan(
        id: 'dstv1',
        name: 'Padi',
        price: 79,
        description: '45+ channels • 1 month',
      ),
      UtilityPlan(
        id: 'dstv2',
        name: 'Access',
        price: 159,
        description: '95+ channels • 1 month',
      ),
      UtilityPlan(
        id: 'dstv3',
        name: 'Family',
        price: 320,
        description: '120+ channels • 1 month',
      ),
      UtilityPlan(
        id: 'dstv4',
        name: 'Compact',
        price: 590,
        description: '135+ channels incl. sport • 1 month',
      ),
      UtilityPlan(
        id: 'dstv5',
        name: 'Compact Plus',
        price: 940,
        description: '145+ channels • 1 month',
      ),
    ],
    UtilityType.gotv: [
      UtilityPlan(
        id: 'gotv1',
        name: 'Lite',
        price: 49,
        description: '30+ channels • 1 month',
      ),
      UtilityPlan(
        id: 'gotv2',
        name: 'Jinja',
        price: 99,
        description: '55+ channels • 1 month',
      ),
      UtilityPlan(
        id: 'gotv3',
        name: 'Jolli',
        price: 149,
        description: '70+ channels • 1 month',
      ),
      UtilityPlan(
        id: 'gotv4',
        name: 'Max',
        price: 219,
        description: '85+ channels • 1 month',
      ),
    ],
    UtilityType.startimes: [
      UtilityPlan(
        id: 'st1',
        name: 'Nova',
        price: 40,
        description: '40+ channels • 1 month',
      ),
      UtilityPlan(
        id: 'st2',
        name: 'Basic',
        price: 80,
        description: '60+ channels • 1 month',
      ),
      UtilityPlan(
        id: 'st3',
        name: 'Classic',
        price: 160,
        description: '85+ channels • 1 month',
      ),
    ],
    UtilityType.dataBundle: [
      UtilityPlan(
        id: 'd1',
        name: '1.2 GB',
        price: 10,
        description: 'No expiry',
      ),
      UtilityPlan(
        id: 'd2',
        name: '4.5 GB',
        price: 30,
        description: 'No expiry',
      ),
      UtilityPlan(
        id: 'd3',
        name: '9.6 GB',
        price: 50,
        description: 'No expiry',
      ),
      UtilityPlan(
        id: 'd4',
        name: '22 GB',
        price: 100,
        description: 'No expiry',
      ),
      UtilityPlan(
        id: 'd5',
        name: '46 GB',
        price: 200,
        description: 'No expiry',
      ),
    ],
    UtilityType.internet: [
      UtilityPlan(
        id: 'i1',
        name: 'Home 20 Mbps',
        price: 299,
        description: 'Unlimited • 30 days',
      ),
      UtilityPlan(
        id: 'i2',
        name: 'Home 50 Mbps',
        price: 499,
        description: 'Unlimited • 30 days',
      ),
      UtilityPlan(
        id: 'i3',
        name: 'Home 100 Mbps',
        price: 799,
        description: 'Unlimited • 30 days',
      ),
    ],
  };

  static final List<PaymentTransaction> transactions = [
    PaymentTransaction(
      id: 't1',
      reference: 'TXN-8842-KQ',
      type: UtilityType.ecg,
      accountNumber: '14258901334',
      accountNickname: 'My Home Meter',
      amount: 200,
      status: TransactionStatus.success,
      createdAt: _daysAgo(6, 14, 32),
      paymentMethodLabel: 'MTN Mobile Money',
      propertyId: 'p1',
      propertyLabel: 'My Home',
      token: '4592 1109 4482 9901 22',
    ),
    PaymentTransaction(
      id: 't2',
      reference: 'TXN-8811-MZ',
      type: UtilityType.water,
      accountNumber: '040218837',
      accountNickname: 'GWCL — My Home',
      amount: 120.50,
      status: TransactionStatus.success,
      createdAt: _daysAgo(14, 9, 12),
      paymentMethodLabel: 'MTN Mobile Money',
      propertyId: 'p1',
      propertyLabel: 'My Home',
    ),
    PaymentTransaction(
      id: 't3',
      reference: 'TXN-8796-AB',
      type: UtilityType.airtime,
      accountNumber: '0551234567',
      accountNickname: 'My MTN',
      amount: 20,
      status: TransactionStatus.success,
      createdAt: _daysAgo(2, 19, 45),
      paymentMethodLabel: 'MTN Mobile Money',
    ),
    PaymentTransaction(
      id: 't4',
      reference: 'TXN-8790-TV',
      type: UtilityType.dstv,
      accountNumber: '7024561890',
      accountNickname: 'DStv — Living Room',
      amount: 590,
      status: TransactionStatus.success,
      createdAt: _daysAgo(29, 11, 5),
      paymentMethodLabel: 'Visa Debit',
      propertyId: 'p1',
      propertyLabel: 'My Home',
      planName: 'Compact',
    ),
    PaymentTransaction(
      id: 't5',
      reference: 'TXN-8761-XX',
      type: UtilityType.ecg,
      accountNumber: '14202447761',
      accountNickname: "Mum's Meter",
      amount: 100,
      status: TransactionStatus.failed,
      createdAt: _daysAgo(21, 16, 20),
      paymentMethodLabel: 'Visa Debit',
      propertyId: 'p2',
      propertyLabel: "Mum's House",
      failureReason: 'Payment was declined by your bank.',
    ),
    PaymentTransaction(
      id: 't6',
      reference: 'TXN-8899-PN',
      type: UtilityType.internet,
      accountNumber: '88014522',
      accountNickname: 'Home Fibre',
      amount: 499,
      status: TransactionStatus.pending,
      createdAt: _daysAgo(0, 8, 5),
      paymentMethodLabel: 'MTN Mobile Money',
      propertyId: 'p1',
      propertyLabel: 'My Home',
      planName: 'Home 50 Mbps',
    ),
  ];

  static const ServiceProviderSummary providerKofi = ServiceProviderSummary(
    id: 'sp1',
    name: 'Efua Asante',
    role: 'Home cleaner',
    rating: 4.9,
    reviews: 124,
    yearsExperience: 8,
  );

  static const ServiceProviderSummary providerAma = ServiceProviderSummary(
    id: 'sp2',
    name: 'Abena Mensah',
    role: 'Cleaning team lead',
    rating: 4.8,
    reviews: 86,
    yearsExperience: 6,
  );

  static const ServiceProviderSummary providerYaw = ServiceProviderSummary(
    id: 'sp3',
    name: 'Yaw Darko',
    role: 'Laundry · Fresh Folds',
    rating: 4.7,
    reviews: 63,
    yearsExperience: 5,
  );

  static final List<ServiceRequest> serviceRequests = [
    ServiceRequest(
      id: 's1',
      reference: 'GJ-3312',
      category: ServiceCategory.cleaning,
      issue: 'Deep cleaning',
      description: 'Kitchen and both bathrooms need the most attention.',
      propertyId: 'p1',
      propertyLabel: 'My Home',
      urgency: ServiceUrgency.sameDay,
      preferredDate: _daysAhead(0, 10),
      timeSlot: '10:00 AM – 12:00 PM',
      status: ServiceRequestStatus.assigned,
      createdAt: _daysAgo(0, 8, 40),
      provider: providerKofi,
      estimateLow: 350,
      estimateHigh: 450,
      timeline: [
        TimelineEvent(
          title: 'Request submitted',
          subtitle: 'We received your cleaning request.',
          time: _daysAgo(0, 8, 40),
        ),
        TimelineEvent(
          title: 'Cleaner assigned',
          subtitle: 'Efua Asante is assigned to your request.',
          time: _daysAgo(0, 9, 10),
        ),
      ],
    ),
    ServiceRequest(
      id: 's2',
      reference: 'GJ-3308',
      category: ServiceCategory.laundry,
      issue: 'Wash & iron',
      description: 'Work shirts on hangers, please.',
      propertyId: 'p1',
      propertyLabel: 'My Home',
      urgency: ServiceUrgency.standard,
      preferredDate: _daysAhead(2, 13),
      timeSlot: '1:00 PM – 3:00 PM',
      status: ServiceRequestStatus.pending,
      createdAt: _daysAgo(1, 17, 25),
      timeline: [
        TimelineEvent(
          title: 'Request submitted',
          subtitle: 'We are finding a laundry near you.',
          time: _daysAgo(1, 17, 25),
        ),
      ],
    ),
    ServiceRequest(
      id: 's3',
      reference: 'GJ-3290',
      category: ServiceCategory.laundry,
      issue: 'Wash & fold',
      description: 'Two bags — towels and bedsheets.',
      propertyId: 'p3',
      propertyLabel: 'Tenant Apartment',
      urgency: ServiceUrgency.standard,
      preferredDate: _daysAgo(0, 15),
      timeSlot: '3:00 PM – 5:00 PM',
      status: ServiceRequestStatus.inProgress,
      createdAt: _daysAgo(2, 9, 0),
      provider: providerYaw,
      estimateLow: 120,
      estimateHigh: 140,
      timeline: [
        TimelineEvent(
          title: 'Request submitted',
          subtitle: 'We received your laundry request.',
          time: _daysAgo(2, 9, 0),
        ),
        TimelineEvent(
          title: 'Laundry assigned',
          subtitle: 'Yaw Darko will collect your items.',
          time: _daysAgo(2, 11, 30),
        ),
        TimelineEvent(
          title: 'Items picked up',
          subtitle: '2 bags collected from Tenant Apartment.',
          time: _daysAgo(0, 15, 5),
        ),
      ],
    ),
    ServiceRequest(
      id: 's4',
      reference: 'GJ-3244',
      category: ServiceCategory.cleaning,
      issue: 'Deep cleaning',
      description: 'Full deep clean ahead of family visit.',
      propertyId: 'p2',
      propertyLabel: "Mum's House",
      urgency: ServiceUrgency.standard,
      preferredDate: _daysAgo(12, 9),
      timeSlot: '9:00 AM – 12:00 PM',
      status: ServiceRequestStatus.completed,
      createdAt: _daysAgo(14, 12, 15),
      provider: providerAma,
      finalAmount: 450,
      timeline: [
        TimelineEvent(
          title: 'Request submitted',
          subtitle: 'We received your cleaning request.',
          time: _daysAgo(14, 12, 15),
        ),
        TimelineEvent(
          title: 'Team assigned',
          subtitle: 'A 3-person cleaning team was assigned.',
          time: _daysAgo(13, 10, 0),
        ),
        TimelineEvent(
          title: 'Cleaning started',
          subtitle: 'Team checked in on site.',
          time: _daysAgo(12, 9, 5),
        ),
        TimelineEvent(
          title: 'Job completed',
          subtitle: 'Deep clean finished and confirmed by you.',
          time: _daysAgo(12, 13, 40),
        ),
      ],
    ),
    ServiceRequest(
      id: 's5',
      reference: 'GJ-3199',
      category: ServiceCategory.laundry,
      issue: 'Dry cleaning',
      description: 'Two suits for a wedding.',
      propertyId: 'p1',
      propertyLabel: 'My Home',
      urgency: ServiceUrgency.standard,
      preferredDate: _daysAgo(20, 11),
      timeSlot: '10:00 AM – 12:00 PM',
      status: ServiceRequestStatus.cancelled,
      createdAt: _daysAgo(22, 18, 0),
      timeline: [
        TimelineEvent(
          title: 'Request submitted',
          subtitle: 'We received your laundry request.',
          time: _daysAgo(22, 18, 0),
        ),
        TimelineEvent(
          title: 'Request cancelled',
          subtitle: 'You cancelled this request.',
          time: _daysAgo(21, 8, 30),
        ),
      ],
    ),
  ];

  static final List<Reminder> reminders = [
    Reminder(
      id: 'r1',
      title: 'DStv expires tomorrow',
      subtitle: 'Compact • DStv — Living Room',
      dueDate: _daysAhead(1),
      severity: ReminderSeverity.urgent,
      utilityType: UtilityType.dstv,
      propertyId: 'p1',
      actionLabel: 'Renew now',
    ),
    Reminder(
      id: 'r2',
      title: 'Time for a deep clean',
      subtitle: 'Last one was 3 months ago',
      dueDate: _daysAhead(5),
      severity: ReminderSeverity.warning,
      serviceCategory: ServiceCategory.cleaning,
      propertyId: 'p1',
      actionLabel: 'Book service',
    ),
    Reminder(
      id: 'r3',
      title: 'Water bill due soon',
      subtitle: 'GWCL — My Home',
      dueDate: _daysAhead(5),
      severity: ReminderSeverity.info,
      utilityType: UtilityType.water,
      propertyId: 'p1',
      actionLabel: 'Pay bill',
    ),
  ];

  /// "Most requested" services shown on the Services hub.
  static const List<ServiceCategory> popularServices = [
    ServiceCategory.cleaning,
    ServiceCategory.laundry,
  ];
}
