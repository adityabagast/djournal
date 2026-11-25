import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../providers/account_controller.dart';
import '../data/backend.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/tokens.dart';
import 'account_sheets.dart';

String apiErrorText(AppLocalizations l, ApiError e) => switch (e) {
  ApiError.network => l.errNetwork,
  ApiError.invalidCredentials => l.errInvalidCredentials,
  ApiError.emailTaken => l.errEmailTaken,
  ApiError.invalidEmail => l.errInvalidEmail,
  ApiError.passwordTooShort => l.errPasswordTooShort,
  ApiError.confirmEmail => l.errConfirmEmail,
  ApiError.sessionExpired => l.errSessionExpired,
  ApiError.server => l.errServer,
};

String googleSignInErrorText(Object error) {
  final text = error.toString();
  return text.contains('10') || text.contains('DEVELOPER_ERROR')
      ? 'Gagal masuk (Kode 10: DEVELOPER_ERROR). SHA-1 aplikasi belum didaftarkan di Firebase Console.'
      : text;
}

/// Form masuk / daftar akun server. Tombol Google (cadangan Drive) hanya
/// ditawarkan selama belum ada akun yang terhubung.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SignInScreen()));

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_password.text.length < 8) {
      setState(() => _error = l.errPasswordTooShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(accountProvider.notifier)
          .signIn(
            email: _email.text,
            password: _password.text,
            register: _register,
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = apiErrorText(l, e.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(googleDriveProvider.notifier).signIn();
      final gUser = ref.read(googleDriveProvider);
      if (gUser.email != null) {
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = googleSignInErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final driveConnected = ref.watch(googleDriveProvider).isConnected;
    final showGoogle = !driveConnected && !ref.watch(accountProvider).loggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _register ? l.serverRegisterTitle : l.serverSignInTitle,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.sm, AppSpace.xl, AppSpace.xxxl),
          children: [
            Text(
              l.signInPrompt,
              style: t.bodyMedium?.copyWith(color: context.colors.muted),
            ),
            const SizedBox(height: AppSpace.lg),
            if (showGoogle) ...[
              OutlinedButton.icon(
                onPressed: _busy ? null : _signInWithGoogle,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const SizedBox.square(
                  dimension: 20,
                  child: Center(
                    child: Text('G', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: AppFontSize.heading)),
                  ),
                ),
                label: Text(l.googleSignIn, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                l.googleDriveOnlyHint,
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: context.colors.muted),
              ),
              const SizedBox(height: AppSpace.lg),
            ],
            if (driveConnected) ...[
              AccountNote(icon: Icons.check, text: l.serverDriveStays),
              const SizedBox(height: AppSpace.lg),
            ],
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l.email),
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: [
                _register ? AutofillHints.newPassword : AutofillHints.password,
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _busy ? null : _submit(),
              decoration: InputDecoration(
                labelText: l.password,
                helperText: _register ? l.passwordHint : null,
                suffixIcon: IconButton(
                  tooltip: l.password,
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                _error!,
                style: t.bodyMedium?.copyWith(color: context.colors.expense),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            AccountNote(
              icon: Icons.info_outline,
              text: l.serverDataScope,
              warning: true,
            ),
            const SizedBox(height: AppSpace.xl),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _busy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: context.colors.onPrimary,
                      ),
                    )
                  : Text(_register ? l.register : l.signIn),
            ),
            const SizedBox(height: AppSpace.sm),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _register = !_register;
                      _error = null;
                    }),
              child: Text(_register ? l.haveAccount : l.noAccount),
            ),
          ],
        ),
      ),
    );
  }
}
