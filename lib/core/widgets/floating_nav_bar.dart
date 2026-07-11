import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/glass_style.dart';
import 'glass_container.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouter.of(
      context,
    ).routeInformationProvider.value.uri.toString();
    final items = <_NavItem>[
      _NavItem(path: '/home', icon: LucideIcons.home, label: 'Home'),
      _NavItem(path: '/nfc-capture', icon: LucideIcons.scanLine, label: 'NFC'),
      _NavItem(
        path: '/network-simulator',
        icon: LucideIcons.network,
        label: 'Network',
      ),
      _NavItem(
        path: '/specialist',
        icon: LucideIcons.stethoscope,
        label: 'Specialist',
      ),
      _NavItem(
        path: '/settings',
        icon: LucideIcons.settings,
        label: 'Settings',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: items.map((item) {
            final isActive = currentPath == item.path;
            return Expanded(
              child: GestureDetector(
                onTap: () => context.go(item.path),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: isActive
                      ? BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(
                            kGlassBorderRadius / 2,
                          ),
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.path, required this.icon, required this.label});

  final String path;
  final IconData icon;
  final String label;
}
