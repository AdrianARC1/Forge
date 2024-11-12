// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import 'registration_screen.dart';
import '../navigation/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Iniciar Sesión')),
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
              _isLoggingIn
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _errorMessage = null;
                          _isLoggingIn = true;
                        });

                        String username = _usernameController.text.trim();
                        String password = _passwordController.text.trim();

                        // Validaciones
                        if (username.isEmpty || password.isEmpty) {
                          setState(() {
                            _errorMessage = 'Por favor, completa todos los campos.';
                            _isLoggingIn = false;
                          });
                          return;
                        }

                        bool success = await appState.login(username, password);
                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => MainNavigationScreen()),
                          );
                        } else {
                          setState(() {
                            _errorMessage = 'Usuario o contraseña incorrectos.';
                            _isLoggingIn = false;
                          });
                        }
                      },
                      child: Text('Iniciar Sesión'),
                    ),
              TextButton(
                onPressed: _isLoggingIn
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegistrationScreen()),
                        );
                      },
                child: Text('Registrarse'),
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
