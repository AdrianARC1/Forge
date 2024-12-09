import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import 'registration_screen.dart';
import '../navigation/main_navigation_screen.dart';
import '../widgets/shared_widgets.dart';
import '../../styles/global_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    // Limpiar cualquier SnackBar existente cuando se inicializa la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _formKey.currentState?.reset();
      _usernameController.clear();
      _passwordController.clear();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SharedWidgets.buildPrimaryButton(
                    text: 'Acceder',
                    isLoading: _isLoggingIn,
                    enabled: !_isLoggingIn,
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                    onPressed: _isLoggingIn ? () {} : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isLoggingIn = true;
                        });

                        String username = _usernameController.text.trim();
                        String password = _passwordController.text.trim();

                        bool success = await appState.login(username, password);
                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                          );
                        } else {
                          setState(() {
                            _isLoggingIn = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuario o contraseña incorrectos.'),
                              backgroundColor: GlobalStyles.errorColor,
                              duration: Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  SharedWidgets.buildLinkButton(
                    text: 'Registrarse',
                    enabled: !_isLoggingIn,
                    onPressed: !_isLoggingIn
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                            );
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
