import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/map_provider.dart';

class AlertBanner extends ConsumerWidget {
  const AlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapProvider);

    if (!state.showAlert || state.alertMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.alertBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.alertBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.alertDot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.alertMessage!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.alertText,
                height: 1.4,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(mapProvider.notifier).dismissAlert(),
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                '×',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFB45309),
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
