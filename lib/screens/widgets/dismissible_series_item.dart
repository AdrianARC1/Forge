import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../app_state.dart';

class DismissibleSeriesItem extends StatelessWidget {
  final Series series;
  final VoidCallback onDelete;
  final Widget child;

  const DismissibleSeriesItem({
    super.key,
    required this.series,
    required this.onDelete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(series.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        onDelete();
        toastification.show(
          context: context,
          title: const Text('Serie eliminada'),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 2),
          alignment: Alignment.bottomCenter
        );
      },
      child: child,
    );
  }
}
