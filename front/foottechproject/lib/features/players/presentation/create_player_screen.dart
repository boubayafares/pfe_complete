import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import 'players_provider.dart';

class CreatePlayerScreen extends ConsumerStatefulWidget {
  const CreatePlayerScreen({super.key});

  @override
  ConsumerState<CreatePlayerScreen> createState() => _CreatePlayerScreenState();
}

class _CreatePlayerScreenState extends ConsumerState<CreatePlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _numeroController = TextEditingController();
  String? _poste;
  String? _piedFort;
  bool _submitting = false;

  static const _postes = [
    'GB',
    'DC',
    'DD',
    'DG',
    'MDC',
    'MC',
    'MOC',
    'AD',
    'AG',
    'ST',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final teamId = ref.read(authControllerProvider).value?.teamId;
    if (teamId == null) return;
    setState(() => _submitting = true);
    try {
      final player = await ref
          .read(playersRepositoryProvider)
          .create(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _phoneController.text.trim(),
            posteP: _poste,
            piedFort: _piedFort,
            numeroMaillot: int.tryParse(_numeroController.text.trim()),
          );
      ref.invalidate(teamPlayersProvider);
      if (mounted) context.pushReplacement('/players/${player.id}');
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.newPlayer)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.firstName,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? context.l10n.required : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.lastName,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? context.l10n.required : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: context.l10n.phoneSmsActivation,
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? context.l10n.invalidNumber
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _poste,
                    decoration: InputDecoration(
                      labelText: context.l10n.primaryPosition,
                    ),
                    items: _postes
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) => setState(() => _poste = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _piedFort,
                    decoration: InputDecoration(
                      labelText: context.l10n.strongFoot,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'DROIT',
                        child: Text(context.l10n.right),
                      ),
                      DropdownMenuItem(
                        value: 'GAUCHE',
                        child: Text(context.l10n.left),
                      ),
                      DropdownMenuItem(
                        value: 'AMBIDEXTRE',
                        child: Text(context.l10n.ambidextrous),
                      ),
                    ],
                    onChanged: (value) => setState(() => _piedFort = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _numeroController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.jerseyNumber,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.greenTextOnFill,
                            ),
                          )
                        : Text(context.l10n.createPlayer),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
