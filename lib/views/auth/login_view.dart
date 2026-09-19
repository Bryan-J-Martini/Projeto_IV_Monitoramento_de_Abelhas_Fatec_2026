import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/honeycomb_background.dart';
import 'cadastro_view.dart';
export 'cadastro_view.dart';
import '../dashboard/dashboard_view.dart';

const _loginBrandText = 'BeeVision';
const _loginBrandFontSize = 45.0;
const _loginBeeSize = Size(130, 104);

/// Tela de entrada do aplicativo.
///
/// O formulário já está preparado para receber a autenticação real. Enquanto
/// o serviço de login não é integrado, um preenchimento válido leva ao
/// dashboard local da aplicação.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardView()),
    );
  }

  void _openRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CadastroView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFB900),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: HoneycombBackground()),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _LoginTopHoneycombPainter())),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 52)
                          .clamp(0.0, double.infinity)
                          .toDouble(),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const _LoginBrand(),
                          const SizedBox(height: 48),
                          _LoginForm(
                            emailController: _emailController,
                            passwordController: _passwordController,
                            onSubmit: _login,
                          ),
                          const SizedBox(height: 14),
                          _LoginButton(onPressed: _login),
                          const SizedBox(height: 27),
                          _RegistrationLink(onTap: _openRegistration),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 21),
              child: Text(
                _loginBrandText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _loginBrandFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 35,
            child: IgnorePointer(
              child: const _FloatingLoginBee(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingLoginBee extends StatefulWidget {
  const _FloatingLoginBee();

  @override
  State<_FloatingLoginBee> createState() => _FloatingLoginBeeState();
}

class _FloatingLoginBeeState extends State<_FloatingLoginBee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _verticalMovement;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _verticalMovement = Tween<double>(begin: 7, end: -7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _verticalMovement,
      child: Image.asset(
        'assets/images/abelha_tela_login.png',
        width: _loginBeeSize.width,
        height: _loginBeeSize.height,
        fit: BoxFit.contain,
      ),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _verticalMovement.value),
          child: child,
        );
      },
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LoginField(
          label: 'Email:',
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Informe seu e-mail';
            }
            if (!value.contains('@')) return 'Informe um e-mail válido';
            return null;
          },
        ),
        const SizedBox(height: 13),
        _LoginField(
          label: 'Senha:',
          controller: passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Informe sua senha';
            return null;
          },
        ),
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _LoginField({
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 1),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF171717),
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            validator: validator,
            style: const TextStyle(
              color: Color(0xFF3B2A1E),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFD0D0D0),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              errorStyle: const TextStyle(
                color: Color(0xFF7A1D00),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Color(0xFF9C5A00),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Color(0xFF7A1D00),
                  width: 1.2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Color(0xFF7A1D00),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTopHoneycombPainter extends CustomPainter {
  const _LoginTopHoneycombPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35;

    final radius = (size.width * 0.055).clamp(15.0, 20.0).toDouble();
    final right = size.width;
    final horizontalStep = radius * math.sqrt(3);
    final verticalStep = radius * 1.5;
    final halfHorizontalStep = horizontalStep / 2;
    final leftCenters = <Offset>[
      Offset(-2, size.height * 0.22),
      Offset(horizontalStep - 2, size.height * 0.22),
      Offset(halfHorizontalStep - 2, size.height * 0.22 + verticalStep),
      Offset(-2, size.height * 0.22 + verticalStep * 2),
      Offset(horizontalStep - 2, size.height * 0.22 + verticalStep * 2),
    ];
    final rightCenters = <Offset>[
      Offset(right + 2, 12),
      Offset(right - horizontalStep + 2, 12),
      Offset(right - halfHorizontalStep + 2, 12 + verticalStep),
      Offset(right + 2, 12 + verticalStep * 2),
      Offset(right - horizontalStep + 2, 12 + verticalStep * 2),
      Offset(right - halfHorizontalStep + 2, 12 + verticalStep * 3),
    ];

    for (final center in [...leftCenters, ...rightCenters]) {
      canvas.drawPath(_hexagon(center, radius), paint);
    }
  }

  Path _hexagon(Offset center, double radius) {
    final path = Path();
    for (var side = 0; side < 6; side++) {
      final angle = (60 * side - 30) * math.pi / 180;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (side == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _LoginTopHoneycombPainter oldDelegate) => false;
}

// Mantido como fallback para referências antigas da tela de login.
// ignore: unused_element
class _ReferenceBeePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 112;
    canvas.save();
    canvas.scale(scale);

    final wingPaint = Paint()..color = const Color(0xFFBDBDBD);
    final wingHighlight = Paint()..color = const Color(0xFFD2D2D2);
    final bodyPaint = Paint()..color = const Color(0xFFF5C119);
    final bodyShadow = Paint()..color = const Color(0xFFEAAE08);
    final darkPaint = Paint()..color = const Color(0xFF17120D);
    final linePaint = Paint()
      ..color = const Color(0xFF17120D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(75, 30);
    canvas.rotate(-0.34);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 47),
      wingPaint,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(91, 34);
    canvas.rotate(0.65);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 21, height: 45),
      wingHighlight,
    );
    canvas.restore();

    canvas.drawOval(const Rect.fromLTWH(48, 43, 53, 35), bodyPaint);
    canvas.drawOval(const Rect.fromLTWH(80, 48, 22, 28), bodyShadow);

    canvas.save();
    canvas.clipPath(
      Path()..addOval(const Rect.fromLTWH(48, 43, 53, 35)),
    );
    canvas.drawRect(const Rect.fromLTWH(69, 39, 7, 46), darkPaint);
    canvas.drawRect(const Rect.fromLTWH(86, 39, 7, 46), darkPaint);
    canvas.restore();

    canvas.drawOval(const Rect.fromLTWH(35, 47, 27, 27), darkPaint);
    canvas.drawOval(
      const Rect.fromLTWH(39, 49, 18, 20),
      Paint()..color = const Color(0xFFB98108),
    );
    canvas.drawCircle(const Offset(51, 53), 4.2, darkPaint);
    canvas.drawCircle(const Offset(52, 52), 1.3, Paint()..color = Colors.white);

    final antenna = Path()
      ..moveTo(40, 49)
      ..quadraticBezierTo(34, 35, 39, 27);
    canvas.drawPath(antenna, linePaint);
    canvas.drawCircle(const Offset(39, 27), 2.2, darkPaint);

    final legOne = Path()
      ..moveTo(68, 73)
      ..quadraticBezierTo(65, 82, 61, 84);
    final legTwo = Path()
      ..moveTo(78, 75)
      ..quadraticBezierTo(77, 84, 73, 86);
    final legThree = Path()
      ..moveTo(89, 73)
      ..quadraticBezierTo(91, 81, 88, 84);
    canvas.drawPath(legOne, linePaint);
    canvas.drawPath(legTwo, linePaint);
    canvas.drawPath(legThree, linePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ReferenceBeePainter oldDelegate) => false;
}

class _LoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C5A00),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: const Text('Login'),
      ),
    );
  }
}

class _RegistrationLink extends StatelessWidget {
  final VoidCallback onTap;

  const _RegistrationLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir tela de cadastro',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text.rich(
            TextSpan(
              text: 'Não tem Login? Faça seu ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: 'Cadastro',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
