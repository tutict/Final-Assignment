import 'package:flutter/material.dart';

class changePasswordPage extends StatefulWidget{
  const changePasswordPage({super.key});

  @override
  State<changePasswordPage> createState() => _changePasswordPageState();
}

class _changePasswordPageState extends State<changePasswordPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  bool _obscureText = true;
  bool _obscureTextNew = true;
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8.0),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _currentPasswordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureTextNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureTextNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureTextNew = !_obscureTextNew;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _confirmNewPasswordController,
                      obscureText: true, // Confirm new password is always obscured
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MaterialButton(
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                      child: const Text('Submit'),
                      onPressed: () {
                        if (_newPasswordController.text.isEmpty ||
                            _confirmNewPasswordController.text.isEmpty) {
                          setState(() {
                            _error = 'New password and confirm new password cannot be empty';
                          });
                          return;
                        }
                        if (_newPasswordController.text !=
                            _confirmNewPasswordController.text) {
                          setState(() {
                            _error = 'New password and confirm new password do not match';
                          });
                          return;
                        }
                        setState(() {
                          _error = ''; // Clear error message
                        });
                        // Show snackbar
                        if (_error.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated successfully!'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
