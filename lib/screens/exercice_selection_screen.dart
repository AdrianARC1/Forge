// lib/screens/exercise_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../styles/global_styles.dart';
import 'widgets/base_scaffold.dart';
import 'widgets/app_bar_button.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({Key? key}) : super(key: key);

  @override
  _ExerciseSelectionScreenState createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  String searchQuery = "";
  String? selectedMuscleGroup;
  String? selectedEquipment;
  ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final String allMusclesOption = "Todos los músculos";
  final String allEquipmentOption = "Todos los equipamientos";

  late AppState appState; 
  bool _initialized = false;

  List<String> getMuscleGroups() {
    return [allMusclesOption, ...appState.muscleGroups];
  }

  List<String> getEquipment() {
    return [allEquipmentOption, ...appState.equipment];
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      appState = Provider.of<AppState>(context, listen: false);
      _initializeData();
    }
  }

  Future<void> _initializeData() async {
    // Espera a que se carguen ejercicios, grupos musculares y equipamientos
    await appState.fetchAllExercises();
    await appState.loadMuscleGroups();
    await appState.loadEquipment();

    setState(() {
      _initialized = true;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      appState.loadMoreExercises();
    }
  }

  void _filterExercises() {
    setState(() {
      _isLoading = true;
    });

    appState.filterExercises(searchQuery.isNotEmpty ? searchQuery : '');
    appState.applyFilters(
      muscleGroup: selectedMuscleGroup,
      equipment: selectedEquipment,
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    appState.applyFilters(muscleGroup: null, equipment: null);
    appState.filterExercises('');
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onMuscleGroupChanged(String? value) {
    setState(() {
      if (value == allMusclesOption) {
        selectedMuscleGroup = null;
      } else {
        selectedMuscleGroup = value;
      }
    });
    _filterExercises();
  }

  void _onEquipmentChanged(String? value) {
    setState(() {
      if (value == allEquipmentOption) {
        selectedEquipment = null;
      } else {
        selectedEquipment = value;
      }
    });
    _filterExercises();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Todavía no se han cargado los datos iniciales
      return BaseScaffold(
        backgroundColor: GlobalStyles.backgroundColor,
        appBar: AppBar(
          backgroundColor: GlobalStyles.backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text("Seleccionar Ejercicio", style: GlobalStyles.insideAppTitleStyle),
        ),
        body: Center(child: CircularProgressIndicator(color: GlobalStyles.textColor)),
      );
    }

    // Ya se inicializó appState, podemos acceder a sus datos
    final exercises = appState.exercises;

    return BaseScaffold(
      backgroundColor: GlobalStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text("Seleccionar Ejercicio", style: GlobalStyles.insideAppTitleStyle),
        leadingWidth: 60,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: GlobalStyles.textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          AppBarButton(
            text: 'Cancelar',
            onPressed: () {
              Navigator.pop(context);
            },
            textColor: GlobalStyles.textColor,
            backgroundColor: Colors.transparent,
          )
        ],
      ),
      body: Column(
        children: [
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              style: GlobalStyles.subtitleStyle,
              cursorColor: GlobalStyles.textColor,
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio',
                hintStyle: GlobalStyles.subtitleStyle.copyWith(color: GlobalStyles.placeholderColor),
                prefixIcon: Icon(Icons.search, color: GlobalStyles.textColor),
                filled: true,
                fillColor: GlobalStyles.inputBackgroundColor,
                contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: GlobalStyles.focusedBorderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
                _filterExercises();
              },
            ),
          ),

          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDropdown(
                  hint: "Músculo",
                  value: selectedMuscleGroup ?? allMusclesOption,
                  items: getMuscleGroups(),
                  onChanged: _onMuscleGroupChanged,
                ),
                _buildDropdown(
                  hint: "Equipo",
                  value: selectedEquipment ?? allEquipmentOption,
                  items: getEquipment(),
                  onChanged: _onEquipmentChanged,
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: GlobalStyles.textColor))
                : exercises.isEmpty
                    ? Center(
                        child: Text(
                          "No se encontraron ejercicios",
                          style: GlobalStyles.subtitleStyle.copyWith(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        itemCount: exercises.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.grey[700],
                          thickness: 0.5,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          final exerciseName = exercise['name'] as String;

                          return ListTile(
                            tileColor: Colors.transparent,
                            leading: exercise['gifUrl'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      exercise['gifUrl'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.image_not_supported, color: GlobalStyles.textColor);
                                      },
                                    ),
                                  )
                                : Icon(Icons.image_not_supported, color: GlobalStyles.textColor),
                            title: Text(
                              exerciseName,
                              style: GlobalStyles.subtitleStyle.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${exercise['target']}',
                              style: GlobalStyles.subtitleStyle.copyWith(color: Colors.grey[400]),
                            ),
                            onTap: () {
                              Navigator.pop(context, exercise);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: GlobalStyles.inputBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlobalStyles.inputBorderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            hint,
            style: GlobalStyles.subtitleStyle.copyWith(color: GlobalStyles.placeholderColor),
          ),
          value: value,
          dropdownColor: GlobalStyles.inputBackgroundColor,
          iconEnabledColor: GlobalStyles.textColor,
          style: GlobalStyles.subtitleStyle,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: GlobalStyles.subtitleStyle,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
