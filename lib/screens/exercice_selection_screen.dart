// lib/screens/exercise_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../styles/global_styles.dart';
import 'widgets/base_scaffold.dart';
import 'widgets/app_bar_button.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  _ExerciseSelectionScreenState createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  String searchQuery = "";
  String? selectedMuscleGroup;
  String? selectedEquipment;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final String allMusclesOption = "Todos\n los músculos";
  final String allEquipmentOption = "Todos\n los equipos";

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
          title: const Text("Seleccionar Ejercicio", style: GlobalStyles.insideAppTitleStyle),
        ),
        body: const Center(child: CircularProgressIndicator(color: GlobalStyles.textColor)),
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
        title: const Text("Seleccionar Ejercicio", style: GlobalStyles.insideAppTitleStyle),
        leadingWidth: 60,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlobalStyles.textColor),
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
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
            child: TextField(
              style: GlobalStyles.subtitleStyle,
              cursorColor: GlobalStyles.textColor,
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio',
                hintStyle: GlobalStyles.subtitleStyle.copyWith(color: GlobalStyles.placeholderColor),
                prefixIcon: const Icon(Icons.search, color: GlobalStyles.textColor),
                filled: true,
                fillColor: GlobalStyles.inputBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: GlobalStyles.inputBorderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: GlobalStyles.focusedBorderColor),
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

          // Filtros con ancho equitativo y margen
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0), // Padding consistente
            child: Row(
              children: [
                // Primer Filtro: Músculo
                Expanded(
                  child: _buildDropdown(
                    hint: "Músculo",
                    value: selectedMuscleGroup ?? allMusclesOption,
                    items: getMuscleGroups(),
                    onChanged: _onMuscleGroupChanged,
                  ),
                ),

                const SizedBox(width: 10), // Espaciado entre filtros

                // Segundo Filtro: Equipo
                Expanded(
                  child: _buildDropdown(
                    hint: "Equipo",
                    value: selectedEquipment ?? allEquipmentOption,
                    items: getEquipment(),
                    onChanged: _onEquipmentChanged,
                  ),
                ),
              ],
            ),
          ),

          // Lista de ejercicios
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0), // Alinea con otros elementos
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: GlobalStyles.textColor))
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
                              contentPadding: EdgeInsets.zero, // Elimina padding interno
                              minLeadingWidth: 0, // Reduce espacio para el leading
                              visualDensity: VisualDensity.compact, // Reduce la densidad vertical
                              tileColor: Colors.transparent,
                              leading: exercise['gifUrl'] != null
                                  ? ClipOval(
                                      child: Image.network(
                                        exercise['gifUrl'],
                                        width: 50, // Ajusta el tamaño si es necesario
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.image_not_supported, color: GlobalStyles.textColor);
                                        },
                                      ),
                                    )
                                  : const Icon(Icons.image_not_supported, color: GlobalStyles.textColor),
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
      // No establezcas un ancho fijo aquí para permitir que Expanded lo controle
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: GlobalStyles.inputBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlobalStyles.inputBorderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true, // Asegura que ocupe todo el ancho del contenedor
          hint: Text(
            hint,
            style: GlobalStyles.subtitleStyle.copyWith(color: GlobalStyles.placeholderColor),
          ),
          value: value,
          dropdownColor: GlobalStyles.inputBackgroundColor,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: GlobalStyles.textColor,
            size: 24, // Ajusta el tamaño si es necesario
          ),
          iconSize: 24, // Asegura que el ícono tenga un tamaño adecuado
          style: GlobalStyles.subtitleStyle,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: GlobalStyles.subtitleStyle.copyWith(fontSize: 12),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
