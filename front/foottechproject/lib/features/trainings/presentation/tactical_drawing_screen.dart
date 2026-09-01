import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/localization.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import 'trainings_provider.dart';

class PlayerToken {
  PlayerToken({required this.id, required this.x, required this.y});
  final int id;
  double x; // 0..1 relative to pitch width
  double y; // 0..1 relative to pitch height

  factory PlayerToken.fromJson(Map<String, dynamic> json) => PlayerToken(
        id: json['id'] as int,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'x': x, 'y': y};
}

class TacticalDrawingScreen extends ConsumerStatefulWidget {
  const TacticalDrawingScreen({super.key, required this.trainingId, required this.situationId});

  final int trainingId;
  final int situationId;

  @override
  ConsumerState<TacticalDrawingScreen> createState() => _TacticalDrawingScreenState();
}

class _TacticalDrawingScreenState extends ConsumerState<TacticalDrawingScreen> {
  List<PlayerToken> _tokens = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(trainingsRepositoryProvider).getDrawing(widget.trainingId, widget.situationId);
      final playersJson = data?['players'] as List<dynamic>?;
      setState(() {
        _tokens = playersJson?.map((p) => PlayerToken.fromJson(p as Map<String, dynamic>)).toList() ??
            _defaultFormation();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _tokens = _defaultFormation();
        _loading = false;
      });
    }
  }

  List<PlayerToken> _defaultFormation() {
    // A simple 4-3-3 spread, purely as a starting layout the coach can drag from.
    const positions = [
      [0.5, 0.92], // GK
      [0.15, 0.72], [0.38, 0.75], [0.62, 0.75], [0.85, 0.72], // defense
      [0.25, 0.5], [0.5, 0.48], [0.75, 0.5], // midfield
      [0.2, 0.2], [0.5, 0.12], [0.8, 0.2], // attack
    ];
    return [for (var i = 0; i < positions.length; i++) PlayerToken(id: i + 1, x: positions[i][0], y: positions[i][1])];
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(trainingsRepositoryProvider).saveDrawing(widget.trainingId, widget.situationId, {
        'players': _tokens.map((t) => t.toJson()).toList(),
        'arrows': <dynamic>[],
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.diagramSaved)));
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tacticalDiagram),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Keep a football-pitch aspect ratio (roughly 2:3) regardless
                  // of platform window size — phones, tablets, and desktop
                  // windows all get a proportionally correct pitch.
                  final width = constraints.maxWidth;
                  final height = (width * 1.5).clamp(0, constraints.maxHeight).toDouble();

                  return Center(
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        children: [
                          CustomPaint(size: Size(width, height), painter: _PitchPainter()),
                          for (final token in _tokens)
                            Positioned(
                              left: token.x * width - 16,
                              top: token.y * height - 16,
                              child: _DraggableToken(
                                token: token,
                                pitchWidth: width,
                                pitchHeight: height,
                                onMoved: (dx, dy) => setState(() {
                                  token.x = (token.x + dx / width).clamp(0.0, 1.0);
                                  token.y = (token.y + dy / height).clamp(0.0, 1.0);
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _DraggableToken extends StatelessWidget {
  const _DraggableToken({required this.token, required this.pitchWidth, required this.pitchHeight, required this.onMoved});

  final PlayerToken token;
  final double pitchWidth;
  final double pitchHeight;
  final void Function(double dx, double dy) onMoved;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onMoved(details.delta.dx, details.delta.dy),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text('${token.id}', style: const TextStyle(color: AppColors.greenTextOnFill, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFF16382A);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fill);
    canvas.drawRect(Rect.fromLTWH(4, 4, size.width - 8, size.height - 8), line);
    canvas.drawLine(Offset(4, size.height / 2), Offset(size.width - 4, size.height / 2), line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.14, line);

    // Goal boxes (top and bottom)
    final boxWidth = size.width * 0.5;
    canvas.drawRect(Rect.fromLTWH((size.width - boxWidth) / 2, 4, boxWidth, size.height * 0.14), line);
    canvas.drawRect(Rect.fromLTWH((size.width - boxWidth) / 2, size.height - 4 - size.height * 0.14, boxWidth, size.height * 0.14), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
