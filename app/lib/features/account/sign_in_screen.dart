import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/sync/account_controller.dart';
import '../../data/sync/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/common.dart';

String apiErrorText(AppLocalizations l, ApiError e) => switch (e) {
  ApiError.network => l.errNetwork,
  ApiError.invalidCredentials => l.errInvalidCredentials,
  ApiError.emailTaken => l.errEmailTaken,
  ApiError.invalidEmail => l.errInvalidEmail,
  ApiError.passwordTooShort => l.errPasswordTooShort,
  ApiError.sessionExpired => l.errSessionExpired,
  ApiError.server => l.errServer,
};

/// Form masuk / daftar. Alamat server bisa diubah (self-hosted).
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
  late final TextEditingController _server;
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: ref.read(accountProvider).serverUrl);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _server.dispose();
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
            serverUrl: _server.text,
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
              style: t.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                l.serverUrl,
                style: t.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              children: [
                TextField(
                  controller: _server,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(hintText: l.serverUrlHint),
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: t.bodyMedium?.copyWith(color: AppColors.expense),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
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
