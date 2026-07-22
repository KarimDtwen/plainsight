import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../ui/animated_gradient_background.dart';
import '../ui/app_button.dart';
import '../ui/server_wake_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AppStateProvider.of(context).login(_controller.text);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.scheme;
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ServerWakeBanner(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(t.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: GlassSurface(
                      borderRadius: BorderRadius.circular(t.radiusXl),
                      boxShadow: t.shadowCardLg,
                      padding: EdgeInsets.all(t.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Plainsight',
                              textAlign: TextAlign.center,
                              style: AppType.displayM
                                  .copyWith(color: cs.onSurface)),
                          SizedBox(height: t.xs),
                          Text('Sign in to your dashboard',
                              textAlign: TextAlign.center,
                              style: AppType.body
                                  .copyWith(color: cs.onSurfaceVariant)),
                          SizedBox(height: t.xl),
                          TextField(
                            controller: _controller,
                            obscureText: _obscure,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            style: TextStyle(color: cs.onSurface, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Admin password',
                              hintStyle: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 14),
                              filled: true,
                              fillColor: cs.brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : cs.surface,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: cs.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(t.radiusLg),
                                  borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(t.radiusLg),
                                  borderSide: const BorderSide(
                                      color: AppColors.electric, width: 1.6)),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(t.radiusLg),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                            ),
                          ),
                          if (_error != null) ...[
                            SizedBox(height: t.s),
                            Text(_error!,
                                style: AppType.caption.copyWith(
                                    color: cs.brightness == Brightness.dark
                                        ? AppColors.dangerDark
                                        : AppColors.danger)),
                          ],
                          SizedBox(height: t.l),
                          AppPrimaryButton(
                            label: 'Sign in',
                            loading: _loading,
                            onPressed: _loading ? null : _submit,
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
      ),
    );
  }
}
