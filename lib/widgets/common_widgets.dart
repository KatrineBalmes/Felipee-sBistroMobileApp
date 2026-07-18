import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

String peso(num v) => '₱${v.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d)\.)'),
      (m) => '${m[1]},',
    )}';

/// Card container with the app's signature dark-glass look.
class BistroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const BistroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  const GradientButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final TextAlign align;
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxis = align == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          ),
          child: Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: AppColors.accent2,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(title,
            textAlign: align,
            style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              subtitle!,
              textAlign: align,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
            ),
          ),
        ],
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  final String status; // OK/Good, Low, Out
  const StatusPill({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'OK':
      case 'Good':
        return AppColors.accentGreen;
      case 'Low':
        return AppColors.warning;
      default:
        return AppColors.accentRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(status,
              style: TextStyle(
                  color: _color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Simple responsive helper used across screens.
bool isWide(BuildContext context) => MediaQuery.of(context).size.width >= 900;
bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600;

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Turns a stored "YYYY-MM-DD HH:MM:SS" order timestamp into a clear,
/// human-friendly label like "Today · 2:57 PM" or "Jul 18 · 12:00 PM",
/// so order history actually shows what time each order really came in.
String formatOrderTimestamp(String raw) {
  try {
    final parts = raw.trim().split(' ');
    final dateBits = parts[0].split('-').map(int.parse).toList();
    final timeBits = parts.length > 1
        ? parts[1].split(':').map(int.parse).toList()
        : <int>[0, 0, 0];

    final dt = DateTime(
      dateBits[0],
      dateBits[1],
      dateBits[2],
      timeBits.isNotEmpty ? timeBits[0] : 0,
      timeBits.length > 1 ? timeBits[1] : 0,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(dt.year, dt.month, dt.day);
    final dayDiff = today.difference(orderDay).inDays;

    final String dayLabel;
    if (dayDiff == 0) {
      dayLabel = 'Today';
    } else if (dayDiff == 1) {
      dayLabel = 'Yesterday';
    } else {
      dayLabel = '${_monthNames[dt.month - 1]} ${dt.day}';
    }

    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$dayLabel · $hour12:$minute $ampm';
  } catch (_) {
    return raw;
  }
}

/// Shows the dish's actual photo when we have one that truly matches its
/// name (no more mismatched photos like a Sprite bottle under "Iced Tea").
/// When there's no real matching photo, it falls back to a clean,
/// brand-colored icon tile for the item's category instead of borrowing
/// an unrelated product's picture.
class MenuItemPhoto extends StatelessWidget {
  final String name;
  final String category;
  final BoxFit fit;
  const MenuItemPhoto({
    super.key,
    required this.name,
    required this.category,
    this.fit = BoxFit.cover,
  });

  // Only items we have a genuine, correctly-matching photo for.
  static const Map<String, String> _photoByName = {
    'Lomi Special': 'assets/images/gallery_5.jpg',
    'Lomi Regular': 'assets/images/gallery_3.jpg',
    'Extra Mami': 'assets/images/gallery_1.jpg',
    'Fried Rice': 'assets/images/gallery_2.jpg',
    'Softdrinks': 'assets/images/coke.jpg',
  };

  static const Map<String, IconData> _iconByCategory = {
    'Lomi': Icons.ramen_dining,
    'Pancit': Icons.dinner_dining,
    'Drinks': Icons.local_drink,
    'Others': Icons.rice_bowl,
  };

  static const Map<String, List<Color>> _gradientByCategory = {
    'Lomi': [AppColors.accent, AppColors.accent2],
    'Pancit': [Color(0xFFD9642C), Color(0xFF9C3D14)],
    'Drinks': [AppColors.accentBlue, Color(0xFF1B4F72)],
    'Others': [AppColors.accentGreen, Color(0xFF117A52)],
  };

  @override
  Widget build(BuildContext context) {
    final photo = _photoByName[name];
    if (photo != null) return Image.asset(photo, fit: fit);

    final colors = _gradientByCategory[category] ?? const [AppColors.accent, AppColors.accent2];
    final icon = _iconByCategory[category] ?? Icons.restaurant_menu;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
