import 'package:get/get.dart';
import '../controllers/price_check_controller.dart';

class PriceCheckBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PriceCheckController>(() => PriceCheckController());
  }
}
