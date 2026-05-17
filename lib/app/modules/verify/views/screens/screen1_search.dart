import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/product_model.dart';
import '../../../../modules/auth/controllers/auth_controller.dart';
import '../../../../modules/notifications/controllers/notifications_controller.dart';
import '../../../../routes/app_routes.dart';
import '../../controllers/verify_controller.dart';
import '../widgets/packaging_sheet.dart';

class Screen1Search extends GetView<VerifyController> {
  const Screen1Search({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              children: [
                // Ligne 1 : logo + cloche
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/logo/app_icon.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Priclo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Obx(() {
                      final notifCtrl = Get.find<NotificationsController>();
                      final count = notifCtrl.unreadCount;
                      return IconButton(
                        onPressed: () =>
                            Get.toNamed(AppRoutes.notifications),
                        icon: Badge(
                          isLabelVisible: count > 0,
                          label: Text(count > 9 ? '9+' : '$count'),
                          child: const Icon(Icons.notifications_outlined),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 14),
                // Ligne 2 : salutation + avatar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Obx(() {
                        final user =
                            Get.find<AuthController>().user.value;
                        final firstName =
                            user?.name.split(' ').first ?? 'Citoyen';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour, $firstName 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.neutral100,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Vérifiez les prix autour de vous',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.neutral60,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    // Avatar initiale
                    Obx(() {
                      final name =
                          Get.find<AuthController>().user.value?.name ?? '';
                      return Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
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
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
        onTap: () {
          ctrl.selectProduct(product);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const PackagingSheet(),
          );
        },
      );
    });
  }
}
