import 'service_category.dart';

enum ServiceUrgency {
  standard(label: 'Standard', description: 'Within 24–48 hours', surcharge: 0),
  sameDay(
    label: 'Same day',
    description: 'A professional visits today',
    surcharge: 50,
  ),
  emergency(
    label: 'Emergency',
    description: 'ASAP — extra fee applies',
    surcharge: 120,
  );

  const ServiceUrgency({
    required this.label,
    required this.description,
    required this.surcharge,
  });

  final String label;
  final String description;
  final double surcharge;
}

enum ServiceRequestStatus {
  pending(label: 'Pending', description: 'Finding you a professional'),
  assigned(label: 'Assigned', description: 'A professional has been assigned'),
  inProgress(label: 'In progress', description: 'Work is underway'),
  completed(label: 'Completed', description: 'Job finished and verified'),
  cancelled(label: 'Cancelled', description: 'This request was cancelled');

  const ServiceRequestStatus({required this.label, required this.description});

  final String label;
  final String description;

  bool get isOpen =>
      this == ServiceRequestStatus.pending ||
      this == ServiceRequestStatus.assigned ||
      this == ServiceRequestStatus.inProgress;
}

class ServiceProviderSummary {
  const ServiceProviderSummary({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    required this.reviews,
    required this.yearsExperience,
  });

  final String id;
  final String name;
  final String role;
  final double rating;
  final int reviews;
  final int yearsExperience;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class TimelineEvent {
  const TimelineEvent({
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final String title;
  final String subtitle;
  final DateTime time;
}

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.reference,
    required this.category,
    required this.issue,
    required this.description,
    required this.propertyId,
    required this.propertyLabel,
    required this.urgency,
    required this.preferredDate,
    required this.timeSlot,
    required this.status,
    required this.createdAt,
    this.provider,
    this.photoCount = 0,
    this.estimateLow,
    this.estimateHigh,
    this.finalAmount,
    this.timeline = const [],
  });

  final String id;
  final String reference;
  final ServiceCategory category;
  final String issue;
  final String description;
  final String propertyId;
  final String propertyLabel;
  final ServiceUrgency urgency;
  final DateTime preferredDate;
  final String timeSlot;
  final ServiceRequestStatus status;
  final DateTime createdAt;
  final ServiceProviderSummary? provider;
  final int photoCount;
  final double? estimateLow;
  final double? estimateHigh;
  final double? finalAmount;
  final List<TimelineEvent> timeline;

  double get calloutFee => category.calloutFee + urgency.surcharge;

  ServiceRequest copyWith({
    ServiceRequestStatus? status,
    ServiceProviderSummary? provider,
    List<TimelineEvent>? timeline,
    double? finalAmount,
  }) => ServiceRequest(
    id: id,
    reference: reference,
    category: category,
    issue: issue,
    description: description,
    propertyId: propertyId,
    propertyLabel: propertyLabel,
    urgency: urgency,
    preferredDate: preferredDate,
    timeSlot: timeSlot,
    status: status ?? this.status,
    createdAt: createdAt,
    provider: provider ?? this.provider,
    photoCount: photoCount,
    estimateLow: estimateLow,
    estimateHigh: estimateHigh,
    finalAmount: finalAmount ?? this.finalAmount,
    timeline: timeline ?? this.timeline,
  );
}
