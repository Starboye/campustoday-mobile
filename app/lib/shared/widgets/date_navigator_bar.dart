import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';

class DateNavigatorBar extends StatelessWidget {
  const DateNavigatorBar({
    super.key,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    this.labelFormat = 'EEE, d MMM yyyy',
  });

  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String labelFormat;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat(labelFormat).format(selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Text(
              dateLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(AppConstants.navyColor),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
