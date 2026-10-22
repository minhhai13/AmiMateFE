import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class PlaceholderDestination {
  const PlaceholderDestination({
    required this.label,
    required this.routeName,
    this.pathParameters = const {},
    this.isPrimary = false,
  });

  final String label;
  final String routeName;
  final Map<String, String> pathParameters;
  final bool isPrimary;
}

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    required this.title,
    required this.description,
    required this.icon,
    this.destinations = const [],
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<PlaceholderDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Icon(icon, color: AppTheme.primary, size: 42),
                  ),
                  const SizedBox(height: 24),
                  Text(title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  Text(description, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 28),
                  for (final destination in destinations) ...[
                    if (destination.isPrimary)
                      FilledButton(
                        onPressed: () => context.pushNamed(
                          destination.routeName,
                          pathParameters: destination.pathParameters,
                        ),
                        child: Text(destination.label),
                      )
                    else
                      OutlinedButton(
                        onPressed: () => context.pushNamed(
                          destination.routeName,
                          pathParameters: destination.pathParameters,
                        ),
                        child: Text(destination.label),
                      ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
