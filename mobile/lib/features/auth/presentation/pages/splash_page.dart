import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    // Check if auth is already resolved right after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });

    // Safety fallback: Never stay on splash screen longer than 1.2s
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!_hasNavigated && mounted) {
        _forceNavigate();
      }
    });
  }

  void _checkAndNavigate() {
    if (_hasNavigated || !mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isInitialCheckDone) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!_hasNavigated && mounted) {
          _doNavigate(auth.isAuthenticated);
        }
      });
    }
  }

  void _forceNavigate() {
    if (_hasNavigated || !mounted) return;
    final auth = ref.read(authProvider);
    _doNavigate(auth.isAuthenticated);
  }

  void _doNavigate(bool isAuthenticated) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    if (isAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.isInitialCheckDone && !_hasNavigated) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!_hasNavigated && mounted) {
            _doNavigate(next.isAuthenticated);
          }
        });
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _forceNavigate,
      child: Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                    children: const [
                      TextSpan(text: 'Student'),
                      TextSpan(
                        text: 'Brain',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Academic Command Center & Study Network',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
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
