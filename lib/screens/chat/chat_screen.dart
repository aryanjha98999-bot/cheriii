import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/app_state.dart';
import '../../services/ai_chat_service.dart';
import '../../services/gemini_service.dart';
import '../../widgets/ai_message_card.dart';
import '../../widgets/app_background.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();
  final AiChatService _aiChatService = AiChatService();
  final GeminiService _gemini = GeminiService();

  late List<ChatMessage> _messages = [];
  bool _typing = false;
  bool _inputFocused = false;
  StreamSubscription<String>? _streamSub;

  // Conversation history for Gemini multi-turn context (last 10 turns)
  final List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user;
    _messages = [
      ChatMessage(
        text: "Hey ${user.name}! 💕\nI'm Cherry, your personal wellness companion. "
            'I know your cycle, your symptoms and how you have been feeling. '
            'Ask me anything about your period, mood, food or self-care.',
        isUser: false,
        time: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];

    _loadHistory();

    _focus.addListener(() {
      if (mounted) setState(() => _inputFocused = _focus.hasFocus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _loadHistory() async {
    final state = context.read<AppState>();
    if (state.isLoggedIn) {
      final history = await _aiChatService.loadHistory();
      if (mounted && history.isNotEmpty) {
        setState(() {
          _messages = history;
          // Rebuild Gemini history from loaded messages
          _history.clear();
          for (final m in history) {
            _history.add({'isUser': m.isUser, 'text': m.text});
          }
        });
        _scrollToEnd();
      }
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
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
    FocusScope.of(context).unfocus();

    final state = context.read<AppState>();

    // Add user message
    final userMsg = ChatMessage(text: text, isUser: true, time: DateTime.now());
    setState(() {
      _messages.add(userMsg);
      _typing = true;
    });
    _scrollToEnd();

    unawaited(_aiChatService.saveMessage(isUser: true, message: text));

    // Add a placeholder bot message to stream into
    final botMsg = ChatMessage(text: '', isUser: false, time: DateTime.now());
    setState(() => _messages.add(botMsg));

    // Build history snapshot (last 10 turns, excluding the empty placeholder)
    final historySnapshot = List<Map<String, dynamic>>.from(_history);

    final streamBuffer = StringBuffer();

    _streamSub?.cancel();
    _streamSub = _gemini
        .streamChat(
          history: historySnapshot,
          userMessage: text,
          state: state,
        )
        .listen(
      (chunk) {
        streamBuffer.write(chunk);
        if (!mounted) return;
        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            text: streamBuffer.toString(),
            isUser: false,
            time: botMsg.time,
          );
        });
        _scrollToEnd();
      },
      onDone: () {
        if (!mounted) return;
        final finalText = streamBuffer.toString();
        setState(() {
          _typing = false;
          _messages[_messages.length - 1] = ChatMessage(
            text: finalText.isEmpty
                ? "I'm here for you 💕 Try asking about cramps, mood, food or your cycle."
                : finalText,
            isUser: false,
            time: botMsg.time,
          );
        });
        // Update history for next turn
        _history.add({'isUser': true, 'text': text});
        _history.add({'isUser': false, 'text': finalText});
        // Keep last 10 turns (20 messages)
        while (_history.length > 20) {
          _history.removeAt(0);
        }
        unawaited(_aiChatService.saveMessage(
          isUser: false,
          message: finalText,
        ));
      },
      onError: (dynamic e) {
        if (!mounted) return;
        setState(() {
          _typing = false;
          _messages[_messages.length - 1] = ChatMessage(
            text: 'Could not connect to Cherry AI. Please check your internet 💕',
            isUser: false,
            time: botMsg.time,
          );
        });
      },
    );
  }

  void _clear() {
    _streamSub?.cancel();
    final name = context.read<AppState>().user.name;
    unawaited(_aiChatService.clearHistory());
    _history.clear();
    setState(() {
      _typing = false;
      _messages = [
        ChatMessage(
          text: "Hey $name! 💕\nI'm Cherry, your personal wellness companion. "
              'I know your cycle, your symptoms and how you have been feeling. '
              'Ask me anything about your period, mood, food or self-care.',
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
      color: Colors.white.withValues(alpha: 0.9),
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
                          color: AppColors.crimson.withValues(alpha: 0.28),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
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