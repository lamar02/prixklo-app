import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/product_model.dart';
import '../../../../modules/notifications/controllers/notifications_controller.dart';
import '../../../../routes/app_routes.dart';
import '../../controllers/verify_controller.dart';

class Screen1Search extends GetView<VerifyController> {
  const Screen1Search({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── AppBar manuel (pas de back) ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Vérifier un prix',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral100,
                    ),
                  ),
                ),
                Obx(() {
                  final notifCtrl = Get.find<NotificationsController>();
                  final count = notifCtrl.unreadCount;
                  return IconButton(
                    onPressed: () => Get.toNamed(AppRoutes.notifications),
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text(count > 9 ? '9+' : '$count'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                  );
                }),
              ],
            ),
          ),
          // ── Recherche ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => controller.searchQuery.value = v,
            ),
          ),
          // ── Liste produits ────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.productsLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final products = controller.filteredProducts;
              if (products.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun produit trouvé',
                    style: TextStyle(color: AppColors.neutral60),
                  ),
                );
              }
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (_, i) => _ProductTile(product: products[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<VerifyController>();
    return Obx(() {
      final selected = ctrl.selectedProduct.value?.id == product.id;
      return ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withAlpha(25) : AppColors.neutral10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.neutral60,
              ),
            ),
          ),
        ),
        title: Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(product.category,
            style: const TextStyle(fontSize: 12, color: AppColors.neutral60)),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
        onTap: () => ctrl.selectProduct(product),
      );
    });
  }
}
