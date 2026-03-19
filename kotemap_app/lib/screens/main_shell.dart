import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/map/presentation/screens/map_screen.dart';
import '../features/map/presentation/widgets/bottom_nav_bar.dart';
import '../features/contribute/presentation/screens/contribute_screen.dart';
import '../core/providers/tab_provider.dart';
import '../core/i18n/app_strings.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    MapScreen(),
    AlertsScreen(),
    ContributeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(tabProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentTab.index,
        children: _screens,
      ),
      bottomNavigationBar: KoteBottomNavBar(
        currentTab: currentTab,
        labels: [s.tabMap, s.tabAlerts, s.tabContribute, s.tabProfile],
        onTabChanged: (tab) => ref.read(tabProvider.notifier).go(tab),
      ),
    );
  }
}
