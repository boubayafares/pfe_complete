import '../constants/api_constants.dart';

/// The backend stores avatars/documents as relative paths (e.g.
/// "/uploads/abc123.jpg", served statically from app.ts). This is the one
/// place that knows how to build an absolute URL from that.
class MediaUrl {
  MediaUrl._();

  static String? resolve(String? relativeOrAbsolute) {
    if (relativeOrAbsolute == null || relativeOrAbsolute.isEmpty) return null;
    if (relativeOrAbsolute.startsWith('http://') ||
        relativeOrAbsolute.startsWith('https://')) {
      return relativeOrAbsolute;
    }
    final path = relativeOrAbsolute.startsWith('/')
        ? relativeOrAbsolute
        : '/$relativeOrAbsolute';
    return '${ApiConstants.baseUrl}$path';
  }
}
