import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String kCustomBaseUrlKey = 'custom_base_url';
  static const String defaultBaseUrl = 'http://127.0.0.1:8000/api';

  late final Dio dio = _buildDio();

  Dio _buildDio() {
    final d = Dio(BaseOptions(
      baseUrl: defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'X-Pinggy-No-Screen': 'true',
      },
    ));
    d.interceptors.add(_AuthInterceptor());
    return d;
  }

  /// Инициализирует сохранённый baseUrl из SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(kCustomBaseUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      dio.options.baseUrl = savedUrl;
    }
  }

  /// Обновляет baseUrl и сохраняет его в SharedPreferences.
  /// Автоматически подставляет https:// для ngrok/pinggy доменов
  /// и http:// для IP-адресов локальной сети.
  Future<String> setBaseUrl(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      cleanUrl = defaultBaseUrl;
    } else {
      final isTunnel = cleanUrl.contains('ngrok') ||
          cleanUrl.contains('pinggy') ||
          cleanUrl.contains('lhr.life') ||
          cleanUrl.startsWith('https://');

      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = isTunnel ? 'https://$cleanUrl' : 'http://$cleanUrl';
      }

      if (!cleanUrl.endsWith('/api')) {
        if (cleanUrl.endsWith('/')) {
          cleanUrl = '${cleanUrl}api';
        } else {
          cleanUrl = '$cleanUrl/api';
        }
      }
    }
    dio.options.baseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kCustomBaseUrlKey, cleanUrl);
    return cleanUrl;
  }

  /// Получить текущий baseUrl
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kCustomBaseUrlKey) ?? dio.options.baseUrl;
  }
}

/// Автоматически синхронизирует актуальный baseUrl, подставляет Bearer-токен
/// и обязательные заголовки обхода HTML-заглушек туннелей (ngrok, pinggy).
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(ApiClient.kCustomBaseUrlKey);
    if (customUrl != null && customUrl.isNotEmpty) {
      options.baseUrl = customUrl;
    }

    // Пропуск предупреждений браузера для бесплатных туннелей
    options.headers['ngrok-skip-browser-warning'] = 'true';
    options.headers['X-Pinggy-No-Screen'] = 'true';

    final token = prefs.getString('access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Convenience shortcut.
Dio get dio => ApiClient.instance.dio;
