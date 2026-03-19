import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/map/presentation/widgets/bottom_nav_bar.dart';

class TabNotifier extends Notifier<NavTab> {
  @override
  NavTab build() => NavTab.map;

  void go(NavTab tab) => state = tab;
}

final tabProvider =
    NotifierProvider<TabNotifier, NavTab>(TabNotifier.new);
