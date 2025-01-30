import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pie_chart/pie_chart.dart';

class MonthlyAttendanceReportPage extends StatefulWidget {
  const MonthlyAttendanceReportPage({super.key});

  @override
  _MonthlyAttendanceReportPageState createState() =>
      _MonthlyAttendanceReportPageState();
}

class _MonthlyAttendanceReportPageState
    extends State<MonthlyAttendanceReportPage> {
  List<Map<String, dynamic>> _statistics = [];
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchMonthlyAttendanceReport();
  }

  Future<void> _fetchMonthlyAttendanceReport() async {
    const String apiUrl =
        'http://10.0.2.2:8000/employee/api/monthly-attendance-report/';

    try {
      final token = await storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _statistics =
              List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        throw Exception('Failed to load statistics');
      }
    } catch (e) {
      print('Error fetching attendance report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Attendance Report'),
        backgroundColor: const Color(0xFF009999),
      ),
      body: _statistics.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _statistics.length,
              itemBuilder: (context, index) {
                final stat = _statistics[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Floor ${stat['etage']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF009999),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Attendance Rate: ${stat['attendance_rate'].toStringAsFixed(2)}%',
                            ),
                            Text(
                              'Total Days: ${stat['total_days']}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Total Present Days: ${stat['total_present_days']}',
                            ),
                            Text(
                              'User Count: ${stat['user_count']}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
