import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/services/storage_service.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/primary_button.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Convenience only — never a stored credential.
    _email.text = StorageService.instance.getString(StorageKeys.lastAuthEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _email.text.trim();
    final ok = await ref.read(authProvider.notifier).login(
          email: email,
          password: _password.text,
        );

    if (!mounted) return;
    if (ok) {
      await StorageService.instance.setString(StorageKeys.lastAuthEmail, email);
      // The router redirect moves us to Home once the auth state flips; no
      // explicit navigation here, so there is exactly one source of truth.
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('🕌', style: TextStyle(fontSize: 56.sp), textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    Text(
                      'আসসালামু আলাইকুম',
                      style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'অ্যাকাউন্টে লগইন করুন',
                      style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),

                    if (state.failure != null) ...[
                      AuthErrorBanner(message: state.failure!.message),
                      SizedBox(height: 20.h),
                    ],

                    AuthTextField(
                      controller: _email,
                      label: 'ইমেইল',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      enabled: !state.isBusy,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'সঠিক ইমেইল ঠিকানা দিন'
                          : null,
                    ),
                    SizedBox(height: 20.h),

                    AuthTextField(
                      controller: _password,
                      label: 'পাসওয়ার্ড',
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      enabled: !state.isBusy,
                      onSubmitted: _submit,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'পাসওয়ার্ড দিন'
                          : null,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: state.isBusy
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        child: Text(
                          'পাসওয়ার্ড ভুলে গেছেন?',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    PrimaryButton(
                      label: 'লগইন',
                      isLoading: state.isBusy,
                      onPressed: _submit,
                    ),
                    SizedBox(height: 20.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'অ্যাকাউন্ট নেই?',
                          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: state.isBusy
                              ? null
                              : () => context.push(AppRoutes.register),
                          child: Text(
                            'রেজিস্টার করুন',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                          ),
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
  }
}
