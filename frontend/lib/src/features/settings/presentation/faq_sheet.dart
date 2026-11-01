import 'package:flutter/material.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/core/utils/legal_links.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// FAQ: eleven answers in four groups (from Profile's FAQ tile and Settings).
Future<void> showFaqSheet(BuildContext context) =>
    showFafoSheet<void>(context, title: 'FAQ', tall: true, builder: (_) => const FaqSheet());

const _faq = <(String, List<(String, String)>)>[
  ('Nudges', [
    ('What’s a nudge?', 'One plan, one clear answer. Write what you want to do, pick a friend or a group, and they get 10 minutes to say yes or no. No chat, no back and forth.'),
    ('What happens if nobody answers?', 'The nudge expires after 10 minutes. Nothing breaks, and you can send a new one straight away.'),
    ('What happens after someone says yes?', 'A second countdown starts, the 5, 10 or 15 minutes you picked. That’s how long you both have to get there.'),
    ('What does “I’m free” do?', 'Switch it on when you’re up for something. Your friends see a blue dot on your photo, and you show up first when they make a plan. It stays on until you turn it off.'),
  ]),
  ('Side quests', [
    ('What are side quests?', 'Small 15-minute things to do with a friend, like a snack run or a phone-free lap. Pick one, tap Invite, and it goes out just like a nudge.'),
    ('Who makes them?', 'We do. The FaFo team adds new ones, so there’s always something to try.'),
  ]),
  ('Friends and groups', [
    ('How do I add friends?', 'Tap the add icon on Friends. Contacts already on FaFo show Add. Everyone else shows Invite, so you can send them the app.'),
    ('How do groups work?', 'Pick two or more friends and give the group a name. Anyone in it can send it a nudge. Only the admin can rename it or remove people.'),
  ]),
  ('Account', [
    ('Can I change my name or username?', 'Yes. Tap your photo at the top of any screen, then Edit.'),
    ('How do I delete my account?', 'Settings, then Delete account. It can’t be undone.'),
  ]),
];

class FaqSheet extends StatefulWidget {
  const FaqSheet({super.key});

  @override
  State<FaqSheet> createState() => _FaqSheetState();
}

class _FaqSheetState extends State<FaqSheet> {
  String? _open;

  @override
  Widget build(BuildContext context) {
    return FafoSheetBody(
      tall: true,
      children: [
        for (final (group, items) in _faq) ...[
          FafoSectionLabel(group, top: group == _faq.first.$1 ? 6 : 26, bottom: 4),
          for (final (q, a) in items) _Question(
            question: q,
            answer: a,
            open: _open == q,
            onTap: () => setState(() => _open = _open == q ? null : q),
          ),
        ],
        const SizedBox(height: 26),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Still stuck? ', style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
            FafoInlineLink(label: 'Report a problem', onTap: () => reportProblem(context)),
          ],
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.question, required this.answer, required this.open, required this.onTap});

  final String question;
  final String answer;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 54),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
              child: Row(
                children: [
                  Expanded(child: Text(question, style: AppTypography.ui(15.5, fontWeight: FontWeight.w600))),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 30, 12),
                  child: Text(answer, style: AppTypography.ui(14.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
