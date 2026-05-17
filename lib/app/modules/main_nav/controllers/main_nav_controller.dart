import 'package:get/get.dart';

class MainNavController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changeTab(int index) => selectedIndex.value = index;

  // 0 = Vérifier, 1 = Carte, 2 = Moi
  void goToVerify() => selectedIndex.value = 0;
  void goToMap() => selectedIndex.value = 1;
}
