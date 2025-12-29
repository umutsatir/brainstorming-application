import 'package:flutter/material.dart';

class SettingsChangeNameScreen extends StatefulWidget {
  final String currentName;

  const SettingsChangeNameScreen({
    super.key,
    required this.currentName,
  });

  @override
  State<SettingsChangeNameScreen> createState() =>
      _SettingsChangeNameScreenState();
}

class _SettingsChangeNameScreenState extends State<SettingsChangeNameScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Name cannot be empty.')),
        );
      return;
    }

    // TODO: Backend entegrasyonu
    // PATCH /me { displayName: newName }
    // ve local user state güncellemesi (provider ile)

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Name updated (dummy – backend not wired yet).'),
        ),
      );

    Navigator.of(context).pop(); // geri dön
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change display name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Display name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
