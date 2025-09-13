import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BottomNavigation extends StatelessWidget {
  final String activePage;
  final Function(String) onPageChanged;

  const BottomNavigation({
    super.key,
    required this.activePage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final navItems = [
      {'id': 'home', 'icon': LucideIcons.home, 'label': 'Home'},
      {'id': 'record', 'icon': LucideIcons.heartPulse, 'label': 'Record'},
      {'id': 'history', 'icon': LucideIcons.history, 'label': 'History'},
      {'id': 'ai-insights', 'icon': LucideIcons.brainCircuit, 'label': 'AI Insights'},
      {'id': 'profile', 'icon': LucideIcons.user, 'label': 'Profile'},
    ];

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: navItems.map((item) {
            final isActive = activePage == item['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () => onPageChanged(item['id'] as String),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isActive 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
