import 'package:flutter/material.dart';
import '../../app_state.dart';

class DismissibleSeriesItem extends StatelessWidget {
  final Series series;
  final VoidCallback onDelete;
  final Widget child;

  const DismissibleSeriesItem({
    Key? key,
    required this.series,
    required this.onDelete,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(series.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        onDelete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Serie eliminada")),
        );
      },
      child: child,
    );
  }
}
