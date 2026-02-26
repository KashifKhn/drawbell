import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class AlarmEditorScreen extends StatelessWidget {
  final String? alarmId;

  const AlarmEditorScreen({super.key, this.alarmId});

  bool get isEditing => alarmId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Alarm' : 'New Alarm'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(child: Text('Alarm editor coming in Phase 2')),
    );
  }
}
