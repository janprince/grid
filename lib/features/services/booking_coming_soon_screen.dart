import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

/// Shown in place of the booking flow until the API can take bookings.
class BookingComingSoonScreen extends StatelessWidget {
  const BookingComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Book a service',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: const SafeArea(
        child: EmptyState(
          icon: Icons.cleaning_services_rounded,
          title: 'Coming soon',
          message:
              'Booking a clean or a laundry pickup isn\'t open yet. '
              'You can already pay your bills in GRID.',
        ),
      ),
    );
  }
}
