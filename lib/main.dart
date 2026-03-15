import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const GravityTugApp());
}

class GravityTugApp extends StatelessWidget {
  const GravityTugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gravity Tug: Color Clash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const GravityTugGame(),
    );
  }
}

class GravityTugGame extends StatefulWidget {
  const GravityTugGame({super.key});

  @override
  State<GravityTugGame> createState() => _GravityTugGameState();
}

class _GravityTugGameState extends State<GravityTugGame> {
  static const double _orbStep = 0.12;
  static const double _bombStep = 0.24;
  static const int _maxTargetsPerSide = 3;

  final Random _random = Random();
  final List<TargetCircle> _targets = <TargetCircle>[];

  Timer? _tickTimer;
  double _orbPosition = 0;
  PlayerSide? _winner;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _tickTimer?.cancel();
    setState(() {
      _orbPosition = 0;
      _winner = null;
      _targets.clear();
    });

    _tickTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted || _winner != null) {
        return;
      }
      setState(() {
        _targets.removeWhere((TargetCircle target) => target.expiresAt.isBefore(DateTime.now()));
        _spawnTargetsForSide(PlayerSide.top);
        _spawnTargetsForSide(PlayerSide.bottom);
      });
    });
  }

  void _spawnTargetsForSide(PlayerSide side) {
    final int activeForSide = _targets.where((TargetCircle target) => target.side == side).length;
    if (activeForSide >= _maxTargetsPerSide) {
      return;
    }

    if (_random.nextDouble() > 0.8) {
      return;
    }

    final DateTime now = DateTime.now();
    final TargetCircle target = TargetCircle(
      id: '${side.name}-${now.microsecondsSinceEpoch}-${_random.nextInt(9999)}',
      side: side,
      x: 0.1 + _random.nextDouble() * 0.8,
      y: 0.08 + _random.nextDouble() * 0.84,
      isBomb: _random.nextDouble() < 0.25,
      expiresAt: now.add(Duration(milliseconds: 900 + _random.nextInt(900))),
    );

    _targets.add(target);
  }

  void _handleTap(TargetCircle target) {
    if (_winner != null) {
      return;
    }

    setState(() {
      _targets.removeWhere((TargetCircle item) => item.id == target.id);

      final double direction = target.side == PlayerSide.top ? -1 : 1;
      final double change = target.isBomb ? -_bombStep * direction : _orbStep * direction;
      _orbPosition = (_orbPosition + change).clamp(-1.0, 1.0);

      if (_orbPosition <= -1) {
        _winner = PlayerSide.top;
        _tickTimer?.cancel();
      } else if (_orbPosition >= 1) {
        _winner = PlayerSide.bottom;
        _tickTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;
          final double halfHeight = height / 2;
          final double orbDiameter = min(width, height) * 0.13;
          final double orbCenterY = halfHeight + (_orbPosition * (halfHeight - orbDiameter));

          return Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      color: const Color(0xFFB71C1C),
                      child: _buildHalfLabel('PLAYER 1', Alignment.topCenter),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: const Color(0xFF0D47A1),
                      child: _buildHalfLabel('PLAYER 2', Alignment.bottomCenter),
                    ),
                  ),
                ],
              ),
              ..._targets.map((TargetCircle target) {
                final double topInset = target.side == PlayerSide.top
                    ? target.y * (halfHeight - 64)
                    : halfHeight + (target.y * (halfHeight - 64));

                return Positioned(
                  left: target.x * (width - 54),
                  top: topInset,
                  child: GestureDetector(
                    onTap: () => _handleTap(target),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: target.isBomb ? Colors.black : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 2),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: target.isBomb
                                ? Colors.black.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.7),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: target.isBomb
                          ? const Icon(Icons.close_rounded, color: Colors.redAccent)
                          : null,
                    ),
                  ),
                );
              }),
              Positioned(
                left: 0,
                right: 0,
                top: orbCenterY - (orbDiameter / 2),
                child: Center(
                  child: Container(
                    width: orbDiameter,
                    height: orbDiameter,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[Color(0xFFBBDEFB), Color(0xFF2196F3), Color(0xFF0D47A1)],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(color: Color(0xAA42A5F5), blurRadius: 18, spreadRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
              if (_winner != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.65),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white54),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              _winner == PlayerSide.top ? 'PLAYER 1 WINS!' : 'PLAYER 2 WINS!',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Tap to start the next round.'),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _startRound,
                              child: const Text('Play Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'White = pull toward you   •   Black = push away',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHalfLabel(String text, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

enum PlayerSide { top, bottom }

class TargetCircle {
  const TargetCircle({
    required this.id,
    required this.side,
    required this.x,
    required this.y,
    required this.isBomb,
    required this.expiresAt,
  });

  final String id;
  final PlayerSide side;
  final double x;
  final double y;
  final bool isBomb;
  final DateTime expiresAt;
}
