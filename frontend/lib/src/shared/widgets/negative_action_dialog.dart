import 'package:flutter/material.dart';

/// Shows the friction questionnaire that gates every destructive / "negative"
/// action in the app (PRD: 3-to-5 questions, unique per action type, shown
/// before the action is confirmed).
///
/// Returns the collected answers, or `null` if the user cancelled. The action
/// should only proceed when a non-null list is returned. All presented
/// questions must be answered before confirmation is allowed.
Future<List<String>?> showNegativeActionQuestionnaire(
  BuildContext context, {
  required String title,
  required List<String> questions,
  String confirmLabel = 'Confirm',
  String intro = 'Answer these quick questions to confirm.',
}) async {
  assert(questions.length >= 3 && questions.length <= 5, 'PRD requires 3 to 5 questions');
  final controllers = List.generate(questions.length, (_) => TextEditingController());
  final result = await showDialog<List<String>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(intro),
            const SizedBox(height: 12),
            for (var i = 0; i < questions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: TextField(
                  controller: controllers[i],
                  decoration: InputDecoration(labelText: questions[i]),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final answers = controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
            // Require every presented question to be answered.
            if (answers.length < questions.length) return;
            Navigator.of(context).pop(answers);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  for (final c in controllers) {
    c.dispose();
  }
  return result;
}
