import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/primary_button.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(authProvider.notifier).forgotPassword(_email.text.trim());
    if (!mounted) return;
    if (ok) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('পাসওয়ার্ড রিসেট', style: TextStyle(fontSize: 18.sp)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: _sent ? _sentView(context) : _formView(state),
        ),
      ),
    );
  }

  Widget _formView(AuthState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'আপনার ইমেইল ঠিকানা দিন। আমরা পাসওয়ার্ড রিসেট করার লিংক পাঠাব।',
            style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary, height: 1.6),
          ),
          SizedBox(height: 28.h),

          if (state.failure != null) ...[
            AuthErrorBanner(message: state.failure!.message),
            SizedBox(height: 20.h),
          ],

          AuthTextField(
            controller: _email,
            label: 'ইমেইল',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            enabled: !state.isBusy,
            onSubmitted: _submit,
            validator: (v) => (v == null || !v.contains('@'))
                ? 'সঠিক ইমেইল ঠিকানা দিন'
                : null,
          ),
          SizedBox(height: 28.h),

          PrimaryButton(
            label: 'রিসেট লিংক পাঠান',
            isLoading: state.isBusy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  /// The server responds identically whether or not the address is registered
  /// (FR-A-09, anti-enumeration), so this message must not claim the email
  /// definitely exists — hence "যদি ... থাকে".
  Widget _sentView(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 24.h),
        Text('📩', style: TextStyle(fontSize: 56.sp)),
        SizedBox(height: 24.h),
        Text(
          'ইমেইল পাঠানো হয়েছে',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),
        Text(
          'এই ঠিকানায় যদি কোনো অ্যাকাউন্ট থাকে, তাহলে পাসওয়ার্ড রিসেটের লিংক পাঠানো হয়েছে। '
          'ইনবক্স ও স্প্যাম ফোল্ডার দেখুন। লিংকটি ১ ঘণ্টা পর্যন্ত কার্যকর থাকবে।',
          style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary, height: 1.6),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32.h),
        PrimaryButton(
          label: 'লগইনে ফিরে যান',
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
