import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/product_model.dart';
import '../../controllers/report_controller.dart';

class Step1ProductView extends GetView<ReportController> {
  const Step1ProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => controller.searchQuery.value = v,
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.productsLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = controller.filteredProducts;
            if (products.isEmpty) {
              return const Center(
                child: Text('Aucun produit trouvé',
                    style: TextStyle(color: AppColors.neutral60)),
              );
            }
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, i) => _ProductTile(product: products[i]),
            );
          }),
        ),
        // Packaging sélection
        Obx(() {
          final product = controller.selectedProduct.value;
          if (product == null) return const SizedBox.shrink();
          return Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conditionnement — ${product.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral100,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: product.packagings
                      .map((p) => Obx(() => ChoiceChip(
                            label: Text(p.label),
                            selected:
                                controller.selectedPackaging.value?.id == p.id,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color:
                                  controller.selectedPackaging.value?.id == p.id
                                      ? Colors.white
                                      : AppColors.neutral100,
                            ),
                            onSelected: (_) => controller.selectPackaging(p),
                          )))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Obx(() => ElevatedButton(
                      onPressed: controller.selectedPackaging.value != null
                          ? () => controller.goToStep(1)
                          : null,
                      child: const Text('Suivant'),
                    )),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ProductTile extends GetView<ReportController> {
  final ProductModel product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedProduct.value?.id == product.id;
      return ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                selected ? AppColors.primary.withAlpha(25) : AppColors.neutral10,
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
            style: const TextStyle(
                fontSize: 12, color: AppColors.neutral60)),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
        onTap: () => controller.selectProduct(product),
      );
    });
  }
}
