import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GuideListPage extends StatefulWidget {
  const GuideListPage({super.key});

  @override
  _GuideListPageState createState() => _GuideListPageState();
}

class _GuideListPageState extends State<GuideListPage> {
  List<dynamic> guides = [];
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchGuides();
  }

  Future<void> fetchGuides() async {
    try {
      final token = await storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/employee/api/guides/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Fetch Guides Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> guides = json.decode(response.body);
        print('Number of guides: ${guides.length}');
        setState(() {
          this.guides = guides;
        });
      } else {
        throw Exception('Failed to load guides: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching guides: $e');
      // Handle error appropriately
    }
  }

  Future<void> deleteGuide(int guideId) async {
    try {
      print('Deleting guide with ID: $guideId');
      final token = await storage.read(key: 'auth_token');
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/employee/api/guides/$guideId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('Delete Response Status Code: ${response.statusCode}');
      if (response.statusCode == 204) {
        fetchGuides();
      } else {
        print('Delete failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to delete guide');
      }
    } catch (e) {
      print('Exception occurred while deleting guide: $e');
    }
  }

  void navigateToDeleteGuidePage(int guideId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeleteGuidePage(guideId: guideId),
      ),
    );

    if (result == true) {
      fetchGuides();
    }
  }

  void navigateToAddGuidePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddGuidePage()),
    );

    if (result == true) {
      fetchGuides();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Number of guides: ${guides.length}');
    if (guides.isNotEmpty) {
      print('First guide: ${guides.first}');
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide List'),
        backgroundColor: const Color(0xFF009999),
      ),
      body: ListView.builder(
        itemCount: guides.length,
        itemBuilder: (context, index) {
          final guide = guides[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            child: ListTile(
              title: Text(
                '${guide['utilisateur']['nom']} ${guide['utilisateur']['prenom']}',
                style: const TextStyle(color: Color(0xFF06888a)),
              ),
              subtitle: Text(
                guide['utilisateur']['email'],
                style: const TextStyle(color: Color(0xFF06888a)),
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
                          builder: (context) => EditGuidePage(guide: guide),
                        ),
                      ).then((result) {
                        if (result == true) {
                          fetchGuides(); // Refresh guide list after editing
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
                                'Are you sure you want to delete this guide?'),
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
                                  final guideId = guide['id'];
                                  if (guideId != null) {
                                    deleteGuide(guideId);
                                  } else {
                                    print('Guide ID is null');
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
        onPressed: navigateToAddGuidePage,
        backgroundColor: const Color(0xFF00BEDC),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DeleteGuidePage extends StatelessWidget {
  final int guideId;

  const DeleteGuidePage({super.key, Key? key, required this.guideId});

  Future<void> deleteGuide(int guideId) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/employee/api/guides/$guideId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        // Return void if the deletion is successful
        return;
      } else {
        throw Exception('Failed to delete guide');
      }
    } catch (e) {
      print('Exception occurred while deleting guide: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Guide'),
        backgroundColor: const Color(0xFF009999),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await deleteGuide(guideId);
              Navigator.pop(context, true);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to delete guide')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF00BEDC), // Text color
          ),
          child: const Text('Delete Guide'),
        ),
      ),
    );
  }
}

class AddGuidePage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController etageController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();

  AddGuidePage({super.key});

  Future<void> addGuide(BuildContext context) async {
    try {
      final token = await storage.read(key: 'auth_token');
      final url = Uri.parse('http://10.0.2.2:8000/employee/api/guides/');
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
        Navigator.pop(context, true); // Navigate back with success flag
      } else {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to add guide');
      }
    } catch (e) {
      print('Exception occurred while adding guide: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add guide')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Guide'),
        backgroundColor: const Color(0xFF009999),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                        addGuide(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF00BEDC), // Button color
                    ),
                    child: const Text('Add Guide'),
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

class EditGuidePage extends StatelessWidget {
  final Map<String, dynamic> guide;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController etageController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();

  EditGuidePage({super.key, Key? key, required this.guide});

  @override
  Widget build(BuildContext context) {
    nomController.text = guide['utilisateur']['nom'];
    prenomController.text = guide['utilisateur']['prenom'];
    emailController.text = guide['utilisateur']['email'];
    contactController.text = guide['utilisateur']['contact'].toString();
    etageController.text = guide['etage'].toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Guide'),
        backgroundColor: const Color(0xFF009999),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                      labelStyle: TextStyle(color: Color(0xFF06888a)),
                    ),
                    style: const TextStyle(color: Color(0xFF06888a)),
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
                          await editGuide();
                          Navigator.pop(context, true);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to edit guide'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF00BEDC), // Button color
                    ),
                    child: const Text('Edit Guide'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> editGuide() async {
    try {
      final token = await storage.read(key: 'auth_token');
      final data = {
        'utilisateur': {
          'nom': nomController.text,
          'prenom': prenomController.text,
          'email': emailController.text,
          'contact': contactController.text,
          'etage': int.parse(etageController.text),
        }
      };

      if (passwordController.text.isNotEmpty) {
        data['utilisateur']?['password'] = passwordController.text;
      }

      final response = await http.put(
        Uri.parse('http://10.0.2.2:8000/employee/api/guides/${guide['id']}/'),
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
        throw Exception('Failed to edit guide');
      }
    } catch (e) {
      print('Exception occurred while editing guide: $e');
      rethrow;
    }
  }
}
