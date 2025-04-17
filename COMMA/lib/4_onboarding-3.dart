import 'package:flutter/material.dart';

class Onboarding3 extends StatelessWidget {
  final FocusNode focusNode;

  const Onboarding3({required this.focusNode});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Focus(
        focusNode: focusNode,
        child: Container(
          width: size.width,
          height: size.height,
          color: theme.scaffoldBackgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.20),
              Text(
                'Alternative learning materials Colon(:) created by AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onTertiary,
                  fontSize: 20,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: size.height * 0.02),
              Text(
                'To help you review after class,\nlet AI create personalised alternative learning materials for you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.surfaceBright,
                  fontSize: 14,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: size.height * 0.08),
              Semantics(
                label: 'Alternative learning resources colon',
                child: SizedBox(
                  width: size.width,
                  height: size.height * 0.3,
                  child: Image.asset('assets/onboarding_3.png'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
