import 'package:flutter/material.dart';
import '../config/app_config.dart';

class FadeInWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  const FadeInWrapper({super.key, required this.child, this.duration = const Duration(milliseconds: 450), this.curve = Curves.easeOut});

  @override
  State<FadeInWrapper> createState() => _FadeInWrapperState();
}

class _FadeInWrapperState extends State<FadeInWrapper> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  bool _hideOverlay = false;
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;

  @override
  void initState() {
    super.initState();
    final fadeDur = Duration(milliseconds: AppConfig.I.splashFadeDurationMs);
    final totalMin = Duration(milliseconds: AppConfig.I.splashMinDisplayMs);
    _controller = AnimationController(vsync: this, duration: fadeDur);
    _logoFade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic));
    _titleFade = CurvedAnimation(parent: _controller, curve: const Interval(0.35, 1.0, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Précharge le logo pour éviter frame blanche.
      try { await precacheImage(const AssetImage('assets/app_logo.png'), context); } catch (_) {}
      setState(() => _opacity = 1.0);
      _controller.forward();
      final remaining = totalMin - fadeDur;
      if (remaining.isNegative) {
        await Future.delayed(fadeDur);
      } else {
        await Future.delayed(totalMin);
      }
      if (mounted) setState(()=> _hideOverlay = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedOpacity(
          opacity: _opacity,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
        if (!_hideOverlay)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF181A20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF23272F), Color(0xFF101215)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF16FF8B).withOpacity(0.25), blurRadius: 14, spreadRadius: 2, offset: const Offset(0,5)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Image.asset('assets/app_logo.png', width: 66, height: 66, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _titleFade,
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Colors.white, Color(0xFF16FF8B)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(rect),
                        child: const Text(
                          'NexTarget',
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeTransition(
                      opacity: _titleFade,
                      child: const Text(
                        'Precision. Progress. Performance.',
                        style: TextStyle(fontSize: 11, color: Colors.white70, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}