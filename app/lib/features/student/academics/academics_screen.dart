import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../fees/fees_screen.dart';
import '../report/report_screen.dart';
import '../timetable/timetable_screen.dart';

class AcademicsScreen extends StatelessWidget {
  const AcademicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              labelColor: const Color(AppConstants.primaryColor),
              unselectedLabelColor: const Color(AppConstants.navyColor),
              indicatorColor: const Color(AppConstants.primaryColor),
              tabs: const [
                Tab(text: 'Timetable'),
                Tab(text: 'Fees'),
                Tab(text: 'Report'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                TimetableScreen(),
                FeesScreen(),
                ReportScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
