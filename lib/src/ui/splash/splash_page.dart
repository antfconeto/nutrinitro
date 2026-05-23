import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/constants/resource.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/widgets/app_loading.dart';

import 'splash_view_model.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashViewModelProvider.notifier).checkout();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(splashViewModelProvider, (previousState, nextState) {
      if (nextState != null) {
        Navigator.of(context).pushReplacementNamed(nextState);
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.grayLight,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                R.ASSETS_IMAGES_ICON_PNG,
                width: 220,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Nutri',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                        letterSpacing: -1,
                      ),
                    ),
                    TextSpan(
                      text: 'Nitro',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              AppLoading(
                size: 32,
                color: AppColors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
