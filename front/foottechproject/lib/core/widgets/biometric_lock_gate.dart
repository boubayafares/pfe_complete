import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/localization.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../../features/auth/presentation/auth_provider.dart';

/// Wraps the whole app. On cold start, if a cached session is restored
/// (no fresh password/OTP entry), asks for a biometric check once before
/// revealing club data. Fails open on Web/unsupported platforms/devices
/// with no biometrics enrolled — see LocalAuthService.
class BiometricLockGate extends ConsumerStatefulWidget {
  const BiometricLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends ConsumerState<BiometricLockGate> {
  bool _locked = false;
  bool _coldStartChecked = false;
  ProviderSubscription<AsyncValue<dynamic>>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCheckColdStart());
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  void _maybeCheckColdStart() {
    if (_coldStartChecked) return;
    final authState = ref.read(authControllerProvider);

    if (!authState.isLoading) {
      _coldStartChecked = true;
      if (authState.value != null) _lockAndAuthenticate();
      return;
    }

    _subscription = ref.listenManual<AsyncValue<dynamic>>(authControllerProvider, (previous, next) {
      if (_coldStartChecked || next.isLoading) return;
      _coldStartChecked = true;
      if (next.value != null) _lockAndAuthenticate();
      _subscription?.close();
    });
  }

  Future<void> _lockAndAuthenticate() async {
    if (!mounted) return;
    setState(() => _locked = true);
    final unlocked = await ref.read(localAuthServiceProvider).authenticate();
    if (mounted) setState(() => _locked = !unlocked);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: Container(
              color: AppColors.navyBg,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fingerprint, size: 56, color: AppColors.green),
                    const SizedBox(height: AppSpacing.md),
                    Text(context.l10n.biometricLocked, style: const TextStyle(color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(onPressed: _lockAndAuthenticate, child: Text(context.l10n.unlock)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
