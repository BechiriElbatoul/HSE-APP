import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SerrefilListPage extends StatefulWidget {
  const SerrefilListPage({Key? key}) : super(key: key);

  @override
  _SerrefilListPageState createState() => _SerrefilListPageState();
}

class _SerrefilListPageState extends State<SerrefilListPage> {
  List<dynamic> serrefils = [];
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchSerrefils();
  }

  Future<void> fetchSerrefils() async {
    try {
      final token = await storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/employee/api/serrefils/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Fetch Serrefils Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> serrefils = json.decode(response.body);
        print('Number of serrefils: ${serrefils.length}');
        setState(() {
          this.serrefils = serrefils;
        });
      } else {
        throw Exception('Failed to load serrefils: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching serrefils: $e');
      // Handle error appropriately
    }
  }

  Future<void> deleteSerrefil(int serrefilId) async {
    try {
      print('Deleting serrefil with ID: $serrefilId');
      final token = await storage.read(key: 'auth_token');
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/employee/api/serrefils/$serrefilId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('Delete Response Status Code: ${response.statusCode}');
      if (response.statusCode == 204) {
        fetchSerrefils();
      } else {
        print('Delete failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to delete serrefil');
      }
    } catch (e) {
      print('Exception occurred while deleting serrefil: $e');
    }
  }

  void navigateToDeleteSerrefilPage(int serrefilId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeleteSerrefilPage(serrefilId: serrefilId),
      ),
    );

    if (result == true) {
      fetchSerrefils();
    }
  }

  void navigateToAddSerrefilPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSerrefilPage()),
    );

    if (result == true) {
      fetchSerrefils();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Number of serrefils: ${serrefils.length}');
    if (serrefils.isNotEmpty) {
      print('First serrefil: ${serrefils.first}');
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serrefil List'),
        backgroundColor: Color(0xFF009999),
      ),
      body: ListView.builder(
        itemCount: serrefils.length,
        itemBuilder: (context, index) {
          final serrefil = serrefils[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            child: ListTile(
              title: Text(
                '${serrefil['utilisateur']['nom']} ${serrefil['utilisateur']['prenom']}',
                style: TextStyle(color: const Color(0xFF06888a)),
              ),
              subtitle: Text(
                serrefil['utilisateur']['email'],
                style: TextStyle(color: const Color(0xFF06888a)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditSerrefilPage(serrefil: serrefil),
                        ),
                      ).then((result) {
                        if (result == true) {
                          fetchSerrefils(); // Refresh guide list after editing
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Deletion'),
                            content: const Text(
                                'Are you sure you want to delete this serrefil?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  final serrefilId = serrefil['id'];
                                  if (serrefilId != null) {
                                    deleteSerrefil(serrefilId);
                                  } else {
                                    print('serrefil ID is null');
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddSerrefilPage,
        backgroundColor: Color(0xFF00BEDC),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DeleteSerrefilPage extends StatelessWidget {
  final int serrefilId;

  const DeleteSerrefilPage({Key? key, required this.serrefilId});

  Future<void> fetchSerrefils() async {
    // Implement the logic to fetch serrefils
  }

  Future<void> deleteSerrefil(int serrefilId) async {
    final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/employee/api/serrefils/$serrefilId/'));

    if (response.statusCode == 204) {
      // Return void if the deletion is successful
      return;
    } else {
      throw Exception('Failed to delete serrefil');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Serrefil'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await deleteSerrefil(serrefilId);
              Navigator.pop(context, true);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to delete serrefil')),
              );
            }
          },
          child: const Text('Delete Serrefil'),
        ),
      ),
    );
  }
}

class AddSerrefilPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController etageController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = FlutterSecureStorage();

  Future<void> addSerrefil(BuildContext context) async {
    try {
      final token = await storage.read(key: 'auth_token');
      final url = Uri.parse('http://10.0.2.2:8000/employee/api/serrefils/');
      final body = json.encode({
        'utilisateur': {
          'nom': nomController.text,
          'prenom': prenomController.text,
          'email': emailController.text,
          'contact': contactController.text,
          'etage': int.parse(etageController.text),
          'password': passwordController.text,
        }
      });

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to add serrefil');
      }
    } catch (e) {
      print('Exception occurred while adding serrefil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add serrefil')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add serrefil'),
        backgroundColor: Color(0xFF009999),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter nom';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prenom',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter prenom';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter contact';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: etageController,
                    decoration: const InputDecoration(
                      labelText: 'Etage',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter etage';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    obscureText: true,
                    validator: (value) {
                      // Password can be empty if the user doesn't want to change it
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        addSerrefil(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF00BEDC), // Button color
                    ),
                    child: const Text('Add serrefil'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EditSerrefilPage extends StatelessWidget {
  final Map<String, dynamic> serrefil;

  EditSerrefilPage({Key? key, required this.serrefil});
  final storage = FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController etageController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    nomController.text = serrefil['utilisateur']['nom'];
    prenomController.text = serrefil['utilisateur']['prenom'];
    emailController.text = serrefil['utilisateur']['email'];
    contactController.text = serrefil['utilisateur']['contact'].toString();
    etageController.text = serrefil['etage'].toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit serrefil'),
        backgroundColor: Color(0xFF009999),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter nom';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prenom',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter prenom';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter contact';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: etageController,
                    decoration: const InputDecoration(
                      labelText: 'Etage',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter etage';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: const Color(0xFF06888a)),
                    ),
                    style: TextStyle(color: const Color(0xFF06888a)),
                    obscureText: true,
                    validator: (value) {
                      // Password can be empty if the user doesn't want to change it
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await editSerrefil();
                          Navigator.pop(context, true);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to edit serrefil'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF00BEDC), // Button color
                    ),
                    child: const Text('Edit serrefil'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> editSerrefil() async {
    try {
      final token = await storage.read(key: 'auth_token');
      final data = {
        'utilisateur': {
          'nom': nomController.text,
          'prenom': prenomController.text,
          'email': emailController.text,
          'contact': contactController.text,
          'etage':
              int.parse(etageController.text), // Ensure etage is sent correctly
        }
      };

      if (passwordController.text.isNotEmpty) {
        data['utilisateur']?['password'] = passwordController.text;
      }

      final response = await http.put(
        Uri.parse(
            'http://10.0.2.2:8000/employee/api/serrefils/${serrefil['id']}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to edit serrefil');
      }
    } catch (e) {
      print('Exception occurred while editing serrefil: $e');
      throw e; // Rethrow the exception to handle it at a higher level if needed
    }
  }
}
