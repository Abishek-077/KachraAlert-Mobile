// lib/features/dashboard/presentation/pages/schedule_screen.dart

import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDay = 0;

  final List<Map<String, dynamic>> schedules = [
    {
      'day': 'Monday',
      'date': '2024-01-15',
      'time': '10:30 AM',
      'type': 'General Waste',
      'status': 'upcoming',
    },
    {
      'day': 'Wednesday',
      'date': '2024-01-17',
      'time': '10:30 AM',
      'type': 'Recyclables',
      'status': 'upcoming',
    },
    {
      'day': 'Friday',
      'date': '2024-01-19',
      'time': '2:00 PM',
      'type': 'Organic Waste',
      'status': 'upcoming',
    },
    {
      'day': 'Saturday',
      'date': '2024-01-20',
      'time': '9:00 AM',
      'type': 'General Waste',
      'status': 'completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Collection Schedule',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar View
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'January 2024',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: 35,
                      itemBuilder: (context, index) {
                        final day = index - 5;
                        final isCurrentMonth = day > 0 && day <= 31;
                        final isSelected = _selectedDay == day;

                        return GestureDetector(
                          onTap: isCurrentMonth
                              ? () {
                                  setState(() {
                                    _selectedDay = day;
                                  });
                                }
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2DD4BF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrentMonth
                                    ? const Color(0xFFD1D5DB)
                                    : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isCurrentMonth ? day.toString() : '',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : isCurrentMonth
                                    ? const Color(0xFF111827)
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Upcoming Collections
              const Text(
                'Upcoming Collections',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  final isCompleted = schedule['status'] == 'completed';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.grey[100]
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? Colors.grey[300]!
                            : const Color(0xFF2DD4BF).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.grey[300]
                                : const Color(0xFF2DD4BF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.delete_rounded,
                            color: isCompleted
                                ? Colors.grey[600]
                                : Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schedule['day'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? Colors.grey[600]
                                      : const Color(0xFF111827),
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${schedule['time']} • ${schedule['type']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2DD4BF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Soon',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2DD4BF),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
