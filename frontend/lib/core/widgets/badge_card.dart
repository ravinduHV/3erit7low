import 'package:flutter/material.dart';
import 'glass_card.dart';

class BadgeCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final bool isCompleted;
  final double percent;
  final VoidCallback? onTap;

  const BadgeCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.isCompleted = false,
    this.percent = 0.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        child: Row(
          children: [
            // Badge Image with locking status
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? activeColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: imageUrl != null
                        ? Image.asset(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.verified_user,
                                color: isCompleted ? activeColor : Colors.grey[400],
                                size: 30,
                              );
                            },
                          )
                        : Icon(
                            Icons.verified_user,
                            color: isCompleted ? activeColor : Colors.grey[400],
                            size: 30,
                          ),
                  ),
                ),
                if (!isCompleted)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Title & Subtitle Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted ? TextDecoration.none : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100.0,
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green : activeColor,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Completion Icon/Percentage
            if (isCompleted)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              )
            else
              Text(
                "${percent.toInt()}%",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
