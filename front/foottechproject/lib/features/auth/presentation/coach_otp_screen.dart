import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_provider.dart';

/// Confirms a freshly-registered (or INACTIVE) Coach / Adjoint via OTP.
/// The [email] is passed from the registration/login flow.
class CoachOtpScreen extends ConsumerStatefulWidget {
  const CoachOtpScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<CoachOtpScreen> createState() => _CoachOtpScreenState();
}

class _CoachOtpScreenState extends ConsumerState<CoachOtpScreen> {
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _sendingCode = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _sendingCode = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestCoachOtp(email: widget.email);
      if (mounted) setState(() => _codeSent = true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    await ref
        .read(authControllerProvider.notifier)
        .verifyCoachOtp(email: widget.email, code: _codeController.text.trim());
    final state = ref.read(authControllerProvider);
    if (state.hasError && mounted) {
      final error = state.error;
      final message = error is ApiException
          ? error.message
          : context.l10n.invalidCode;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } else if (mounted && state.value != null) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerifying = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.otpTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _codeSent
                      ? context.l10n.otpCodeSentEmail(widget.email)
                      : context.l10n.otpWillSendEmail(widget.email),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _codeController,
                  enabled: _codeSent,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, letterSpacing: 6),
                  decoration: const InputDecoration(hintText: '000000'),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _codeSent
                      ? (isVerifying ? null : _verifyCode)
                      : (_sendingCode ? null : _sendCode),
                  child: (_sendingCode || isVerifying)
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.greenTextOnFill,
                          ),
                        )
                      : Text(
                          _codeSent
                              ? context.l10n.verifyAndActivate
                              : context.l10n.receiveNewCode,
                        ),
                ),
                if (_codeSent)
                  TextButton(
                    onPressed: () => setState(() => _codeSent = false),
                    child: Text(
                      context.l10n.receiveNewCode,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
