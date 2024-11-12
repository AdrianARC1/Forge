// lib/screens/registration_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../onboarding/tutorial_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Registrarse')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Para evitar overflow en pantallas pequeñas
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 20),
              _isRegistering
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _errorMessage = null;
                          _isRegistering = true;
                        });

                        String username = _usernameController.text.trim();
                        String password = _passwordController.text.trim();

                        // Validaciones
                        if (username.isEmpty || password.isEmpty) {
                          setState(() {
                            _errorMessage = 'Por favor, completa todos los campos.';
                            _isRegistering = false;
                          });
                          return;
                        }

                        if (password.length < 6) {
                          setState(() {
                            _errorMessage = 'La contraseña debe tener al menos 6 caracteres.';
                            _isRegistering = false;
                          });
                          return;
                        }

                        bool success = await appState.register(username, password);
                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => TutorialScreen()),
                          );
                        } else {
                          setState(() {
                            _errorMessage = 'El nombre de usuario ya existe o hubo un error.';
                            _isRegistering = false;
                          });
                        }
                      },
                      child: Text('Registrarse'),
                    ),
              TextButton(
                onPressed: _isRegistering
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: Text('Volver al Iniciar Sesión'),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
