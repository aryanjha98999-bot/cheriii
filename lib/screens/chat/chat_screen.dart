import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/app_state.dart';
import '../../widgets/ai_message_card.dart';
import '../../widgets/app_background.dart';

/// Keyword-based mock replies for Cherry AI.
class MockChatService {
  MockChatService._();

  static const String _doctor =
      "If the pain is severe or unusual, it's a good idea to talk to a doctor.";

  static ChatMessage reply(String input, {String name = 'there'}) {
    final q = input.toLowerCase();
    bool has(List<String> words) => words.any(q.contains);

    ChatMessage msg(
      String text, {
      List<String> bullets = const [],
      String? outro,
    }) =>
        ChatMessage(
          text: text,
          isUser: false,
          time: DateTime.now(),
          bullets: bullets,
          outro: outro,
        );

    if (RegExp(r'^(hi|hello|hey)\b').hasMatch(q.trim())) {
      return msg(
        'Hi $name! 💕 I can help with cramps, your cycle, food, mood and '
        'skincare. What would you like to know?',
      );
    }

    if (has(['thank'])) {
      return msg("You're so welcome, $name! 💕 I'm here whenever you need me.");
    }

    if (has(['why']) && has(['cramp'])) {
      return msg(
        'Cramps happen when your uterus contracts to shed its lining. '
        'Chemicals called prostaglandins trigger those contractions, so higher '
        'levels can mean stronger cramps.',
        bullets: const [
          "They're often strongest in the first 1-2 days",
          'Stress, caffeine and low sleep can make them worse',
          'Warmth and gentle movement usually ease them',
        ],
        outro: _doctor,
      );
    }

    if (has(['cramp', 'pain', 'ache'])) {
      return msg(
        "I'm sorry you're feeling uncomfortable 💕\n"
        'Here are a few things that may help:',
        bullets: const [
          'Use a warm heating pad',
          'Try gentle stretches or yoga',
          'Stay hydrated',
          'Have a warm drink (like herbal tea)',
          'Get some rest',
        ],
        outro: _doctor,
      );
    }

    if (has(['regular', 'irregular', 'late', 'cycle length', 'my cycle'])) {
      return msg(
        'Cycles between 21 and 35 days are generally considered regular, and a '
        'few days of variation is normal. Your logged cycles average about 29 '
        'days, which looks steady. ✨',
        outro: 'Keep logging for a few more months and your predictions will '
            'get even more accurate.',
      );
    }

    if (has(['food', 'eat', 'diet', 'nutrition', 'craving'])) {
      return msg(
        'Eating well can really change how you feel through your cycle. 🥗',
        bullets: const [
          'Iron-rich foods like spinach, lentils and beans',
          'Magnesium sources like nuts, seeds and dark chocolate',
          'Fruits and veggies for fibre and vitamins',
          'Water-rich foods like cucumber and watermelon',
          'Go easy on very salty, sugary or processed snacks',
        ],
        outro: 'Small, regular meals can also keep your energy steady.',
      );
    }

    if (has(['mood', 'swing', 'sad', 'anxi', 'irritab', 'stress'])) {
      return msg(
        'Mood swings are very common because hormones like estrogen and '
        'progesterone shift through your cycle. 💕',
        bullets: const [
          'Try light exercise or a walk outside',
          'Keep a regular sleep routine',
          'Log your mood to spot patterns',
          'Talk to someone you trust',
        ],
        outro: 'If low mood feels heavy or lasts a long time, please consider '
            'talking to a doctor or counsellor.',
      );
    }

    if (has(['skin', 'acne', 'pimple', 'breakout'])) {
      return msg(
        'Hormonal changes can affect your skin, especially before your '
        'period. ✨',
        bullets: const [
          'Wash your face gently twice a day',
          'Use a non-comedogenic moisturiser',
          'Avoid picking or squeezing breakouts',
          'Drink plenty of water and get enough sleep',
        ],
        outro: 'If acne is painful or persistent, a dermatologist can help.',
      );
    }

    if (has(['headache', 'migraine'])) {
      return msg(
        'Headaches around your period are often linked to hormone changes. '
        'Here is what may help:',
        bullets: const [
          'Rest in a quiet, dim room',
          'Drink a glass of water',
          'Try a cool or warm compress',
          'Do gentle neck and shoulder stretches',
        ],
        outro: 'If headaches are frequent or very intense, check in with a '
            'doctor.',
      );
    }

    if (has(['bloat'])) {
      return msg(
        'Bloating is common before and during your period. Some ideas:',
        bullets: const [
          'Sip peppermint or ginger tea',
          'Cut back on salty foods',
          'Go for a short, easy walk',
          'Wear comfy, loose clothing',
        ],
      );
    }

    if (has(['sleep', 'tired', 'fatigue', 'energy'])) {
      return msg(
        'Energy often dips in the days before your period. Be kind to '
        'yourself 💕',
        bullets: const [
          'Aim for a consistent bedtime',
          'Have a light snack with protein and iron',
          'Take short breaks and stretch',
          'Limit caffeine late in the day',
        ],
      );
    }

    return msg(
      "Thanks for sharing, $name 💕 I'm still learning, but I can help with "
      'cramps, cycle regularity, food, mood and skincare. Tap a suggestion '
      'below or tell me a bit more about how you feel.',
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  late List<ChatMessage> _messages = _seed();
  bool _typing = false;
  bool _inputFocused = false;
  Timer? _timer;

  /// Pre-filled conversation that matches the design showcase.
  static List<ChatMessage> _seed() => [
        ChatMessage(
          text: AppStrings.botGreeting,
          isUser: false,
          time: DateTime(2024, 10, 8, 9, 41),
        ),
        ChatMessage(
          text: 'I have cramps today. What can I do?',
          isUser: true,
          time: DateTime(2024, 10, 8, 9, 42),
        ),
        ChatMessage(
          text: "I'm sorry you're feeling uncomfortable 💕\n"
              'Here are a few things that may help:',
          isUser: false,
          time: DateTime(2024, 10, 8, 9, 42),
          bullets: const [
            'Use a warm heating pad',
            'Try gentle stretches or yoga',
            'Stay hydrated',
            'Have a warm drink (like herbal tea)',
            'Get some rest',
          ],
          outro:
              "If the pain is severe or unusual, it's a good idea to talk to "
              'a doctor.',
        ),
      ];

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _inputFocused = _focus.hasFocus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty || _typing) return;
    _input.clear();
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, time: DateTime.now()),
      );
      _typing = true;
    });
    _scrollToEnd();

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      final name = context.read<AppState>().user.name;
      setState(() {
        _messages.add(MockChatService.reply(text, name: name));
        _typing = false;
      });
      _scrollToEnd();
    });
  }

  void _clear() {
    _timer?.cancel();
    final name = context.read<AppState>().user.name;
    setState(() {
      _typing = false;
      _messages = [
        ChatMessage(
          text: AppStrings.botGreeting.replaceFirst('Aarohi', name),
          isUser: false,
          time: DateTime.now(),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ChatHeader(onClear: _clear),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView.builder(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: _messages.length + (_typing ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= _messages.length) return const _TypingBubble();
                    return AiMessageCard(message: _messages[i]);
                  },
                ),
              ),
            ),
            if (!_inputFocused)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in AppStrings.chatSuggestions)
                      _SuggestionChip(label: s, onTap: () => _send(s)),
                  ],
                ),
              ),
            _InputBar(
              controller: _input,
              focusNode: _focus,
              onSend: _send,
              onMic: () => Helpers.showSnack(
                context,
                'Voice input is coming soon 🎙️',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 6),
      child: Row(
        children: [
          const BotAvatar(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.botName,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 17),
                ),
                Text(
                  AppStrings.botTagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded,
                color: AppColors.textPrimary),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (v) {
              if (v == 'clear') onClear();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'clear',
                child: Text('Clear chat', style: AppTextStyles.body),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const StadiumBorder(side: BorderSide(color: AppColors.roseLight)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11.5,
              color: AppColors.crimson,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onMic,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 54,
        padding: const EdgeInsets.fromLTRB(6, 0, 7, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.mic_none_rounded,
                  color: AppColors.crimson),
              onPressed: onMic,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                style: AppTextStyles.body,
                decoration: const InputDecoration(
                  hintText: AppStrings.askHint,
                  filled: false,
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'Send message',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onSend(controller.text),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.buttonGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.crimson.withOpacity(0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bot "typing..." bubble with three pulsing dots.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BotAvatar(size: 34),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: AppColors.softShadow,
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                      child: Opacity(
                        opacity: 0.3 +
                            0.7 *
                                ((math.sin(_c.value * 2 * math.pi - i * 0.9) +
                                        1) /
                                    2),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.crimson,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}