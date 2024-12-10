import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../onboarding/intro_slides.dart';
import '../widgets/shared_widgets.dart';
import '../../styles/global_styles.dart';
import 'package:toastification/toastification.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>(); 
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
      _formKey.currentState?.reset(); 
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _formKey.currentState?.reset(); 
      _usernameController.clear();
      _passwordController.clear();
      _repeatPasswordController.clear();
    });

    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: GlobalStyles.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( 
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon/icon.png', 
                    height: 100,
                  ),
                  const SizedBox(height: 60),
                  const Text(
                    'FORGE',
                    style: GlobalStyles.titleStyle,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Organiza tus rutinas diarias\nsemanal o mensualmente',
                    textAlign: TextAlign.center,
                    style: GlobalStyles.subtitleStyle,
                  ),
                  const SizedBox(height: 40),
                  SharedWidgets.buildTextFormField(
                    controller: _usernameController,
                    labelText: 'Usuario',
                    prefixIcon: const Icon(Icons.person, color: GlobalStyles.placeholderColor),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa tu usuario.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SharedWidgets.buildTextFormField(
                    controller: _passwordController,
                    labelText: 'Contraseña',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock, color: GlobalStyles.placeholderColor),
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
                  const SizedBox(height: 16),
                  SharedWidgets.buildTextFormField(
                    controller: _repeatPasswordController,
                    labelText: 'Repetir Contraseña',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock, color: GlobalStyles.placeholderColor),
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
                  const SizedBox(height: 20),
                  SharedWidgets.buildPrimaryButton(
                    text: 'Registrarse',
                    isLoading: _isRegistering,
                    enabled: !_isRegistering,
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                    onPressed: _isRegistering ? () {} : () async {
                      if (_formKey.currentState!.validate()) { 
                        setState(() {
                          _isRegistering = true;
                        });

                        String username = _usernameController.text.trim();
                        String password = _passwordController.text.trim();

                        bool success = await appState.register(username, password);
                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const IntroSlides()),
                          );
                        } else {
                          setState(() {
                            _isRegistering = false;
                          });
                          toastification.show(
                            context: context,
                            title: const Text('Error'),
                            description: const Text('El nombre de usuario ya existe o hubo un error.'),
                            type: ToastificationType.error,
                            autoCloseDuration: const Duration(seconds: 3),
                            alignment: Alignment.bottomCenter
                          );
                        }
                      }
                    },
                  ),
                  SharedWidgets.buildLinkButton(
                    text: 'Iniciar Sesión',
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
