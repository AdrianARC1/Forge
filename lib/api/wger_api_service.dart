import 'dart:convert';
import 'package:http/http.dart' as http;

class WgerApiService {
  final String baseUrl = "https://wger.de/api/v2";

  // Mapa para almacenar imágenes de ejercicios
  Map<int, String> exerciseImages = {};

  // Obtener ejercicios con filtros opcionales (por grupo muscular o equipo)
  Future<List<Map<String, dynamic>>> fetchExercises({int? muscleGroup, int? equipment, int page = 1}) async {
    try {
      String urlString = "$baseUrl/exercise?language=4&page=$page";
      if (muscleGroup != null) {
        urlString += "&category=$muscleGroup";
      }
      if (equipment != null) {
        urlString += "&equipment=$equipment";
      }
      final url = Uri.parse(urlString);

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final exercises = data['results'] as List;

        // Si el mapa de imágenes está vacío, cargar imágenes
        if (exerciseImages.isEmpty) {
          await _fetchExerciseImages();
        }

        // Agregar la URL de la imagen a cada ejercicio
        exercises.forEach((exercise) {
          int id = exercise['id'];
          exercise['image'] = exerciseImages[id];
        });

        return exercises.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Error al obtener ejercicios: ${response.statusCode}");
      }
    } catch (e) {
      print("Error en la API de Wger: $e");
      return [];
    }
  }

  // Obtener imágenes de ejercicios
  Future<void> _fetchExerciseImages() async {
    try {
      int page = 1;
      bool hasNextPage = true;

      while (hasNextPage) {
        final url = Uri.parse("$baseUrl/exerciseimage/?page=$page");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final images = data['results'] as List;

          for (var imageData in images) {
            int exerciseId = imageData['exercise'];
            String imageUrl = imageData['image'];
            exerciseImages[exerciseId] = imageUrl;
          }

          hasNextPage = data['next'] != null;
          page++;
        } else {
          throw Exception("Error al obtener imágenes de ejercicios: ${response.statusCode}");
        }
      }
    } catch (e) {
      print("Error en la API de Wger: $e");
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
