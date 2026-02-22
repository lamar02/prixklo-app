import 'package:get/get.dart';
import 'storage_service.dart';

class ApiService extends GetConnect {
  static const _base = 'https://prixklobackend.vercel.app/api';

  @override
  void onInit() {
    httpClient.baseUrl = _base;
    httpClient.timeout = const Duration(seconds: 8);

    httpClient.addRequestModifier<dynamic>((request) {
      final token = Get.find<StorageService>().token;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });

    httpClient.addResponseModifier((request, response) async {
      if (response.statusCode == 401) {
        await Get.find<StorageService>().clearToken();
        Get.offAllNamed('/login');
      }
      return response;
    });
  }

  // ── Auth ────────────────────────────────────────────────
  Future<Response> register(String name, String email, String password) =>
      post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });

  Future<Response> login(String email, String password) =>
      post('/auth/login', {'email': email, 'password': password});

  Future<Response> getMe() => get('/auth/me');

  // ── Catalogue ────────────────────────────────────────────
  Future<Response> getProducts() => get('/products');

  Future<Response> getActivePrices({String zone = 'ABIDJAN_30KM'}) =>
      get('/official-prices/active', query: {'zone': zone});

  // ── Signalements ─────────────────────────────────────────
  Future<Response> createReport(Map<String, dynamic> body) =>
      post('/reports', body);

  Future<Response> createReportWithPhoto(
    Map<String, String> fields,
    String photoPath,
  ) {
    final form = FormData({
      ...fields,
      'photo': MultipartFile(photoPath, filename: 'photo.jpg'),
    });
    return post('/reports', form);
  }

  Future<Response> getMyReports({int page = 1}) =>
      get('/reports/mine', query: {'page': page.toString()});

  Future<Response> getMapMarkers({bool onlyAbus = false}) =>
      get('/reports/map', query: {'onlyAbus': onlyAbus.toString()});

  // ── Gamification ─────────────────────────────────────────
  Future<Response> getGamification() => get('/gamification/me');

  Future<Response> getLeaderboard({String? period}) => get(
        '/leaderboard',
        query: period != null ? {'period': period} : {},
      );
}
