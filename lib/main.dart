import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'widgets/chatbot_overlay.dart'; 

void main() {
  runApp(
    const ProviderScope(
      child: RapidCareApp(),
    ),
  );
}

class RapidCareApp extends ConsumerWidget {
  const RapidCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'RapidCare',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Applying the Global Chatbot overlay on top of every route
        return Stack(
          children: [
            child!,
            const ChatbotOverlay(),
          ],
        );
      },
    );
  }
}
