import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SectionChip extends StatelessWidget {
  final String sectionName;
  final String sectionId;

  const SectionChip({
    Key? key,
    required this.sectionName,
    required this.sectionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getSectionColor(sectionId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            sectionName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
