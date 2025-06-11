import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/AttendanceService.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceCalendarPage extends StatefulWidget {
  const AttendanceCalendarPage({super.key});

  @override
  AttendanceCalendarPageState createState() => AttendanceCalendarPageState();
}

class AttendanceCalendarPageState extends State<AttendanceCalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final AttendanceService _attendanceService = AttendanceService();
  Map<DateTime, String> _attendanceMap = {}; // date -> 'Present'/'Absent'
  int _presentCount = 0;
  int _absentCount = 0;
  double _attendancePercentage = 0.0;
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Example static public holidays list
  final List<Map<String, String>> _publicHolidays = [
    {'date': '2025-01-26', 'name': "Republic Day"},
    {'date': '2025-03-29', 'name': "Holi"},
    {'date': '2025-04-18', 'name': "Good Friday"},
    {'date': '2025-05-23', 'name': "Founders' Day"},
    {'date': '2025-08-15', 'name': "Independence Day"},
    {'date': '2025-10-02', 'name': "Gandhi Jayanti"},
    {'date': '2025-12-25', 'name': "Christmas"},
  ];

  Set<DateTime> get _publicHolidayDates {
    return _publicHolidays.map((h) {
      final parts = h['date']!.split('-').map(int.parse).toList();
      return DateTime.utc(parts[0], parts[1], parts[2]);
    }).toSet();
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Replace with actual studentId (e.g., from auth)
      final studentId = 'STUDENT_ID_HERE';
      final records = await _attendanceService.getStudentAttendanceRecords(studentId);

      final Map<DateTime, String> attMap = {};
      int present = 0, absent = 0;
      for (var rec in records) {
        // Handle both string dates and Timestamp objects
        DateTime date;
        if (rec['date'] is String) {
          final dateParts = rec['date'].split('-').map(int.parse).toList();
          date = DateTime.utc(dateParts[0], dateParts[1], dateParts[2]);
        } else if (rec['date'] is Timestamp) {
          date = (rec['date'] as Timestamp).toDate();
        } else {
          print('Warning: Unknown date format: ${rec['date']}');
          continue;
        }
        
        attMap[date] = rec['present'] == true ? 'Present' : 'Absent';
        if (rec['present'] == true) present++;
        else absent++;
      }
      final total = present + absent;
      setState(() {
        _attendanceMap = attMap;
        _presentCount = present;
        _absentCount = absent;
        _attendancePercentage = total > 0 ? (present / total * 100) : 0.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (kDebugMode) print('Error fetching attendance: $e');
    }
  }

  Color _getStatusColor(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    if (_publicHolidayDates.contains(normalized)) return Colors.blue;
    final status = _attendanceMap[normalized];
    if (status == 'Present') return Colors.green;
    if (status == 'Absent') return Colors.red;
    return Colors.transparent;
  }

  Widget _buildSummaryItem(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Calendar'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Attendance', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Public Holidays', icon: Icon(Icons.flag)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Attendance Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSummaryItem('Present', _presentCount, Colors.green),
                                _buildSummaryItem('Absent', _absentCount, Colors.red),
                                _buildSummaryItem('Attendance %', _attendancePercentage.toStringAsFixed(1), Colors.blue),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) =>
                                  isSameDay(_selectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              },
                              calendarFormat: _calendarFormat,
                              onFormatChanged: (format) {
                                setState(() {
                                  _calendarFormat = format;
                                });
                              },
                              calendarStyle: const CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: Colors.orangeAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              headerStyle: HeaderStyle(
                                titleTextStyle: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                                formatButtonTextStyle: GoogleFonts.poppins(),
                                formatButtonVisible: true,
                                titleCentered: true,
                              ),
                              calendarBuilders: CalendarBuilders(
                                defaultBuilder: (context, date, _) {
                                  final color = _getStatusColor(date);
                                  return Container(
                                    margin: const EdgeInsets.all(6.0),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        color: color == Colors.transparent
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  );
                                },
                                selectedBuilder: (context, date, _) {
                                  return Container(
                                    margin: const EdgeInsets.all(6.0),
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${date.day}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const LegendRow(),
                        ],
                      ),
                    ),
                  ),
            // Public Holidays Tab
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Public Holidays',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _publicHolidays.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final holiday = _publicHolidays[index];
                        return ListTile(
                          leading: const Icon(Icons.flag, color: Colors.blue),
                          title: Text(holiday['name'] ?? ''),
                          subtitle: Text(holiday['date'] ?? ''),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegendRow extends StatelessWidget {
  const LegendRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        LegendItem(color: Colors.green, label: 'Present'),
        LegendItem(color: Colors.red, label: 'Absent'),
        LegendItem(color: Colors.blue, label: 'Holiday'),
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(),
        ),
      ],
    );
  }
}
