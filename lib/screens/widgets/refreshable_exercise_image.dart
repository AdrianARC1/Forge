// lib/widgets/refreshable_exercise_image.dart

import 'package:flutter/material.dart';
import '../../api/exercise_db_api_service.dart';

class RefreshableExerciseImage extends StatefulWidget {
  final String? gifUrl; // Cambiado a String? para permitir null
  final String exerciseId;
  final double width;
  final double height;
  final BoxShape shape;
  final BoxFit fit;

  RefreshableExerciseImage({
    required this.gifUrl,
    required this.exerciseId,
    this.width = 50,
    this.height = 50,
    this.shape = BoxShape.circle,
    this.fit = BoxFit.cover,
  });

  @override
  _RefreshableExerciseImageState createState() => _RefreshableExerciseImageState();
}

class _RefreshableExerciseImageState extends State<RefreshableExerciseImage> {
  String? currentGifUrl; // Cambiado a String? para permitir null
  bool isLoading = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    currentGifUrl = widget.gifUrl;
    if (currentGifUrl == null || currentGifUrl!.isEmpty) {
      hasError = true;
    }
  }

  Future<void> _fetchNewGifUrl() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final updatedExercise = await ExerciseDbApiService().fetchExerciseById(widget.exerciseId);
      setState(() {
        currentGifUrl = updatedExercise['gifUrl'];
        isLoading = false;
        if (currentGifUrl == null || currentGifUrl!.isEmpty) {
          hasError = true;
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print('Error al obtener nueva gifUrl: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError || currentGifUrl == null || currentGifUrl!.isEmpty) {
      // Mostrar ícono o placeholder
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          shape: widget.shape,
          color: Colors.grey[300],
        ),
        child: Icon(Icons.image_not_supported, size: widget.width * 0.6),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        shape: widget.shape,
        image: DecorationImage(
          image: NetworkImage(currentGifUrl!),
          fit: widget.fit,
          onError: (error, stackTrace) {
            setState(() {
              hasError = true;
            });
            _fetchNewGifUrl();
          },
        ),
      ),
    );
  }
}
