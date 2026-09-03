import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/auth/auth_cubit.dart';
import '../../../models/auth/login_response_model.dart';
import '../../../settings/app_assets.dart';
import '../../../settings/app_colors.dart';
import '../../../settings/app_enums.dart';
import '../../../settings/app_environment.dart';
import '../../../settings/app_extensions.dart';
import '../../../settings/app_fonts.dart';
import '../../../settings/app_routes.dart';
import '../../../settings/app_validators.dart';
import '../../components/app_button.dart';
import '../../components/app_icon.dart';
import '../../components/app_input.dart';
import '../../components/app_snackbar.dart';

/// Tela de login. **Não existe no protótipo** — foi derivada da paleta e dos
/// componentes já definidos (decisão A2), então é a primeira candidata a ajuste
/// quando houver um mockup dela.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AppInputController _emailController;
  late final AppInputController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = AppInputController(
      validator: AppValidators.validateEmail,
    );
    _passwordController = AppInputController(
      validator: AppValidators.validatePassword,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validação é `validate()` em cada controller dentro de um `setState` — não
  /// `Form` + `GlobalKey<FormState>` (capítulo 08 do padrão).
  void _submit() {
    setState(() {
      _emailController.validate();
      _passwordController.validate();
    });

    if (_emailController.hasError || _passwordController.hasError) return;

    BlocProvider.of<AuthCubit>(context).login(
      email: _emailController.text.trim(),
      senha: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: BlocConsumer<AuthCubit, AuthState>(
                  listenWhen: (p, c) => p.loginSubState != c.loginSubState,
                  buildWhen: (p, c) => p.loginSubState != c.loginSubState,
                  listener: (context, state) {
                    final sub = state.loginSubState;
                    if (!sub.isCompleted) return;

                    if (sub.hasError) {
                      AppSnackBar.showSnackbar(
                        context,
                        sub.error!.message,
                        SnackBarStatus.error,
                      );
                      return;
                    }

                    if (sub.value<LoginResponseModel>() != null) {
                      AppRoutes.push(
                        AppRoutes.homeRoute,
                        removeUntil: (_) => false,
                      );
                    }
                  },
                  builder: (context, state) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBrand(context),
                      if (AppEnvironment.isDemo) ...[
                        const SizedBox(height: 20),
                        _buildDemoBanner(context),
                      ],
                      const SizedBox(height: 26),
                      Text(
                        context.l10n.welcomeBack,
                        style: AppFonts.sectionTitle(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.welcomeBackHint,
                        style: AppFonts.caption(context),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppInput(
                            controller: _emailController,
                            label: context.l10n.emailLabel,
                            hint: context.l10n.emailHint,
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                            autofocus: true,
                          ),
                          const SizedBox(height: 14),
                          AppInput(
                            controller: _passwordController,
                            label: context.l10n.passwordLabel,
                            isObscure: true,
                            showObscureToggle: true,
                            onSubmitted: _submit,
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            label: context.l10n.signInButton,
                            isLoading: state.loginSubState.isLoading,
                            isExpanded: true,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  /// Sem isto, o modo demo é indistinguível do app real: alguém mostra a tela
  /// para a cliente, ela salva um atendimento e o dado some no refresh.
  Widget _buildDemoBanner(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.amberLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppIcon(AppAssets.warning, size: 18, color: AppColors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.demoModeBanner,
                style: AppFonts.captionSmall(context)
                    .copyWith(color: AppColors.amber),
              ),
            ),
          ],
        ),
      );

  Widget _buildBrand(BuildContext context) => Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.primaryShadow,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const AppIcon(
              AppAssets.sparkles,
              size: 25,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.appName,
            textAlign: TextAlign.center,
            style: AppFonts.pageTitle(context),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.loginSubtitle,
            textAlign: TextAlign.center,
            style: AppFonts.caption(context),
          ),
        ],
      );
}
