import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_page.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  _MaintenancePageState createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final List<Map<String, dynamic>> maintenances = [];
  List<int> etages = [];

  @override
  void initState() {
    super.initState();
    _fetchMaintenances();
    _fetchEtages();
  }

  Future<void> _fetchMaintenances() async {
    final response = await http
        .get(Uri.parse('http://10.0.2.2:8000/employee/api/maintenance/'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        maintenances.clear();
        maintenances.addAll(data
            .map((item) => {
                  'type': item['type'],
                  'date': DateTime.parse(item['date_de_maintenance']),
                  'etage': item['etage'],
                })
            .toList());
      });
    } else {
      // Handle error
    }
  }

  Future<void> _fetchEtages() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8000/employee/api/etages/'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        etages = data.map<int>((item) => item['id']).toList();
      });
    } else {
      // Handle error
    }
  }

  void _addMaintenance() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedDate = DateTime.now();
        String selectedType = 'Alarme';
        int selectedEtage = etages.isNotEmpty ? etages[0] : 1;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ajouter une maintenance',
                  style: TextStyle(color: Color(0xFF009999))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedType,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedType = newValue!;
                      });
                    },
                    items: <String>['Alarme', 'Extincteur']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style: const TextStyle(color: Color(0xFF00C1B6))),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<int>(
                    value: selectedEtage,
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedEtage = newValue!;
                      });
                    },
                    items: etages.map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('Etage $value',
                            style: const TextStyle(color: Color(0xFF00C1B6))),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Date de maintenance",
                      hintText: DateFormat('yyyy-MM-dd').format(selectedDate),
                      hintStyle: const TextStyle(color: Color(0xFF00BEDC)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final response = await http.post(
                      Uri.parse(
                          'http://10.0.2.2:8000/employee/api/maintenance/'),
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                      },
                      body: jsonEncode(<String, dynamic>{
                        'type': selectedType,
                        'date_de_maintenance':
                            DateFormat('yyyy-MM-dd').format(selectedDate),
                        'etage': selectedEtage,
                      }),
                    );

                    if (response.statusCode == 201) {
                      Navigator.of(context).pop();
                      _fetchMaintenances(); // Actualiser la liste après l'ajout
                    } else {
                      // Handle error
                    }
                  },
                  child: const Text('Ajouter',
                      style: TextStyle(color: Color(0xFF00C1B6))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token'); // Supprimer le jeton

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              const LoginPage()), // Rediriger vers la page de login
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Maintenances'),
        backgroundColor: const Color(0xFF009999),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                _logout(context), // Appel à la fonction de déconnexion
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: maintenances.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 5,
            child: ListTile(
              leading: const Icon(Icons.build, color: Color(0xFF00C1B6)),
              title: Text(
                maintenances[index]['type'],
                style: const TextStyle(
                    color: Color(0xFF009999), fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Etage ${maintenances[index]['etage']}',
                    style: const TextStyle(color: Color(0xFF00C1B6)),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd')
                        .format(maintenances[index]['date']),
                    style: const TextStyle(color: Color(0xFF00BEDC)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMaintenance,
        backgroundColor: const Color(0xFF00BEDC),
        child: const Icon(Icons.add),
      ),
    );
  }
}
