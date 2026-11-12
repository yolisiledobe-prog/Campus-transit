import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class StudentBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const StudentBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    const color = AppPalette.navy;

    Widget item(int index, IconData icon, String label) {
      final selected = index == currentIndex;
      return Expanded(
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? color : AppPalette.mutedText,
                size: 23,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? color : AppPalette.mutedText,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return BottomAppBar(
      color: AppPalette.cream,
      elevation: 10,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            item(0, Icons.home_outlined, 'Home'),
            item(1, Icons.search, 'Explore'),
            const Expanded(child: SizedBox()),
            item(3, Icons.schedule_outlined, 'Bus schedule'),
            item(4, Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }
}
