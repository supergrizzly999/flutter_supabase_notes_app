import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_screen.dart';
import 'simpan_berita_screen.dart';

class BottomMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomMenu({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        onTap(index);
        if (index == 0 && selectedIndex != 0) {
          Get.offAll(() => const HomeScreen());
        } else if (index == 1 && selectedIndex != 1) {
          Get.offAll(() => const SimpanBeritaScreen());
        }
      },
      selectedItemColor: const Color.fromRGBO(254, 31, 2, 0.506),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border),
          activeIcon: Icon(Icons.bookmark),
          label: 'Simpan',
        ),
      ],
    );
  }
}
