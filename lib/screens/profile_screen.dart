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
import './widgets/base_scaffold.dart';
import './widgets/app_bar_button.dart';
import '../styles/global_styles.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.username == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      });
      return Scaffold(backgroundColor: GlobalStyles.backgroundColor);
    }

    int totalWorkouts = appState.completedRoutines.length;
    int totalVolume = appState.completedRoutines.fold<int>(0, (int sum, routine) {
      return sum + (routine.totalVolume);
    });

    return BaseScaffold(
      backgroundColor: GlobalStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text('Perfil', style: GlobalStyles.insideAppTitleStyle),
        leadingWidth: 100,
        leading: AppBarButton(
          text: 'Descarga',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Funcionalidad en desarrollo')),
            );
          },
          textColor: GlobalStyles.textColor,
          backgroundColor: Colors.transparent,
        ),
        actions: [
          AppBarButton(
            text: 'Ajustes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
            textColor: GlobalStyles.textColor,
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de información de usuario
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Foto de perfil
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        await appState.updateProfileImage(pickedFile.path);
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: appState.profileImagePath != null
                          ? FileImage(File(appState.profileImagePath!))
                          : AssetImage('assets/default_profile.png') as ImageProvider,
                    ),
                  ),
                  SizedBox(width: 16),
                  // Nombre de usuario y rutinas completadas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.username ?? 'Usuario',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: GlobalStyles.textColor),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Rutinas completadas: $totalWorkouts',
                          style: TextStyle(color: GlobalStyles.textColorWithOpacity),
                        ),
                      ],
                    ),
                  ),
                  // Botón de editar perfil
                  IconButton(
                    icon: Icon(Icons.edit, color: GlobalStyles.textColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Sección de gráficas
            Text('Progreso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlobalStyles.textColor)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(16.0),
              height: 350,
              child: DataGraphs(),
            ),

            SizedBox(height: 24),

            // Mejores marcas personales
            Text('Mejores Marcas Personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlobalStyles.textColor)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: appState.getPersonalRecords().entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key, style: TextStyle(color: GlobalStyles.textColor)),
                    trailing: Text('${entry.value} kg', style: TextStyle(color: GlobalStyles.textColor)),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 24),

            // Volumen total acumulado
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, color: GlobalStyles.textColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Volumen total acumulado: $totalVolume kg',
                      style: TextStyle(color: GlobalStyles.textColor),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Botón de cerrar sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalStyles.backgroundButtonsColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await appState.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                },
                child: Text('Cerrar Sesión', style: GlobalStyles.buttonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para las gráficas de datos
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
    routines = getFilteredRoutines(appState);

    List<BarChartGroupData> barData = getBarChartData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
            ),
          ),
        ),
        SizedBox(height: 16),
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

    routines = routines.where((routine) {
      return routine.dateCompleted != null && routine.dateCompleted!.isAfter(startDate);
    }).toList();

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
              color: Color(0xFFFFAA76),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    return barGroups;
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toInt().toString(),
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

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
        style: TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
  }

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
          backgroundColor: selected ? GlobalStyles.backgroundButtonsColor : Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white)),
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
          side: BorderSide(color: selected ? GlobalStyles.backgroundButtonsColor : Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Text(label, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
