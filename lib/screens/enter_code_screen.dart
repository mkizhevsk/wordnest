import 'package:flutter/material.dart';
import 'package:wordnest/services/auth_service.dart';
import 'package:wordnest/services/card_sync_service.dart';
import 'package:wordnest/main.dart';

class EnterCodeScreen extends StatefulWidget {
  final String username;

  const EnterCodeScreen({super.key, required this.username});

  @override
  _EnterCodeScreenState createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final CardSyncService cardSyncService = CardSyncService();

  void _submitCode() async {
    if (_formKey.currentState!.validate()) {
      final String code = _codeController.text;
      // Handle code submission logic here
      print('Submitted code: $code');
      // Example: Call an authentication service with the code

      int statusCode = await _authService.processCode(widget.username, code);
      if (statusCode == 200) {
        await cardSyncService.fetchAndSyncCards();
        print("here1");
        if (mounted) {
          // Navigate to MyHome screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  const MyHomePage(), // Ensure MyHome is imported
            ),
          );
        }
      } else if (statusCode == 498) {
        _showMessage("The verification code you entered is invalid");
      } else if (statusCode == 498) {
        _showMessage("The verification code has expired");
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red, // Optional: set a background color
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Verification Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Please enter the verification code sent to your email:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the verification code';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitCode,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
