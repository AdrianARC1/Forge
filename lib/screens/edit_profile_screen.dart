// lib/screens/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../styles/global_styles.dart';
import './widgets/base_scaffold.dart';
import './widgets/app_bar_button.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
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
        title: Text('Editar Perfil', style: GlobalStyles.insideAppTitleStyle),
        leading: AppBarButton(
          text: 'Atrás',
          onPressed: () => Navigator.pop(context),
          textColor: GlobalStyles.textColor,
          backgroundColor: Colors.transparent,
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
      body: Column(
        children: [
          SizedBox(height: 20),
          GestureDetector(
            onTap: _changeProfileImage,
            child: CircleAvatar(
              radius: 40,
              backgroundImage: _profileImagePath != null
                  ? FileImage(File(_profileImagePath!))
                  : AssetImage('assets/default_profile.png') as ImageProvider,
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _usernameController,
            style: TextStyle(color: GlobalStyles.textColor),
            decoration: InputDecoration(
              labelText: 'Nombre de Usuario',
              labelStyle: TextStyle(color: GlobalStyles.placeholderColor),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: GlobalStyles.focusedBorderColor),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text('Aquí puedes cambiar tu nombre y foto de perfil.', style: TextStyle(color: GlobalStyles.textColorWithOpacity))
        ],
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

  void _saveChanges() {
    // Aquí iría la lógica para guardar los cambios en AppState
    // Por ahora, solo volvemos atrás
    Navigator.pop(context);
  }
}
