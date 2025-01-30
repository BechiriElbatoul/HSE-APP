import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_page.dart';

class PresenceIndicatorButton extends StatefulWidget {
  final int userId;
  final String userRole;
  final bool isAdmin;

  const PresenceIndicatorButton({
    super.key,
    required this.userId,
    required this.userRole,
    required this.isAdmin,
  });

  @override
  State<PresenceIndicatorButton> createState() =>
      _PresenceIndicatorButtonState();
}

class _PresenceIndicatorButtonState extends State<PresenceIndicatorButton> {
  bool _isPresent = false;
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _profileDetails;

  @override
  void initState() {
    super.initState();
    _fetchCurrentPresenceStatus();
    _fetchUserProfile();
  }

  Future<void> _fetchCurrentPresenceStatus() async {
    try {
      final String? token = await _storage.read(key: 'auth_token');
      final String url =
          'http://10.0.2.2:8000/employee/api/get_presence_status/${widget.userId}/';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _isPresent = data['status'] == true;
        });
      } else {
        print('Failed to fetch presence status');
      }
    } catch (error) {
      print('Error fetching presence status: $error');
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final String url =
          'http://10.0.2.2:8000/employee/api/profile/${widget.userId}/';

      final response = await http.get(Uri.parse(url));

      print(
          'User Profile API Response: ${response.body}'); // Print response for debugging

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _profileDetails = data;
        });
      } else {
        print('Failed to fetch user profile');
      }
    } catch (error) {
      print('Error fetching user profile: $error');
    }
  }

  void _togglePresence() {
    setState(() {
      _isPresent = !_isPresent;
    });

    _updatePresence(_isPresent, widget.userId);
  }

  void _updatePresence(bool isPresent, int userId) async {
    try {
      const String url = 'http://10.0.2.2:8000/employee/api/update_presence/';

      final Map<String, dynamic> body = {
        'user_id': userId,
        'status': isPresent,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Presence updated successfully');
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? errorMessage = responseData['error'];
        final String message = errorMessage ?? 'Failed to update presence.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print('Error updating presence: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'auth_token');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _viewProfileDetails() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _profileDetails != null
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xFF009999),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_profileDetails!['prenom']} ${_profileDetails!['nom']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF009999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _profileDetails!['role'],
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF00C1B6),
                        ),
                      ),
                      const Divider(color: Color(0xFF00BEDC), thickness: 1.5),
                      _buildProfileDetailRow(
                          Icons.email, _profileDetails!['email']),
                      _buildProfileDetailRow(
                          Icons.access_time, _profileDetails!['last_presence']),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Color(0xFF00C1B6)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF00C1B6)),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF009999)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF00C1B6),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Presence - ${widget.userRole}'),
        backgroundColor: const Color(0xFF009999),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _viewProfileDetails,
          ),
          if (widget.isAdmin) const Icon(Icons.admin_panel_settings),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _togglePresence,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isPresent ? const Color(0xFF00C1B6) : const Color(0xFF009999),
          ),
          child: Text(_isPresent ? '✅ Présent' : '🛑 Absent'),
        ),
      ),
    );
  }
}
