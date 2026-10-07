import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../core/constants/strings.dart';
import 'safe_asset_image.dart';

/// Renders either a chosen avatar icon or an asset image for the user.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatar,
    this.size = 54,
    this.borderWidth = 2.0,
    this.borderColor = AppColors.crimson,
    this.showBorder = true,
  });

  final String avatar;
  final double size;
  final double borderWidth;
  final Color borderColor;
  final bool showBorder;

  static const Map<String, IconData> avatarIcons = {
    'flower': Icons.local_florist_rounded,
    'favorite': Icons.favorite_rounded,
    'heart': Icons.favorite_rounded,
    'face': Icons.face_3_rounded,
    'smile': Icons.face_3_rounded,
    'pets': Icons.pets_rounded,
    'star': Icons.star_rounded,
    'butterfly': Icons.flutter_dash_rounded,
    'person': Icons.person_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final iconData = avatarIcons[avatar.toLowerCase()];
    final isIcon = iconData != null;

    Widget content;
    if (isIcon) {
      content = Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.rose,
              AppColors.crimsonDark,
            ],
          ),
        ),
        child: Icon(
          iconData,
          color: Colors.white,
          size: size * 0.52,
        ),
      );
    } else {
      // It's an asset path or URL
      final assetPath = avatar.isEmpty ? AppAssets.avatar : avatar;
      content = SafeAssetImage(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fallbackIcon: Icons.person_rounded,
      );
    }

    if (!showBorder) {
      return ClipOval(child: content);
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth > 0 ? 2 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(child: content),
    );
  }
}
