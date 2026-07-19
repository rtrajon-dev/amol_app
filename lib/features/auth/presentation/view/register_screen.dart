import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/services/storage_service.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/primary_button.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _email.text.trim();
    final ok = await ref.read(authProvider.notifier).register(
          email: email,
          password: _password.text,
          displayName: _name.text.trim(),
        );

    if (!mounted) return;
    if (ok) {
      await StorageService.instance.setString(StorageKeys.lastAuthEmail, email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('নতুন অ্যাকাউন্ট', style: TextStyle(fontSize: 18.sp)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: state.isBusy ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.failure != null) ...[
                    AuthErrorBanner(message: state.failure!.message),
                    SizedBox(height: 20.h),
                  ],

                  AuthTextField(
                    controller: _name,
                    label: 'আপনার নাম (ঐচ্ছিক)',
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    enabled: !state.isBusy,
                  ),
                  SizedBox(height: 20.h),

                  AuthTextField(
                    controller: _email,
                    label: 'ইমেইল',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    enabled: !state.isBusy,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'সঠিক ইমেইল ঠিকানা দিন';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),

                  AuthTextField(
                    controller: _password,
                    label: 'পাসওয়ার্ড',
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !state.isBusy,
                    onSubmitted: _submit,
                    // FR-A-02 — length only. No composition rules: they push
                    // users toward reuse and measurably reduce security.
                    validator: (v) => (v == null || v.length < 8)
                        ? 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে'
                        : null,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'কমপক্ষে ৮ অক্ষর',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 28.h),

                  PrimaryButton(
                    label: 'রেজিস্টার করুন',
                    isLoading: state.isBusy,
                    onPressed: _submit,
                  ),
                  SizedBox(height: 16.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ইতিমধ্যে অ্যাকাউন্ট আছে?',
                        style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: state.isBusy ? null : () => context.pop(),
                        child: Text(
                          'লগইন করুন',
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
    );
  }
}
