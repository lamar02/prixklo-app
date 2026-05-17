import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/storage_service.dart';
import '../../map/views/map_view.dart';
import '../../profile/views/profile_view.dart';
import '../../verify/views/verify_view.dart';
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
              VerifyView(),
              MapView(),
              ProfileView(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            onTap: controller.changeTab,
            items: [
              BottomNavigationBarItem(
                icon: Obx(() {
                  final count = storage.pendingCount.value;
                  if (count == 0) {
                    return const Icon(Icons.search_rounded);
                  }
                  return Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.search_rounded),
                  );
                }),
                activeIcon: Obx(() {
                  final count = storage.pendingCount.value;
                  if (count == 0) {
                    return const Icon(Icons.search_rounded);
                  }
                  return Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.search_rounded),
                  );
                }),
                label: 'Vérifier',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Carte',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Moi',
              ),
            ],
          ),
        ));
  }
}
