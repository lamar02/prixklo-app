import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/storage_service.dart';
import '../../home/views/home_view.dart';
import '../../map/views/map_view.dart';
import '../../profile/views/profile_view.dart';
import '../../report/views/report_view.dart';
import '../controllers/main_nav_controller.dart';

class MainNavView extends GetView<MainNavController> {
  const MainNavView({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();
    return Obx(() => Scaffold(
          body: IndexedStack(
            index: controller.selectedIndex.value,
            children: const [
              HomeView(),
              MapView(),
              ReportView(),
              ProfileView(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            onTap: controller.changeTab,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Carte',
              ),
              BottomNavigationBarItem(
                icon: Obx(() {
                  final count = storage.pendingCount.value;
                  if (count == 0) return const Icon(Icons.add_circle_outline);
                  return Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.add_circle_outline),
                  );
                }),
                activeIcon: Obx(() {
                  final count = storage.pendingCount.value;
                  if (count == 0) return const Icon(Icons.add_circle);
                  return Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.add_circle),
                  );
                }),
                label: 'Signaler',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ));
  }
}
