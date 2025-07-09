import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_routes.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.blueGrey.shade900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: const [
                Icon(Icons.newspaper, color: Colors.white, size: 50),
                SizedBox(height: 8),
                Text(
                  'Breaking News',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white54),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.white),
            title: const Text('Pengguna', style: TextStyle(color: Colors.white)),
            onTap: () => Get.toNamed(AppRoutes.penggunaAdmin),
          ),
          ListTile(
            leading: const Icon(Icons.article, color: Colors.white),
            title: const Text('Berita', style: TextStyle(color: Colors.white)),
             onTap: () => Get.toNamed(AppRoutes.beritaList),
  
                      ),
          ListTile(
            leading: const Icon(Icons.bookmark, color: Colors.white),
            title: const Text('Data Disimpan', style: TextStyle(color: Colors.white)),
            onTap: () => Get.toNamed(AppRoutes.beritaDisimpanAdmin),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              Get.offAllNamed(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}
