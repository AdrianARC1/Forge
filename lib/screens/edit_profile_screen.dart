import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../styles/global_styles.dart';
import './widgets/base_scaffold.dart';
import './widgets/app_bar_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _usernameController.text = appState.username ?? '';
    _profileImagePath = appState.profileImagePath;
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Editar Perfil', style: GlobalStyles.insideAppTitleStyle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlobalStyles.textColor),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Atrás',
        ),
        actions: [
          AppBarButton(
            text: 'Guardar',
            onPressed: _saveChanges,
            textColor: GlobalStyles.buttonTextStyle.color,
            backgroundColor: GlobalStyles.backgroundButtonsColor,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _changeProfileImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImagePath != null
                    ? FileImage(File(_profileImagePath!))
                    : const AssetImage('assets/default_profile.png') as ImageProvider,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Personaliza tu Perfil',
              style: GlobalStyles.orangeSubtitleStyle,
            ),
            const SizedBox(height: 20),

            // Sección Nombre de Usuario
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nombre de Usuario',
                    style: GlobalStyles.insideAppTitleStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: GlobalStyles.textColor),
                    decoration: const InputDecoration(
                      labelText: 'Nuevo nombre',
                      labelStyle: TextStyle(color: GlobalStyles.placeholderColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: GlobalStyles.focusedBorderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aquí puedes cambiar tu nombre de usuario.',
                    style: TextStyle(color: GlobalStyles.textColorWithOpacity, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sección Contraseña
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cambiar Contraseña',
                    style: GlobalStyles.insideAppTitleStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentPasswordController,
                    style: const TextStyle(color: GlobalStyles.textColor),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña Actual',
                      labelStyle: TextStyle(color: GlobalStyles.placeholderColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: GlobalStyles.focusedBorderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _newPasswordController,
                    style: const TextStyle(color: GlobalStyles.textColor),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva Contraseña',
                      labelStyle: TextStyle(color: GlobalStyles.placeholderColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: GlobalStyles.focusedBorderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confirmPasswordController,
                    style: const TextStyle(color: GlobalStyles.textColor),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña',
                      labelStyle: TextStyle(color: GlobalStyles.placeholderColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: GlobalStyles.focusedBorderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Introduce tu contraseña actual para confirmar el cambio.',
                    style: TextStyle(color: GlobalStyles.textColorWithOpacity, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _changeProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveChanges() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final newUsername = _usernameController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Actualizar nombre de usuario
    if (newUsername.isNotEmpty && newUsername != appState.username) {
      await appState.updateUsername(newUsername);
    }

    // Verificación para el cambio de contraseña
    if (newPassword.isNotEmpty || confirmPassword.isNotEmpty || currentPassword.isNotEmpty) {
      if (currentPassword.isEmpty) {
        toastification.show(
          context: context,
          title: const Text('Atención'),
          description: const Text('Debes ingresar tu contraseña actual para cambiarla.'),
          type: ToastificationType.warning,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter
        );
        return;
      }

      bool currentPassValid = await appState.validateCurrentPassword(currentPassword);
      if (!currentPassValid) {
        toastification.show(
          context: context,
          title: const Text('Error'),
          description: const Text('La contraseña actual no es correcta.'),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter
        );
        return;
      }

      if (newPassword.isEmpty || confirmPassword.isEmpty) {
        toastification.show(
          context: context,
          title: const Text('Atención'),
          description: const Text('Debes ingresar y confirmar la nueva contraseña.'),
          type: ToastificationType.warning,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter
        );
        return;
      }

      if (newPassword != confirmPassword) {
        toastification.show(
          context: context,
          title: const Text('Atención'),
          description: const Text('La nueva contraseña no coincide con la confirmación.'),
          type: ToastificationType.warning,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter
        );
        return;
      }

      if (newPassword.length < 6) {
        toastification.show(
          context: context,
          title: const Text('Atención'),
          description: const Text('La nueva contraseña debe tener al menos 6 caracteres.'),
          type: ToastificationType.warning,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter
        );
        return;
      }

      // Todo OK, actualizar la contraseña
      await appState.updatePassword(newPassword);
      toastification.show(
        context: context,
        title: const Text('Éxito'),
        description: const Text('Tu contraseña se ha actualizado correctamente.'),
        type: ToastificationType.success,
        autoCloseDuration: const Duration(seconds: 3),
        alignment: Alignment.bottomCenter
      );
    }

    Navigator.pop(context);
  }
}
