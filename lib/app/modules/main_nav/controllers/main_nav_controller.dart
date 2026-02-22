import 'package:get/get.dart';

class MainNavController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changeTab(int index) => selectedIndex.value = index;

  void goToReport() => selectedIndex.value = 2;
}
