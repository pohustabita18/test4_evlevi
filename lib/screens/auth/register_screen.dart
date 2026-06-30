import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_input.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Creator';
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _auth.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _selectedRole,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cont creat cu succes! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Eroare: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cont Nou'),
        backgroundColor: const Color(0xFFD2E6FF),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              CustomInput(
                label: 'Email',
                controller: _emailController,
                validator: (v) => v!.contains('@') ? null : 'Email invalid',
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Parolă',
                controller: _passwordController,
                isPassword: true,
                validator: (v) => v!.length >= 6 ? null : 'Minim 6 caractere',
              ),
              const SizedBox(height: 24),
              const Text(
                'Alege tipul de utilizator:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    items: ['Brand', 'Creator']
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                              role,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0F172A),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(
                          0xFF0F172A,
                        ), // Albastru închis premium
                        foregroundColor: Colors.white, // Text alb
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Înregistrare',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
