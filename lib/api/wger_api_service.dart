import 'dart:convert';
import 'package:http/http.dart' as http;

class WgerApiService {
  final String baseUrl = "https://wger.de/api/v2";

  // Obtener ejercicios con filtros opcionales (por grupo muscular o equipo)
  Future<List<Map<String, dynamic>>> fetchExercises({int? muscleGroup, int? equipment}) async {
    try {
      final url = Uri.parse("$baseUrl/exercise?language=4"); // 'language=2' para obtener ejercicios en inglés
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final exercises = data['results'] as List;
        
        // Filtrar por grupo muscular o equipo si están presentes
        final filteredExercises = exercises.where((exercise) {
          final categoryMatch = muscleGroup == null || exercise['category'] == muscleGroup;
          final equipmentMatch = equipment == null || (exercise['equipment'] as List).contains(equipment);
          return categoryMatch && equipmentMatch;
        }).toList();

        return filteredExercises.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Error al obtener ejercicios: ${response.statusCode}");
      }
    } catch (e) {
      print("Error en la API de Wger: $e");
      return [];
    }
  }
  // Obtener categorías de músculos
  Future<List<Map<String, dynamic>>> fetchMuscleGroups() async {
    try {
      final url = Uri.parse("$baseUrl/exercisecategory/");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['results'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception("Error al obtener categorías de músculos: ${response.statusCode}");
      }
    } catch (e) {
      print("Error en la API de Wger: $e");
      return [];
    }
  }

  // Obtener tipos de equipo
  Future<List<Map<String, dynamic>>> fetchEquipment() async {
    try {
      final url = Uri.parse("$baseUrl/equipment/");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['results'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception("Error al obtener equipos: ${response.statusCode}");
      }
    } catch (e) {
      print("Error en la API de Wger: $e");
      return [];
    }
  }


}
