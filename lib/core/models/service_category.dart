import 'package:flutter/material.dart';

/// Home-service categories GRID can dispatch trusted professionals for.
enum ServiceCategory {
  plumbing(
    label: 'Plumbing',
    description: 'Leaks, pipes, fittings and drainage',
    icon: Icons.plumbing_rounded,
    calloutFee: 100,
    issues: [
      'Leaking pipe or joint',
      'Blocked drain or sink',
      'Toilet not flushing',
      'Low water pressure',
      'New installation',
    ],
  ),
  electrical(
    label: 'Electrical',
    description: 'Wiring, sockets, fixtures and faults',
    icon: Icons.electrical_services_rounded,
    calloutFee: 100,
    issues: [
      'Power outage in part of the home',
      'Faulty socket or switch',
      'Tripping breaker',
      'Light fixture installation',
      'Wiring inspection',
    ],
  ),
  acRepair(
    label: 'AC Repair & Servicing',
    description: 'Servicing, gas refill and full repairs',
    icon: Icons.ac_unit_rounded,
    calloutFee: 120,
    issues: [
      'AC not cooling',
      'Routine servicing',
      'Gas refill',
      'Water dripping from unit',
      'New AC installation',
    ],
  ),
  applianceRepair(
    label: 'Appliance Repair',
    description: 'Fridges, washers, microwaves and more',
    icon: Icons.kitchen_rounded,
    calloutFee: 100,
    issues: [
      'Fridge or freezer fault',
      'Washing machine fault',
      'Microwave or oven fault',
      'TV fault',
      'Other appliance',
    ],
  ),
  cleaning(
    label: 'Cleaning',
    description: 'Deep cleaning, move-in/out and regular upkeep',
    icon: Icons.cleaning_services_rounded,
    calloutFee: 0,
    issues: [
      'Deep cleaning',
      'Move-in / move-out cleaning',
      'Regular home cleaning',
      'Post-construction cleaning',
      'Upholstery & carpet cleaning',
    ],
  ),
  powerBackup(
    label: 'Generator / Inverter / Solar',
    description: 'Backup power installation and support',
    icon: Icons.solar_power_rounded,
    calloutFee: 150,
    issues: [
      'Generator not starting',
      'Generator servicing',
      'Inverter or battery fault',
      'Solar panel servicing',
      'New solar installation quote',
    ],
  ),
  waterPump(
    label: 'Water Pump / Borehole',
    description: 'Pumps, tanks and borehole support',
    icon: Icons.water_rounded,
    calloutFee: 120,
    issues: [
      'Pump not working',
      'Tank not filling',
      'Borehole servicing',
      'New pump installation',
    ],
  ),
  security(
    label: 'CCTV / Security',
    description: 'Cameras, alarms and electric fencing',
    icon: Icons.videocam_rounded,
    calloutFee: 120,
    issues: [
      'CCTV installation',
      'Camera not recording',
      'Alarm system fault',
      'Electric fence servicing',
    ],
  ),
  handyman(
    label: 'General Handyman',
    description: 'Mounting, carpentry, painting, small fixes',
    icon: Icons.handyman_rounded,
    calloutFee: 80,
    issues: [
      'TV or shelf mounting',
      'Door or lock repair',
      'Furniture assembly',
      'Painting touch-up',
      'Other small fix',
    ],
  );

  const ServiceCategory({
    required this.label,
    required this.description,
    required this.icon,
    required this.calloutFee,
    required this.issues,
  });

  final String label;
  final String description;
  final IconData icon;

  /// Inspection / call-out fee in GHS. 0 means quoted after details.
  final double calloutFee;
  final List<String> issues;
}
