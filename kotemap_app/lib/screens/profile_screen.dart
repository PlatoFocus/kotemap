import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/i18n/app_lang.dart';
import '../core/i18n/app_strings.dart';
import '../core/providers/tab_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme_colors.dart';
import '../features/map/presentation/widgets/bottom_nav_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: context.tc.background,
      body: Column(
        children: [
          _ProfileHeader(context: context, s: s),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const _ProfileAvatar(),
                  const SizedBox(height: 16),
                  _ContribStats(s: s),
                  const SizedBox(height: 16),
                  _LanguageSelector(s: s),
                  const SizedBox(height: 16),
                  _ThemeSelector(s: s),
                  const SizedBox(height: 16),
                  _MenuSection(context: context, s: s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final BuildContext context;
  final S s;
  const _ProfileHeader({required this.context, required this.s});

  @override
  Widget build(BuildContext _) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        children: [
          Text(s.profileTitle,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const Spacer(),
          const Icon(Icons.settings_outlined,
              color: Colors.white70, size: 22),
        ],
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _ProfileAvatar extends ConsumerWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tc.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('JB',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF15803D),
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2)),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Jean-Baptiste M.',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.tc.textPrimary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(s.verifiedBadge,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3730A3),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Stats ────────────────────────────────────────────────────────────────────

class _ContribStats extends StatelessWidget {
  final S s;
  const _ContribStats({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tc.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _StatItem(value: '24', label: s.statContribs),
          _divider(context),
          _StatItem(value: '18', label: s.statValidated),
          _divider(context),
          _StatItem(value: '142', label: s.statPoints),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) =>
      Container(height: 32, width: 1, color: context.tc.border);
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: context.tc.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Language Selector ────────────────────────────────────────────────────────

class _LanguageSelector extends ConsumerWidget {
  final S s;
  const _LanguageSelector({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(localeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tc.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.languageTitle,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.tc.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: AppLang.values.map((lang) {
              final isSelected = currentLang == lang;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      ref.read(localeProvider.notifier).setLang(lang),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : context.tc.inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(lang.flag,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          lang.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : context.tc.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Theme Selector ───────────────────────────────────────────────────────────

class _ThemeSelector extends ConsumerWidget {
  final S s;
  const _ThemeSelector({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    Widget option(IconData icon, String label, ThemeMode mode,
        VoidCallback onTap) {
      final isSelected = themeMode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : context.tc.inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 20,
                    color:
                        isSelected ? Colors.white : context.tc.textSecondary),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white : context.tc.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tc.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.themeTitle,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.tc.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              option(
                Icons.light_mode,
                s.themeLight,
                ThemeMode.light,
                () => ref.read(themeModeProvider.notifier).setLight(),
              ),
              option(
                Icons.dark_mode,
                s.themeDark,
                ThemeMode.dark,
                () => ref.read(themeModeProvider.notifier).setDark(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Menu Section ─────────────────────────────────────────────────────────────

class _MenuSection extends ConsumerWidget {
  final BuildContext context;
  final S s;
  const _MenuSection({required this.context, required this.s});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: ctx.tc.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.dashboard_outlined,
            iconColor: AppColors.primary,
            iconBg: const Color(0xFFEFF6FF),
            label: s.menuDashboard,
            onTap: () => context.push('/admin'),
            isFirst: true,
          ),
          Divider(height: 1, indent: 56, color: ctx.tc.border),
          _MenuItem(
            icon: Icons.history,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFF5F3FF),
            label: s.menuMyContribs,
            onTap: () => ref.read(tabProvider.notifier).go(NavTab.contribute),
          ),
          Divider(height: 1, indent: 56, color: ctx.tc.border),
          _MenuItem(
            icon: Icons.help_outline,
            iconColor: const Color(0xFF0EA5E9),
            iconBg: const Color(0xFFEFF6FF),
            label: s.menuHowTo,
            onTap: () => _showHowTo(ref),
          ),
          Divider(height: 1, indent: 56, color: ctx.tc.border),
          _MenuItem(
            icon: Icons.logout,
            iconColor: const Color(0xFFDC2626),
            iconBg: const Color(0xFFFEF2F2),
            label: s.menuLogout,
            onTap: () => _confirmLogout(ref),
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _showHowTo(WidgetRef ref) {
    final s = ref.read(stringsProvider);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.howToTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _HowToStep(text: s.howToStep1),
              const SizedBox(height: 10),
              _HowToStep(text: s.howToStep2),
              const SizedBox(height: 10),
              _HowToStep(text: s.howToStep3),
              const SizedBox(height: 14),
              Text(s.howToNote,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF8E8E93))),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(WidgetRef ref) {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.logoutTitle),
        content: Text(s.logoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(tabProvider.notifier).go(NavTab.map);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: Text(s.menuLogout),
          ),
        ],
      ),
    );
  }
}

class _HowToStep extends StatelessWidget {
  final String text;
  const _HowToStep({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline,
            size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.tc.textPrimary)),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: context.tc.textTertiary),
          ],
        ),
      ),
    );
  }
}
