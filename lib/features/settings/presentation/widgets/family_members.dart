import 'package:flutter/material.dart';

class FamilyMembers extends StatelessWidget {
  const FamilyMembers({super.key});

  @override
  Widget build(BuildContext context) {
    final members = [
      _FamilyMemberData(initials: 'JD', name: 'John Doe', color: const Color(0xFF93C5FD)),
      _FamilyMemberData(initials: 'AD', name: 'Alice Doe', color: const Color(0xFFC084FC)),
      _FamilyMemberData(initials: 'MD', name: 'Mary Doe', color: const Color(0xFFFDBA74)),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Members',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...members.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: m.color,
                          child: Text(
                            m.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.name,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  )),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Family management features are currently simulated.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add New',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark ? Colors.white30 : Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FamilyMemberData {
  const _FamilyMemberData({
    required this.initials,
    required this.name,
    required this.color,
  });

  final String initials;
  final String name;
  final Color color;
}
