// lib/screens/registration_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../onboarding/tutorial_screen.dart';
import '../widgets/shared_widgets.dart';
import '../../styles/global_styles.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();

  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    // Limpiar cualquier SnackBar existente cuando se inicializa la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _formKey.currentState?.reset(); // Reiniciar el formulario
      _usernameController.clear();
      _passwordController.clear();
      _repeatPasswordController.clear();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ocultar cualquier SnackBar existente cuando se reconstruye la RegistrationScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _formKey.currentState?.reset(); // Reiniciar el formulario
      _usernameController.clear();
      _passwordController.clear();
      _repeatPasswordController.clear();
    });

    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: GlobalStyles.backgroundColor,
      appBar: AppBar(
        title: Text('Registrarse'),
        backgroundColor: GlobalStyles.backgroundColor,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // Para evitar overflow en pantallas pequeñas
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset(
                    'assets/icon/icon.png', // Reemplaza con la ruta de tu logo
                    height: 100,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Crea tu Cuenta',
                    style: GlobalStyles.titleStyle,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Organiza tus rutinas diarias, semanales o mensuales',
                    textAlign: TextAlign.center,
                    style: GlobalStyles.subtitleStyle,
                  ),
                  SizedBox(height: 40),
                  SharedWidgets.buildTextFormField(
                    controller: _usernameController,
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person, color: GlobalStyles.placeholderColor),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa tu usuario.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  SharedWidgets.buildTextFormField(
                    controller: _passwordController,
                    labelText: 'Contraseña',
                    obscureText: true,
                    prefixIcon: Icon(Icons.lock, color: GlobalStyles.placeholderColor),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa tu contraseña.';
                      }
                      if (value.trim().length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  SharedWidgets.buildTextFormField(
                    controller: _repeatPasswordController,
                    labelText: 'Repetir Contraseña',
                    obscureText: true,
                    prefixIcon: Icon(Icons.lock, color: GlobalStyles.placeholderColor),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, repite tu contraseña.';
                      }
                      if (value.trim() != _passwordController.text.trim()) {
                        return 'Las contraseñas no coinciden.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  SharedWidgets.buildPrimaryButton(
                    text: 'Registrarse',
                    isLoading: _isRegistering,
                    enabled: !_isRegistering,
                    onPressed: _isRegistering ? () {} : () async {
                      if (_formKey.currentState!.validate()) { // Validar el formulario
                        setState(() {
                          _isRegistering = true;
                        });

                        String username = _usernameController.text.trim();
                        String password = _passwordController.text.trim();

                        bool success = await appState.register(username, password);
                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => TutorialScreen()),
                          );
                        } else {
                          setState(() {
                            _isRegistering = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('El nombre de usuario ya existe o hubo un error.'),
                              backgroundColor: GlobalStyles.errorColor,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  SharedWidgets.buildLinkButton(
                    text: 'Volver al Iniciar Sesión',
                    enabled: !_isRegistering,
                    onPressed: !_isRegistering
                        ? () {
                            Navigator.pop(context);
                          }
                        : () {},
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
