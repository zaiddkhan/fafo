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
  assert(
    questions.length >= 3 && questions.length <= 5,
    'PRD requires 3 to 5 questions',
  );
  final controllers = List.generate(
    questions.length,
    (_) => TextEditingController(),
  );

  final result = await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final allAnswered = controllers.every((c) => c.text.trim().isNotEmpty);
          final bottom = MediaQuery.viewInsetsOf(context).bottom;

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 18 + bottom),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      intro,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 18),
                    for (var i = 0; i < questions.length; i++) ...[
                      Text(
                        questions[i],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: controllers[i],
                        minLines: 2,
                        maxLines: 3,
                        textInputAction: i == questions.length - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Type your answer',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: allAnswered
                                ? () {
                                    Navigator.of(context).pop(
                                      controllers
                                          .map((c) => c.text.trim())
                                          .toList(growable: false),
                                    );
                                  }
                                : null,
                            child: Text(confirmLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  for (final c in controllers) {
    c.dispose();
  }
  return result;
}
