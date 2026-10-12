import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:flutter_template/features/auth/presentation/widgets/register_form.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:go_router/go_router.dart';

/// Create account. Back goes to log in.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthPageShell(
      eyebrow: l10n.registerEyebrow,
      headline: l10n.registerHeadline,
      onBack: () => context.go(RouteNames.login),
      child: const RegisterForm(),
    );
  }
}
