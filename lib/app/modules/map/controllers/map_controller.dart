import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:get/get.dart';
import '../../../data/models/map_marker_model.dart';
import '../../../services/api_service.dart';
import '../views/widgets/map_marker_sheet.dart';

class MapController extends GetxController {
  final _api = Get.find<ApiService>();

  /// Contrôleur flutter_map pour le zoom programmatique
  final mapCtrl = flutter_map.MapController();

  final RxList<MapMarkerModel> markers = <MapMarkerModel>[].obs;
  final RxBool onlyAbus = false.obs;
  final RxBool isLoading = false.obs;
  final Rx<MapMarkerModel?> selectedMarker = Rx<MapMarkerModel?>(null);

  static const defaultLat = 5.3599517;
  static const defaultLng = -4.0082563;

  @override
  void onInit() {
    super.onInit();
    fetchMarkers();
    ever(onlyAbus, (_) => fetchMarkers());
    ever(selectedMarker, (MapMarkerModel? m) {
      if (m != null) _showMarkerSheet(m);
    });
  }

  void _showMarkerSheet(MapMarkerModel m) {
    Get.bottomSheet(
      MapMarkerSheet(marker: m),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
    ).whenComplete(() => selectedMarker.value = null);
  }

  Future<void> fetchMarkers() async {
    isLoading.value = true;
    try {
      final res = await _api.getMapMarkers(onlyAbus: onlyAbus.value);
      if (res.isOk) {
        // Filtrer les signalements sans coordonnées GPS avant le parsing
        markers.value = (res.body['markers'] as List)
            .cast<Map<String, dynamic>>()
            .where((m) => m['lat'] != null && m['lng'] != null)
            .map((m) => MapMarkerModel.fromJson(m))
            .toList();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void onMarkerTap(MapMarkerModel marker) {
    selectedMarker.value = marker;
  }

  void toggleOnlyAbus(bool value) => onlyAbus.value = value;

  void zoomIn() {
    try {
      final cam = mapCtrl.camera;
      mapCtrl.move(cam.center, cam.zoom + 1);
    } catch (_) {}
  }

  void zoomOut() {
    try {
      final cam = mapCtrl.camera;
      mapCtrl.move(cam.center, cam.zoom - 1);
    } catch (_) {}
  }

  @override
  void onClose() {
    mapCtrl.dispose();
    super.onClose();
  }
}
