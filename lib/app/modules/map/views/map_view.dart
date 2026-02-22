import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide MapController;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/map_marker_model.dart';
import '../controllers/map_controller.dart' as app_map;
// Alias to avoid conflict with flutter_map's MapController
typedef AppMapController = app_map.MapController;

class MapView extends GetView<AppMapController> {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                  AppMapController.defaultLat, AppMapController.defaultLng),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ci.prixklo.app',
              ),
              Obx(() => MarkerLayer(
                    markers: controller.markers
                        .map((m) => _buildMarker(m))
                        .toList(),
                  )),
            ],
          ),
          // Switch Abus seulement
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Abus uniquement',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral100),
                  ),
                  Obx(() => Switch.adaptive(
                        value: controller.onlyAbus.value,
                        thumbColor: WidgetStateProperty.all(AppColors.abus),
                        onChanged: controller.toggleOnlyAbus,
                      )),
                ],
              ),
            ),
          ),
          // Indicateur de chargement
          Obx(() => controller.isLoading.value
              ? const Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Marker _buildMarker(MapMarkerModel m) {
    final isAbus = m.status == 'ABUS';
    return Marker(
      point: LatLng(m.lat, m.lng),
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: () => controller.onMarkerTap(m),
        child: Container(
          decoration: BoxDecoration(
            color: isAbus ? AppColors.abus : AppColors.success,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 4,
                  offset: Offset(0, 2))
            ],
          ),
          child: Icon(
            isAbus ? Icons.warning_rounded : Icons.check_circle,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
