import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.bullets = const [],
    this.outro,
  });

  final String text;
  final bool isUser;
  final DateTime time;
  final List<String> bullets;
  final String? outro;
}

/// Red rounded robot face used as the Cherry AI avatar.
class BotAvatar extends StatelessWidget {
  const BotAvatar({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget eye() => Container(
          width: size * 0.11,
          height: size * 0.11,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.rose, AppColors.crimsonDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.68,
          height: size * 0.46,
          decoration: BoxDecoration(
            color: const Color(0xFF3A0D18),
            borderRadius: BorderRadius.circular(size * 0.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [eye(), eye()],
          ),
        ),
      ),
    );
  }
}

/// Chat bubble: bot (white, avatar left) or user (crimson, right).
class AiMessageCard extends StatelessWidget {
  const AiMessageCard({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxWidth = MediaQuery.sizeOf(context).width * (isUser ? 0.74 : 0.70);
    final textColor = isUser ? Colors.white : AppColors.textPrimary;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isUser ? AppColors.crimson : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 18 : 6),
          topRight: Radius.circular(isUser ? 6 : 18),
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.text, style: AppTextStyles.body.copyWith(color: textColor)),
          if (message.bullets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final b in message.bullets)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 8, right: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.crimson,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              b,
                              style: AppTextStyles.body
                                  .copyWith(color: textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (message.outro != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message.outro!,
                style: AppTextStyles.body.copyWith(color: textColor),
              ),
            ),
        ],
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubble,
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            Helpers.time(message.time),
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const BotAvatar(size: 34),
            const SizedBox(width: 8),
          ],
          Flexible(child: content),
        ],
      ),
    );
  }
}