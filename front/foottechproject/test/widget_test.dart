import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foottechproject/main.dart';
import 'package:foottechproject/core/providers.dart';
import 'package:foottechproject/core/storage/token_storage.dart';

/// In-memory fake for flutter_secure_storage so the app can boot in tests
/// without platform channels. No persisted session => onboarding shows.
class _MemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.remove(key);

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => Map.of(_store);
}

void main() {
  testWidgets('FootTech boots to onboarding when no session exists', (
    tester,
  ) async {
    final storage = TokenStorage(storage: _MemorySecureStorage());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(storage)],
        child: const FootTechApp(),
      ),
    );

    // Let the router resolve the initial /onboarding route and restoreSession
    // complete (returns null -> not logged in -> onboarding is shown).
    await tester.pumpAndSettle();

    expect(find.text('FootTech'), findsOneWidget);
    expect(find.text('New club? Create a Coach account'), findsOneWidget);
    expect(find.text('I am a Coach or Assistant'), findsOneWidget);
    expect(find.text('I am a Player (SMS login)'), findsOneWidget);
  });
}
