import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/primary_button.dart';
import '../viewmodel/subscription_viewmodel.dart';

/// The subscription gate (M-3/M-4).
///
/// FR-S-08 — SOFT gate. The ✕ in the top-right dismisses it and the user
/// continues to the app as a free user. The Android back gesture does the same.
/// No confirmation, no penalty.
class SubscriptionGateScreen extends ConsumerStatefulWidget {
  const SubscriptionGateScreen({
    super.key,
    required this.onDone,
    this.canDismiss = true,
    this.isAutomaticPrompt = true,
  });

  /// Called on both dismissal and success — the caller decides where to go, so
  /// this screen works identically as a startup gate and as a Settings entry.
  final void Function({required bool subscribed}) onDone;

  final bool canDismiss;

  /// FR-S-09 — only an automatic startup display counts toward the 3-prompt
  /// limit. A user who opens this deliberately from Settings should not burn
  /// one of their own prompts by doing so.
  final bool isAutomaticPrompt;

  @override
  ConsumerState<SubscriptionGateScreen> createState() => _SubscriptionGateScreenState();
}

class _SubscriptionGateScreenState extends ConsumerState<SubscriptionGateScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Start clean: a previous visit may have ended on the OTP or success
      // step, and reopening should not resume someone else's half-finished
      // flow.
      ref.read(subscriptionProvider.notifier).reset();
      if (widget.isAutomaticPrompt) {
        SubscriptionGatePolicy.recordShown(); // FR-S-09
      }
    });
    // Drives the resend countdown label.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await ref.read(subscriptionProvider.notifier).dismiss();
    if (!mounted) return;
    widget.onDone(subscribed: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);

    ref.listen(subscriptionProvider, (previous, next) {
      if (next.step == GateStep.success && previous?.step != GateStep.success) {
        widget.onDone(subscribed: true);
      }
    });

    // FR-S-08 — system back behaves exactly like the cross.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (state.step == GateStep.otp) {
          ref.read(subscriptionProvider.notifier).backToPhone();
        } else if (widget.canDismiss) {
          _dismiss();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                showBack: state.step == GateStep.otp,
                canDismiss: widget.canDismiss,
                onBack: () => ref.read(subscriptionProvider.notifier).backToPhone(),
                onDismiss: _dismiss,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: state.step == GateStep.otp
                      ? _otpStep(state)
                      : _phoneStep(state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- phone step

  Widget _phoneStep(SubscriptionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 8.h),
        Text('⭐', style: TextStyle(fontSize: 52.sp), textAlign: TextAlign.center),
        SizedBox(height: 20.h),
        Text(
          'প্রিমিয়াম সাবস্ক্রিপশন',
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10.h),
        Text(
          'সপ্তাহে মাত্র ৫ টাকা',
          style: TextStyle(fontSize: 17.sp, color: AppColors.accent, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24.h),

        const _BenefitList(),
        SizedBox(height: 28.h),

        if (state.failure != null) ...[
          _ErrorBanner(message: state.failure!.message),
          SizedBox(height: 16.h),
        ],

        Text(
          'রবি / এয়ারটেল নম্বর',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          enabled: !state.isBusy,
          maxLength: 11,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(fontSize: 17.sp, letterSpacing: 1.2),
          decoration: InputDecoration(
            hintText: '01XXXXXXXXX',
            counterText: '',
            filled: true,
            prefixIcon: const Icon(Icons.phone_android),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _submitPhone(),
        ),
        SizedBox(height: 20.h),

        PrimaryButton(
          label: 'সাবস্ক্রাইব করুন',
          isLoading: state.isBusy,
          onPressed: _submitPhone,
        ),
        SizedBox(height: 12.h),

        Text(
          'আপনার মোবাইল ব্যালেন্স থেকে সাপ্তাহিক ৫ টাকা কাটা হবে। '
          'যেকোনো সময় সেটিংস থেকে বাতিল করতে পারবেন।',
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.6),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  void _submitPhone() {
    FocusScope.of(context).unfocus();
    ref.read(subscriptionProvider.notifier).submitPhone(_phone.text);
  }

  // --------------------------------------------------------------- otp step

  Widget _otpStep(SubscriptionState state) {
    final masked = state.msisdn.length == 11
        ? '${state.msisdn.substring(0, 3)}XXXXX${state.msisdn.substring(8)}'
        : state.msisdn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 16.h),
        Text('📩', style: TextStyle(fontSize: 48.sp), textAlign: TextAlign.center),
        SizedBox(height: 20.h),
        Text(
          'ওটিপি যাচাই',
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10.h),
        Text(
          '$masked নম্বরে পাঠানো কোডটি লিখুন',
          style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 28.h),

        if (state.failure != null) ...[
          _ErrorBanner(message: state.failure!.message),
          SizedBox(height: 16.h),
        ],

        TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          enabled: !state.isBusy,
          maxLength: 6,
          textAlign: TextAlign.center,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(fontSize: 26.sp, letterSpacing: 10, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '------',
            counterText: '',
            filled: true,
            contentPadding: EdgeInsets.symmetric(vertical: 16.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _submitOtp(),
        ),
        SizedBox(height: 20.h),

        PrimaryButton(
          label: 'যাচাই করুন',
          isLoading: state.isBusy,
          onPressed: _submitOtp,
        ),
        SizedBox(height: 12.h),

        // FR-S-05 — resend only after the countdown, and only within the
        // server-side rate limit.
        Center(
          child: state.resendInSeconds > 0
              ? Text(
                  '${_bn(state.resendInSeconds)} সেকেন্ড পর আবার পাঠাতে পারবেন',
                  style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                )
              : TextButton(
                  onPressed: state.isBusy
                      ? null
                      : () => ref.read(subscriptionProvider.notifier).resendOtp(),
                  child: Text('ওটিপি আবার পাঠান', style: TextStyle(fontSize: 14.sp)),
                ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: TextButton(
            onPressed: () => ref.read(subscriptionProvider.notifier).backToPhone(),
            child: Text(
              'নম্বর পরিবর্তন করুন',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  void _submitOtp() {
    FocusScope.of(context).unfocus();
    ref.read(subscriptionProvider.notifier).submitOtp(_otp.text);
  }

  /// NFR-07 — numerals render in Bangla script.
  static String _bn(int value) {
    const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return value.toString().split('').map((c) {
      final index = int.tryParse(c);
      return index == null ? c : digits[index];
    }).join();
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showBack,
    required this.canDismiss,
    required this.onBack,
    required this.onDismiss,
  });

  final bool showBack;
  final bool canDismiss;
  final VoidCallback onBack;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
              tooltip: 'পেছনে',
            ),
          const Spacer(),
          // FR-S-08 — the cross. One tap, straight out, no questions.
          if (canDismiss)
            IconButton(
              icon: const Icon(Icons.close),
              iconSize: 26.sp,
              onPressed: onDismiss,
              tooltip: 'বন্ধ করুন',
            ),
        ],
      ),
    );
  }
}

/// FR-S-16 — premium value is stated plainly. Locked features stay visible;
/// invisible value cannot be sold.
class _BenefitList extends StatelessWidget {
  const _BenefitList();

  static const _benefits = [
    ('📿', 'সম্পূর্ণ আমল ট্র্যাকার', 'তাহাজ্জুদসহ ৯টি আমল'),
    ('📖', 'সব সূরা ও ৯৯ নাম', 'সম্পূর্ণ সংকলন'),
    ('🌙', 'রমজান স্পেশাল মোড', 'সেহরি, ইফতার ও তারাবিহ'),
    ('🔔', 'প্রতিদিনের হাদিস নোটিফিকেশন', 'সরাসরি আপনার ফোনে'),
    ('🚫', 'বিজ্ঞাপনমুক্ত', 'কোনো বিজ্ঞাপন নেই'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _benefits
          .map(
            (b) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.$1, style: TextStyle(fontSize: 20.sp)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.$2,
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          b.$3,
                          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14.sp, color: AppColors.error, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
