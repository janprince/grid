import 'service_catalogue.dart';

enum ServiceUrgency { standard, sameDay }

/// Where a booking is, as GRID reports it.
enum ServiceRequestStatus {
  awaitingPayment(label: 'Awaiting payment'),
  paymentFailed(label: 'Payment failed'),
  searching(label: 'Finding a professional'),
  assigned(label: 'Confirmed'),
  inProgress(label: 'In progress'),
  completed(label: 'Completed'),
  cancelled(label: 'Cancelled'),
  unfilled(label: 'No one available');

  const ServiceRequestStatus({required this.label});

  final String label;

  /// Still moving: worth checking on.
  bool get isOpen =>
      {awaitingPayment, searching, assigned, inProgress}.contains(this);
}

enum ServicePaymentStatus {
  awaitingApproval,
  paid,
  failed,
  refunding,
  refunded,
  refundFailed,
}

class ServicePaymentInfo {
  const ServicePaymentInfo({
    required this.status,
    required this.amount,
    required this.payerPhone,
    this.channel = '',
    this.error,
    this.paidAt,
    this.refundedAt,
  });

  final ServicePaymentStatus status;
  final double amount;
  final String channel;
  final String payerPhone;
  final String? error;
  final DateTime? paidAt;
  final DateTime? refundedAt;

  String get label => switch (status) {
    ServicePaymentStatus.awaitingApproval => 'Waiting for approval',
    ServicePaymentStatus.paid => 'Paid',
    ServicePaymentStatus.failed => 'Not paid',
    ServicePaymentStatus.refunding => 'Refund on its way',
    ServicePaymentStatus.refunded => 'Refunded',
    ServicePaymentStatus.refundFailed => 'Refund delayed',
  };
}

/// The professional GRID assigned, shared once they accept.
class AssignedProvider {
  const AssignedProvider({
    required this.id,
    required this.name,
    required this.phone,
    this.completedJobs = 0,
    this.rating,
    this.reviews = 0,
  });

  final String id;
  final String name;
  final String phone;
  final int completedJobs;
  final double? rating;
  final int reviews;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class RequestLine {
  const RequestLine({
    required this.packageId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.total,
    this.unitLabel,
  });

  final String packageId;
  final String name;
  final String? unitLabel;
  final double unitPrice;
  final int quantity;
  final double total;
}

class RequestReview {
  const RequestReview({required this.rating, this.comment});
  final int rating;
  final String? comment;
}

/// A booking: what, where, when, what it cost, and who is coming.
class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.reference,
    required this.serviceSlug,
    required this.serviceName,
    required this.title,
    required this.lines,
    required this.total,
    required this.area,
    required this.address,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
    this.bookingMode = BookingMode.fixedPrice,
    this.scope,
    this.items = const [],
    this.notes,
    this.propertyId,
    this.city = '',
    this.payment,
    this.jobCode,
    this.jobStage,
    this.provider,
    this.review,
    this.canCancel = false,
  });

  final String id;

  /// "GR-1042".
  final String reference;
  final String serviceSlug;
  final String serviceName;
  final BookingMode bookingMode;
  final String title;
  final String? scope;
  final List<RequestLine> lines;
  final double total;
  final List<String> items;
  final String? notes;
  final String? propertyId;
  final String area;
  final String city;
  final String address;
  final DateTime scheduledAt;
  final ServiceRequestStatus status;
  final ServicePaymentInfo? payment;
  final String? jobCode;

  /// camelCase stage from GRID, e.g. `onTheWay`, `awaitingConfirmation`.
  final String? jobStage;
  final AssignedProvider? provider;
  final RequestReview? review;
  final bool canCancel;
  final DateTime createdAt;

  bool get awaitingConfirmation => jobStage == 'awaitingConfirmation';

  bool get awaitingApproval =>
      status == ServiceRequestStatus.awaitingPayment &&
      payment?.status == ServicePaymentStatus.awaitingApproval;

  /// What the customer should read first, in plain words.
  String get headline => switch (status) {
    ServiceRequestStatus.awaitingPayment => 'Approve the payment on your phone',
    ServiceRequestStatus.paymentFailed => 'Your payment didn\'t go through',
    ServiceRequestStatus.searching => 'Finding you a professional',
    ServiceRequestStatus.assigned =>
      '${provider?.name ?? 'Your professional'} is booked',
    ServiceRequestStatus.inProgress =>
      awaitingConfirmation ? 'Is everything done?' : stageHeadline,
    ServiceRequestStatus.completed => 'Done',
    ServiceRequestStatus.cancelled => 'Booking cancelled',
    ServiceRequestStatus.unfilled => 'No one was available',
  };

  String get stageHeadline => switch (jobStage) {
    'onTheWay' => '${provider?.name ?? 'Your professional'} is on the way',
    'arrived' => '${provider?.name ?? 'Your professional'} has arrived',
    'inProgress' => 'Work in progress',
    'pickedUp' => 'Your laundry has been collected',
    'processing' => 'Washing',
    'readyForDelivery' => 'Your laundry is ready',
    'outForDelivery' => 'Your laundry is on its way back',
    _ => 'In progress',
  };
}

/// Hours someone nearby can come on one day.
class ServiceSlot {
  const ServiceSlot({required this.startsAt, required this.available});
  final DateTime startsAt;
  final bool available;
}

class ServiceAvailability {
  const ServiceAvailability({
    required this.served,
    this.area,
    this.providersNearby = 0,
    this.slots = const [],
  });

  final bool served;
  final String? area;
  final int providersNearby;
  final List<ServiceSlot> slots;
}
