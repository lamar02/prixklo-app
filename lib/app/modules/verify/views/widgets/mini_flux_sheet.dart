import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/verify_controller.dart';

class MiniFluxSheet extends GetView<VerifyController> {
  const MiniFluxSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral20,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quelques détails (optionnel)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral100,
            ),
          ),
          const SizedBox(height: 16),
          // ── Nom de l'enseigne ──────────────────────────────
          TextField(
            decoration: const InputDecoration(
              hintText: 'Ex : Marché de Cocody, Supermarché Hayat…',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            onChanged: (v) => controller.shopName.value = v,
          ),
          const SizedBox(height: 12),
          // ── Photo ─────────────────────────────────────────
          Obx(() {
            final f = controller.photo.value;
            if (f != null) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(f,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => controller.photo.value = null,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            }
            return OutlinedButton.icon(
              onPressed: () => _pickPhoto(context),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Ajouter une photo'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            );
          }),
          const SizedBox(height: 20),
          // ── Bouton Envoyer ────────────────────────────────
          Obx(() => ElevatedButton.icon(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await controller.submitReport();
                      },
                icon: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(controller.isSubmitting.value
                    ? 'Envoi en cours…'
                    : 'Envoyer'),
              )),
        ],
      ),
    );
  }

  void _pickPhoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Caméra'),
              onTap: () {
                Navigator.of(context).pop();
                controller.takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.of(context).pop();
                controller.pickPhoto();
              },
            ),
          ],
        ),
      ),
    );
  }
}
