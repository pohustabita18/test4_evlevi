import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_input.dart';

class ResetPasswordScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Resetare Parolă')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomInput(
              label: 'Introdu Email-ul',
              controller: _emailController,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_emailController.text.isNotEmpty) {
                  await _auth.resetPassword(_emailController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Link trimis pe email!')),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Trimite Email de Resetare'),
            ),
          ],
        ),
      ),
    );
  }
}
