import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/sync/account_controller.dart';
import '../../data/sync/backend.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/common.dart';

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

/// Form masuk / daftar.
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
      final err = e.toString();
      if (err.contains('10') || err.contains('DEVELOPER_ERROR')) {
        setState(
          () => _error =
              'Gagal masuk (Kode 10: DEVELOPER_ERROR). SHA-1 aplikasi belum didaftarkan di Firebase Console.',
        );
      } else {
        setState(() => _error = err);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _register ? l.register : l.signIn,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              l.signInPrompt,
              style: t.bodyMedium?.copyWith(color: context.colors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const SizedBox.square(
                dimension: 20,
                child: Center(
                  child: Text('G', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 18)),
                ),
              ),
              label: Text(l.googleSignIn, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: context.colors.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ATAU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.colors.muted,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: context.colors.divider)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l.email),
            ),
            const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              Text(
                _error!,
                style: t.bodyMedium?.copyWith(color: context.colors.expense),
              ),
            ],
            const SizedBox(height: 20),
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
            const SizedBox(height: 8),
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
