import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:next_gen_app/title_screen/particle_overlay.dart';
import 'package:next_gen_app/title_screen/title_screen_ui.dart';

import '../assets.dart';
import '../orb_shader/orb_shader_config.dart';
import '../orb_shader/orb_shader_widget.dart';
import '../styles.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen>
    with SingleTickerProviderStateMixin {
  final _orbKey = GlobalKey<OrbShaderWidgetState>();

  Color get _emitColor =>
      AppColors.emitColors[_difficultyOverride ?? _difficulty];

  Color get _orbColor =>
      AppColors.orbColors[_difficultyOverride ?? _difficulty];

  /// Currently selected difficulty
  int _difficulty = 0;

  /// Currently focused difficulty (if any)
  int? _difficultyOverride;
   double _orbEnergy = 0;
  double _minOrbEnergy = 0;

  double get _finalReceiveLightAmt {
    final light =
        lerpDouble(_minReceiveLightAmt, _maxReceiveLightAmt, _orbEnergy) ?? 0;
    return light + _pulseEffect.value * .05 * _orbEnergy;
  }

  double get _finalEmitLightAmt {
    return lerpDouble(_minEmitLightAmt, _maxEmitLightAmt, _orbEnergy) ?? 0;
  }

  void _handleDifficultyPressed(int value) {
    setState(() => _difficulty = value);
  }

  @override
  void initState() {
    super.initState();
    _pulseEffect.forward();
    _pulseEffect.addListener(_handlePulseEffectUpdate);
  }

  void _handlePulseEffectUpdate() {
    if (_pulseEffect.status == AnimationStatus.completed) {
      _pulseEffect.reverse();
      _pulseEffect.duration = _getRndPulseDuration();
    } else if (_pulseEffect.status == AnimationStatus.dismissed) {
      _pulseEffect.duration = _getRndPulseDuration();
      _pulseEffect.forward();
    }
  }

  late final _pulseEffect = AnimationController(
    vsync: this,
    duration: _getRndPulseDuration(),
    lowerBound: -1,
    upperBound: 1,
  );

  Duration _getRndPulseDuration() => 100.ms + 200.ms * Random().nextDouble();

  double _getMinEnergyForDifficulty(int difficulty) => switch (difficulty) {
        1 => 0.3,
        2 => 0.6,
        _ => 0,
      };

  Future<void> _bumpMinEnergy([double amount = 0.1]) async {
    setState(() {
      _minOrbEnergy = _getMinEnergyForDifficulty(_difficulty) + amount;
    });
    await Future<void>.delayed(.2.seconds);
    setState(() {
      _minOrbEnergy = _getMinEnergyForDifficulty(_difficulty);
    });
  }

  void _handleStartPressed() => _bumpMinEnergy(0.3);

  void _handleDifficultyFocused(int? value) {
    setState(() {
      _difficultyOverride = value;
      if (value == null) {
        _minOrbEnergy = _getMinEnergyForDifficulty(_difficulty);
      } else {
        _minOrbEnergy = _getMinEnergyForDifficulty(value);
      }
    });
  }

  final _minReceiveLightAmt = .35;
  final _maxReceiveLightAmt = .7;

  final _minEmitLightAmt = .5;
  final _maxEmitLightAmt = 1;

  final _mousePos = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final orbColor = AppColors.orbColors[0];
    final emitColor = AppColors.emitColors[0];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _AnimatedColors(
          orbColor: _orbColor,
          emitColor: _emitColor,
          builder: (_, orbColor, emitColor) => Stack(
            children: [
              /// Bg-Base
              Image.asset(AssetPaths.titleBgBase),

              /// Bg-Receive
              _LitImage(
                  color: orbColor,
                  imgSrc: AssetPaths.titleBgReceive,
                  pulseEffect: _pulseEffect,
                  lightAmt: _finalReceiveLightAmt),

              Positioned.fill(
                child: Stack(
                  children: [
                    // Orb
                    OrbShaderWidget(
                      key: _orbKey,
                      mousePos: _mousePos,
                      minEnergy: _minOrbEnergy,
                      config: OrbShaderConfig(
                        ambientLightColor: orbColor,
                        materialColor: orbColor,
                        lightColor: orbColor,
                      ),
                      onUpdate: (energy) => setState(() {
                        _orbEnergy = energy;
                      }),
                    ),
                  ],
                ),
              ),

              /// Mg-Base
              _LitImage(
                  color: orbColor,
                  imgSrc: AssetPaths.titleMgBase,
                  pulseEffect: _pulseEffect,
                  lightAmt: _finalReceiveLightAmt),

              /// Mg-Receive
              _LitImage(
                  color: orbColor,
                  imgSrc: AssetPaths.titleMgReceive,
                  pulseEffect: _pulseEffect,
                  lightAmt: _finalReceiveLightAmt),

              /// Mg-Emit
              _LitImage(
                  color: emitColor,
                  imgSrc: AssetPaths.titleMgEmit,
                  pulseEffect: _pulseEffect,
                  lightAmt: _finalEmitLightAmt),

              Positioned.fill(                          // Add from here...
                child: IgnorePointer(
                  child: ParticleOverlay(
                    color: orbColor,
                    energy: _orbEnergy,
                  ),
                ),
              ),

              /// Fg-Rocks
              Image.asset(AssetPaths.titleFgBase),

              /// Fg-Receive
              _LitImage(
                  color: orbColor,
                  imgSrc: AssetPaths.titleFgReceive,
                  pulseEffect: _pulseEffect,
                  lightAmt: _finalReceiveLightAmt),

              /// Fg-Emit
              _LitImage(
                  color: emitColor,
                  imgSrc: AssetPaths.titleFgEmit,
                  pulseEffect: _pulseEffect,
                  lightAmt: _finalEmitLightAmt),
              Positioned.fill(
                  child: TitleScreenUi(
                difficulty: _difficulty,
                onStartPressed: _handleStartPressed,
                onDifficultyFocused: _handleDifficultyFocused,
                onDifficultyPressed: _handleDifficultyPressed,
              ))
            ],
          ).animate().fadeIn(duration: 1.seconds, delay: .3.seconds),
        ),
      ),
    );
  }
}

class _LitImage extends StatelessWidget {
  const _LitImage(
      {required this.color,
      required this.imgSrc,
      required this.lightAmt,
      required this.pulseEffect});

  final Color color;
  final String imgSrc;
  final double lightAmt;
  final AnimationController pulseEffect;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    return ListenableBuilder(
        listenable: pulseEffect,
        builder: (context, child) {
          return Image.asset(
            imgSrc,
            color: hsl.withLightness(hsl.lightness * lightAmt).toColor(),
            colorBlendMode: BlendMode.modulate,
          );
        });
  }
} // to here.

class _AnimatedColors extends StatelessWidget {
  const _AnimatedColors({
    required this.emitColor,
    required this.orbColor,
    required this.builder,
  });

  final Color emitColor;
  final Color orbColor;

  final Widget Function(BuildContext context, Color orbColor, Color emitColor)
      builder;

  @override
  Widget build(BuildContext context) {
    final duration = .5.seconds;
    return TweenAnimationBuilder(
      tween: ColorTween(begin: emitColor, end: emitColor),
      duration: duration,
      builder: (_, emitColor, __) {
        return TweenAnimationBuilder(
          tween: ColorTween(begin: orbColor, end: orbColor),
          duration: duration,
          builder: (context, orbColor, __) {
            return builder(context, orbColor!, emitColor!);
          },
        );
      },
    );
  }
}
