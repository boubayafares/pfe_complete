import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Dio wrapper shared by every repository: attaches the JWT to every
/// request, and on 401 tries exactly one silent refresh-and-retry before
/// clearing the session and firing [onSessionExpired]. Platform-agnostic —
/// Dio's default (IO) HttpClientAdapter is swapped for a browser adapter
/// automatically on Web by the dio package itself, no code changes needed.
class ApiClient {
  ApiClient({required TokenStorage tokenStorage, this.onSessionExpired})
      : _tokenStorage = tokenStorage,
        _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.accessToken;
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRefreshCall = error.requestOptions.path.contains('/auth/refresh');

          if (isUnauthorized && !isRefreshCall) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              try {
                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              } catch (_) {
                // fall through to session-expired handling below
              }
            }
            await _tokenStorage.clear();
            onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final void Function()? onSessionExpired;

  // BUG CORRIGÉ (race condition): un écran qui déclenche plusieurs appels
  // en parallèle (ex: dashboard qui charge stats + notifications + équipe
  // en même temps) peut recevoir plusieurs 401 quasi simultanés si
  // l'access token vient d'expirer. Chacun appelait _tryRefresh()
  // indépendamment avec le MÊME refreshToken lu en mémoire ; côté backend,
  // le refresh token est à usage unique (rotation) — la première requête
  // le consomme et en reçoit un nouveau, la ou les suivantes échouent avec
  // un refreshToken déjà révoqué et déconnectaient l'utilisateur alors que
  // sa session venait pourtant d'être rafraîchie avec succès une ligne plus
  // tôt. On ne garde plus qu'un seul refresh "en vol" : tous les 401
  // concurrents attendent le même Future et partagent son résultat.
  Future<bool>? _inFlightRefresh;

  Future<bool> _tryRefresh() {
    return _inFlightRefresh ??= _doRefresh().whenComplete(() => _inFlightRefresh = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _tokenStorage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await _dio.post('${ApiConstants.auth}/refresh', data: {'refreshToken': refreshToken});
      final data = response.data['data'] as Map<String, dynamic>;
      await _tokenStorage.saveTokens(accessToken: data['accessToken'] as String, refreshToken: data['refreshToken'] as String);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _request(() => _dio.get(path, queryParameters: queryParameters));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, {Object? data}) async {
    final response = await _request(() => _dio.post(path, data: data));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patch(String path, {Object? data}) async {
    final response = await _request(() => _dio.patch(path, data: data));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(String path, {Object? data}) async {
    final response = await _request(() => _dio.put(path, data: data));
    return response.data as Map<String, dynamic>;
  }

  /// Uploads a single file as multipart/form-data. On Web, pass [bytes]
  /// (from image_picker's XFile.readAsBytes()) since there is no real
  /// filesystem path to read from; on other platforms pass [filePath].
  Future<Map<String, dynamic>> uploadFile(
      String path, {
        required String fieldName,
        String? filePath,
        List<int>? bytes,
        String? fileName,
      }) async {
    assert(filePath != null || bytes != null, 'Provide either filePath or bytes');
    // Derive the file name from the explicit name, or the basename of the path.
    final name = fileName ??
        (bytes != null ? 'upload' : (filePath ?? '').split(RegExp(r'[\\/]')).last);
    // MUST set the part content-type: the backend multer fileFilter only accepts
    // image/jpeg|png|webp. Without it Dio defaults the part to
    // application/octet-stream and the backend rejects the upload with 400.
    final mime = _mimeFromName(name);
    final contentType = DioMediaType.parse(mime);
    final multipartFile = bytes != null
        ? MultipartFile.fromBytes(bytes, filename: name, contentType: contentType)
        : await MultipartFile.fromFile(filePath!, filename: name, contentType: contentType);
    final formData = FormData.fromMap({fieldName: multipartFile});
    final response = await _request(() => _dio.post(path, data: formData));
    return response.data as Map<String, dynamic>;
  }

  static String _mimeFromName(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> delete(String path, {Object? data}) async {
    await _request(() => _dio.delete(path, data: data));
  }

  Future<Response> _request(Future<Response> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ApiException _mapError(DioException error) {
    final response = error.response;
    if (response?.data is Map<String, dynamic>) {
      final body = response!.data as Map<String, dynamic>;
      return ApiException(
        message: body['message'] as String? ?? 'An error occurred',
        statusCode: response.statusCode,
        details: body['details'],
      );
    }
    return ApiException(message: error.message ?? 'Unable to reach the server', statusCode: error.response?.statusCode);
  }
}
