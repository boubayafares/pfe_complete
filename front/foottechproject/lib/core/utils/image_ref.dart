import 'dart:io';

import 'package:flutter/painting.dart';

import 'media_url.dart';

/// Resolves a stored image reference (a local file path from SQLite, or a
/// network URL from the old backend) into a usable [ImageProvider]. Used to
/// render avatars offline without assuming the file came from a server.
class ImageRef {
  ImageRef._();

  static bool isLocal(String? path) {
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('http://') || path.startsWith('https://')) return false;
    if (path.startsWith('file://')) return true;
    // Remote backend static assets (served under /uploads) are network URLs.
    if (path.startsWith('/uploads/')) return false;
    // Absolute filesystem paths (Windows drive letters, POSIX root, etc.)
    return path.contains(RegExp(r'^[A-Za-z]:[\\/]')) ||
        path.startsWith('/') ||
        path.startsWith('~');
  }

  static ImageProvider? resolve(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('file://')) {
      return FileImage(File(path.replaceFirst('file://', '')));
    }
    if (isLocal(path)) {
      return FileImage(File(path));
    }
    final url = MediaUrl.resolve(path);
    if (url == null) return null;
    return NetworkImage(url);
  }
}
