import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

/// Biometric unlock wrapper. local_auth has no meaningful implementation on
/// Web and only partial support on Windows/Linux, so [isAvailable] is
/// checked defensively and every call fails OPEN (never blocks the user)
/// if the platform can't do it or throws — this is a convenience UX layer
/// on top of JWT auth, not the actual security boundary.
class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get isAvailable async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Unlock FootTech'}) async {
    try {
      if (!await isAvailable) return true;
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
  /// FAILLE CORRIGÉE: `catch (_) { return true; }` traitait toute exception
  /// levée pendant une tentative d'authentification RÉELLE comme un succès
  /// — pas seulement l'absence de matériel biométrique. Le plugin local_auth
  /// lève des PlatformException dans plusieurs cas qui n'ont rien à voir
  /// avec "cet appareil n'a pas de biométrie" (capteur occupé, état
  /// `lockedOut` après plusieurs échecs, ROM custom, etc.) : quelqu'un en
  /// possession physique du téléphone n'avait donc, dans ces cas, RIEN à
  /// prouver pour voir les données du club — l'écran de verrouillage
  /// s'ouvrait tout seul sur une erreur. On distingue maintenant :
  /// "pas de biométrie disponible" (fail open, comportement voulu, géré en
  /// amont par isAvailable) vs "une tentative d'authentification a échoué
  /// ou a levé une erreur" (fail CLOSED — reste verrouillé, l'utilisateur
  /// peut réessayer via le bouton "Déverrouiller").

}


