import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/specto_service.dart';

class AddSubjectsScreen extends StatefulWidget {
  const AddSubjectsScreen({super.key});

  @override
  State<AddSubjectsScreen> createState() => _AddSubjectsScreenState();
}

class _AddSubjectsScreenState extends State<AddSubjectsScreen> {
  final List<TextEditingController> _controllers = [TextEditingController()];
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeField(int index) {
    if (_controllers.length <= 1) return;
    setState(() {
      final c = _controllers.removeAt(index);
      c.dispose();
    });
  }

  Future<void> _submit() async {
    final names = _controllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите хотя бы один класс/предмет')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await SpectoService.instance.createSubjects(names);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Классы успешно добавлены')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка добавления классов')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Добавить классы')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.screenH,
                  vertical: AppPadding.screenV,
                ),
                itemCount: _controllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _controllers[index],
                            decoration: InputDecoration(
                              labelText: 'Класс ${index + 1}',
                              hintText: 'Например: Алгебра',
                              prefixIcon: const Icon(
                                Icons.book_outlined,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_controllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded,
                                color: AppColors.danger),
                            onPressed: () => _removeField(index),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppPadding.screenH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addField,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Добавить ещё одно поле'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Подтвердить'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

