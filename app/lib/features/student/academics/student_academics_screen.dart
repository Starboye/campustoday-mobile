import 'package:flutter/material.dart';

import '../announcements/announcements_screen.dart';
import '../dashboard/student_dashboard_screen.dart';
import '../fees/fees_screen.dart';
import '../homework/homework_screen.dart';
import '../profile/student_profile_screen.dart';
import '../report/report_card_screen.dart';
import '../timetable/timetable_screen.dart';

class StudentAcademicsScreen extends StatelessWidget {
  const StudentAcademicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Timetable'),
              Tab(text: 'Fees'),
              Tab(text: 'Report'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                TimetableScreen(),
                FeesScreen(),
                ReportCardScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
