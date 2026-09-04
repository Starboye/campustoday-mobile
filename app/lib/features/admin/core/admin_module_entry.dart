import 'package:flutter/material.dart';

class AdminModuleEntry {
  const AdminModuleEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.permission,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String permission;
  final String route;
}
