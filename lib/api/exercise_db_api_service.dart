// lib/api/exercise_db_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExerciseDbApiService {
  final String baseUrl = "https://exercisedb.p.rapidapi.com";
  final String apiKey = dotenv.env['API_KEY'] ?? 'API_KEY not found';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
      };

  // Obtener todos los ejercicios
  Future<List<Map<String, dynamic>>> fetchExercises() async {
    try {
      final url = Uri.parse("$baseUrl/exercises");
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Error al obtener ejercicios: ${response.statusCode}");
      }
    } catch (e) {
      return [];
    }
  }

  // Nuevo método para obtener ejercicios filtrados
  Future<List<Map<String, dynamic>>> fetchExercisesFiltered(
      {String? muscleGroup, String? equipment}) async {
    try {
      String endpoint = "$baseUrl/exercises";
      if (muscleGroup != null) {
        endpoint = "$baseUrl/exercises/target/$muscleGroup";
      } else if (equipment != null) {
        endpoint = "$baseUrl/exercises/equipment/$equipment";
      }

      final url = Uri.parse(endpoint);
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Error al obtener ejercicios filtrados: ${response.statusCode}");
      }
    } catch (e) {
      return [];
    }
  }

  // Obtener ejercicios por grupo muscular
  Future<List<Map<String, dynamic>>> fetchExercisesByMuscleGroup(String muscleGroup) async {
    try {
      final url = Uri.parse("$baseUrl/exercises/target/$muscleGroup");
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Error al obtener ejercicios por músculo: ${response.statusCode}");
      }
    } catch (e) {
      return [];
    }
  }

  // Obtener ejercicios por equipo
  Future<List<Map<String, dynamic>>> fetchExercisesByEquipment(String equipment) async {
    try {
      final url = Uri.parse("$baseUrl/exercises/equipment/$equipment");
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Error al obtener ejercicios por equipo: ${response.statusCode}");
      }
    } catch (e) {
      return [];
    }
  }

  // Obtener lista de grupos musculares
  Future<List<String>> fetchMuscleGroups() async {
    try {
      final url = Uri.parse("$baseUrl/exercises/targetList");
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception("Error al obtener grupos musculares: ${response.statusCode}");
      }
    } catch (e) {
      return [];
    }
  }

  // Obtener lista de equipos
  Future<List<String>> fetchEquipmentList() async {
    try {
      final url = Uri.parse("$baseUrl/exercises/equipmentList");
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception("Error al obtener lista de equipos: ${response.statusCode}");
      }
    } catch (e) {
      return [];
    }
  }
}