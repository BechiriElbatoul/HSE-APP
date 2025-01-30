import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PresenceStatistics extends StatefulWidget {
  const PresenceStatistics({super.key});

  @override
  _PresenceStatisticsState createState() => _PresenceStatisticsState();
}

class _PresenceStatisticsState extends State<PresenceStatistics> {
  Map<String, int> _statistics = {};
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    try {
      final token = await storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/employee/api/presence-statistics/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _statistics = Map<String, int>.from(json.decode(response.body));
        });
      } else {
        throw Exception('Failed to load statistics');
      }
    } catch (e) {
      print('Error fetching statistics: $e');
      // Handle error appropriately
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presence Statistics'),
        backgroundColor: const Color(
            0xFF009999), // Use the same color as SerreilfListPage and GuideListPage
      ),
      body: _statistics.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presence Statistics by Floor',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                      ),
                      itemCount: _statistics.length,
                      itemBuilder: (context, index) {
                        String etage = _statistics.keys.elementAt(index);
                        int count = _statistics.values.elementAt(index);

                        return Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Floor $etage',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(
                                        0xFF06888a), // Use the same color as SerreilfListPage and GuideListPage
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Count: $count',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
