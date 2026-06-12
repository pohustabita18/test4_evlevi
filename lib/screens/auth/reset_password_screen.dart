import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_input.dart';

class ResetPasswordScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundalul general Baby Blue este preluat automat din main.dart
      appBar: AppBar(
        title: const Text('Resetare Parolă'),
        backgroundColor: const Color(
          0xFFD2E6FF,
        ), // 🔴 NOU: Asortat cu fundalul Baby Blue
        foregroundColor: const Color(0xFF0F172A), // Text titlu albastru închis
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment
              .stretch, // Forțăm elementele să se întindă frumos pe lățime
          children: [
            CustomInput(
              label: 'Introdu Email-ul',
              controller: _emailController,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_emailController.text.isNotEmpty) {
                  await _auth.resetPassword(_emailController.text.trim());

                  // Verificăm dacă ecranul este încă activ înainte de a afișa SnackBar sau Navigator.pop
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Link-ul de resetare a fost trimis pe email! ✉️',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Te rugăm să introduci o adresă de email validă.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(
                  0xFF0F172A,
                ), // Albastru închis premium
                foregroundColor: Colors.white, // Text alb
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    16,
                  ), // Margini fin rotunjite asortate
                ),
                elevation: 0,
              ),
              child: const Text(
                'Trimite Email de Resetare',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
