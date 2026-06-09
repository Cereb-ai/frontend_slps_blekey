import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../states/global_user.dart';
import '../../routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _rememberMe = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..repeat();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final saved = await GlobalUser.instance.getSavedUsername();
    final rem = await GlobalUser.instance.getRememberMe();
    if (!mounted) return;
    setState(() {
      _rememberMe = rem;
      if (saved != null) _usernameController.text = saved;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await GlobalUser.instance.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated particle background
          AnimatedBuilder(
            animation: _ticker,
            builder: (context, _) => CustomPaint(
              painter: _ParticlePainter(_ticker.value),
              size: Size.infinite,
            ),
          ),
          // Login card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1B2A3A)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 40,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Lock icon replacing logo
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF176B87,
                            ).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF176B87,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF00D9FF),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Smart Lock Platform',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '智能门锁管理平台',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Username
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          textInputAction: TextInputAction.next,
                          decoration: _inputDeco(
                            hint: '用户名 / 邮箱',
                            icon: Icons.person_outline,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? '请输入用户名' : null,
                        ),
                        const SizedBox(height: 14),
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration:
                              _inputDeco(
                                hint: '密码',
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF6B7A8D),
                                  ),
                                ),
                              ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? '请输入密码' : null,
                        ),
                        const SizedBox(height: 12),
                        // Remember me
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                                activeColor: const Color(0xFF176B87),
                                side: const BorderSide(
                                  color: Color(0xFF3A4A5A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '记住我',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF176B87),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    '登录',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF6B7A8D), size: 20),
      filled: true,
      fillColor: const Color(0xFF111C2D),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E2E40)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF176B87)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade700),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade700),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}

// ----- Particle background painter -----

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  Color color;
  double alpha;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    required this.alpha,
  });
}

class _ParticlePainter extends CustomPainter {
  static const int _count = 80;
  static const double _connectionDist = 120;
  static const double _speed = 0.3;

  static final _colors = [
    const Color(0xFF00D9FF),
    const Color(0xFF8B5CF6),
    Colors.white,
  ];

  static List<_Particle>? _particles;
  static Size _lastSize = Size.zero;

  final double tick;

  _ParticlePainter(this.tick);

  static List<_Particle> _init(Size size) {
    final rng = math.Random(42);
    return List.generate(_count, (i) {
      final angle = rng.nextDouble() * math.pi * 2;
      final spd = rng.nextDouble() * _speed + 0.1;
      return _Particle(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        vx: math.cos(angle) * spd,
        vy: math.sin(angle) * spd,
        radius: rng.nextDouble() * 1.5 + 0.5,
        color: _colors[rng.nextInt(_colors.length)],
        alpha: rng.nextDouble() * 0.5 + 0.2,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size != _lastSize) {
      _particles = _init(size);
      _lastSize = size;
    }
    final parts = _particles!;

    for (final p in parts) {
      p.x = (p.x + p.vx + size.width) % size.width;
      p.y = (p.y + p.vy + size.height) % size.height;
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0xFF00D9FF);

    for (int i = 0; i < parts.length; i++) {
      final pi = parts[i];
      dotPaint.color = pi.color.withValues(alpha: pi.alpha);
      canvas.drawCircle(Offset(pi.x, pi.y), pi.radius, dotPaint);

      for (int j = i + 1; j < parts.length; j++) {
        final pj = parts[j];
        final dx = pi.x - pj.x;
        final dy = pi.y - pj.y;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < _connectionDist) {
          linePaint.color = const Color(
            0xFF00D9FF,
          ).withValues(alpha: (1 - dist / _connectionDist) * 0.15);
          canvas.drawLine(Offset(pi.x, pi.y), Offset(pj.x, pj.y), linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.tick != tick;
}
