// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'auth/login_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.username == null) {
      // Si el usuario no está autenticado, redirigir al inicio de sesión
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      });
      return Scaffold(); // Retorna un scaffold vacío mientras se redirige
    }

    int totalWorkouts = appState.completedRoutines.length;
    int totalVolume = appState.completedRoutines.fold<int>(0, (int sum, routine) {
      return sum + (routine.totalVolume);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        leading: IconButton(
          icon: Icon(Icons.file_download),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Funcionalidad en desarrollo')),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navegar a la pantalla de ajustes
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Fila para la foto de perfil y el nombre con botón de editar
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Foto de perfil
                GestureDetector(
                  onTap: () async {
                    // Lógica para cambiar la foto de perfil
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      await appState.updateProfileImage(pickedFile.path);
                    }
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: appState.profileImagePath != null
                        ? FileImage(File(appState.profileImagePath!))
                        : AssetImage('assets/default_profile.jpg') as ImageProvider,
                  ),
                ),
                SizedBox(width: 16),
                // Columna para el nombre y el botón de editar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.username ?? 'Usuario',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Rutinas completadas: $totalWorkouts'),
                    ],
                  ),
                ),
                // Botón de editar perfil
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    // Navegar a la pantalla de editar perfil
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfileScreen()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 32),
            // Gráficas de datos
            Expanded(
              child: DataGraphs(),
            ),
            SizedBox(height: 16),
            // Mejores marcas personales
            Text('Mejores Marcas Personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: appState.getPersonalRecords().entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key),
                    trailing: Text('${entry.value} kg'),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await appState.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              },
              child: Text('Cerrar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para las gráficas de datos
// Dentro de profile_screen.dart

class DataGraphs extends StatefulWidget {
  @override
  _DataGraphsState createState() => _DataGraphsState();
}

class _DataGraphsState extends State<DataGraphs> {
  String selectedData = 'Duración';
  String selectedTimeframe = 'Semana';

  List<Routine> routines = [];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Obtener y filtrar las rutinas
    routines = getFilteredRoutines(appState);

    // Generar los datos para la gráfica
    List<BarChartGroupData> barData = getBarChartData();

    return Column(
      children: [
        // Gráfica
        Expanded(
          child: BarChart(
            BarChartData(
              barGroups: barData,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: getLeftTitlesInterval(),
                    reservedSize: 40,
                    getTitlesWidget: leftTitleWidgets,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: bottomTitleWidgets,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: false), // Ocultar líneas de cuadrícula
              borderData: FlBorderData(show: false), // Ocultar bordes
              barTouchData: BarTouchData(enabled: false), // Deshabilitar interacción táctil
            ),
          ),
        ),
        SizedBox(height: 16),
        // Botones para seleccionar el tipo de dato
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              DataButton(
                label: 'Duración',
                selected: selectedData == 'Duración',
                onTap: () {
                  setState(() {
                    selectedData = 'Duración';
                  });
                },
              ),
              DataButton(
                label: 'Volumen',
                selected: selectedData == 'Volumen',
                onTap: () {
                  setState(() {
                    selectedData = 'Volumen';
                  });
                },
              ),
              DataButton(
                label: 'RIR Medio',
                selected: selectedData == 'RIR Medio',
                onTap: () {
                  setState(() {
                    selectedData = 'RIR Medio';
                  });
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Botones para seleccionar el marco de tiempo
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              TimeframeButton(
                label: 'Semana',
                selected: selectedTimeframe == 'Semana',
                onTap: () {
                  setState(() {
                    selectedTimeframe = 'Semana';
                  });
                },
              ),
              TimeframeButton(
                label: 'Mes',
                selected: selectedTimeframe == 'Mes',
                onTap: () {
                  setState(() {
                    selectedTimeframe = 'Mes';
                  });
                },
              ),
              TimeframeButton(
                label: 'Año',
                selected: selectedTimeframe == 'Año',
                onTap: () {
                  setState(() {
                    selectedTimeframe = 'Año';
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Routine> getFilteredRoutines(AppState appState) {
    List<Routine> routines = appState.completedRoutines;

    DateTime now = DateTime.now();
    DateTime startDate;

    switch (selectedTimeframe) {
      case 'Semana':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Mes':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Año':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    // Filtrar rutinas dentro del rango de tiempo
    routines = routines.where((routine) {
      return routine.dateCompleted != null && routine.dateCompleted!.isAfter(startDate);
    }).toList();

    // Ordenar rutinas por fecha
    routines.sort((a, b) => a.dateCompleted!.compareTo(b.dateCompleted!));

    return routines;
  }

  List<BarChartGroupData> getBarChartData() {
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < routines.length; i++) {
      double yValue;

      switch (selectedData) {
        case 'Duración':
          yValue = routines[i].duration.inMinutes.toDouble();
          break;
        case 'Volumen':
          yValue = routines[i].totalVolume.toDouble();
          break;
        case 'RIR Medio':
          yValue = calculateAverageRIR(routines[i]);
          break;
        default:
          yValue = 0;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: yValue,
              color: Color(0xFFFFAA76), // Usar el color #FFAA76
              width: 16,
              borderRadius: BorderRadius.circular(4), // Opcional: redondear esquinas
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  // Función para personalizar las etiquetas del eje izquierdo (valores)
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toInt().toString(),
        style: TextStyle(
          color: Colors.black54,
          fontSize: 12,
        ),
      ),
    );
  }

  // Función para personalizar las etiquetas del eje inferior (días)
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    int index = value.toInt();
    if (index < 0 || index >= routines.length) {
      return Container();
    }
    DateTime date = routines[index].dateCompleted!;
    String text;
    switch (selectedTimeframe) {
      case 'Semana':
      case 'Mes':
        text = '${date.day}/${date.month}';
        break;
      case 'Año':
        text = '${date.month}/${date.year}';
        break;
      default:
        text = '';
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black54,
          fontSize: 10,
        ),
      ),
    );
  }

  // Ajustar el intervalo de las etiquetas del eje izquierdo
  double getLeftTitlesInterval() {
    double maxY = 0;
    routines.forEach((routine) {
      double yValue;
      switch (selectedData) {
        case 'Duración':
          yValue = routine.duration.inMinutes.toDouble();
          break;
        case 'Volumen':
          yValue = routine.totalVolume.toDouble();
          break;
        case 'RIR Medio':
          yValue = calculateAverageRIR(routine);
          break;
        default:
          yValue = 0;
      }
      if (yValue > maxY) {
        maxY = yValue;
      }
    });

    // Determinar un intervalo adecuado
    if (maxY <= 10) {
      return 1;
    } else if (maxY <= 50) {
      return 5;
    } else if (maxY <= 100) {
      return 10;
    } else {
      return 20;
    }
  }

  double calculateAverageRIR(Routine routine) {
    int totalRIR = 0;
    int count = 0;

    for (var exercise in routine.exercises) {
      for (var series in exercise.series) {
        totalRIR += series.perceivedExertion;
        count++;
      }
    }

    return count > 0 ? totalRIR / count : 0;
  }
}


class DataButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const DataButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? Colors.blue : Colors.grey,
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}

class TimeframeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TimeframeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: selected ? Colors.blue : Colors.grey),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
