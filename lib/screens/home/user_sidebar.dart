import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/app_routes.dart';

class UserSidebar extends StatelessWidget {
  final bool isLoading;
  final String? avatarUrl;
  final String? username;
  final VoidCallback onProfileUpdated;

  const UserSidebar({
    super.key,
    required this.isLoading,
    required this.avatarUrl,
    required this.username,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240, // Sidebar diperkecil
      child: Drawer(
        child: Column(
          children: [
            const SizedBox(height: 40),
            isLoading
                ? const CircularProgressIndicator()
                : CircleAvatar(
                    radius: 50, // Foto profil diperbesar
                    backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? NetworkImage(avatarUrl!)
                        : const NetworkImage('https://via.placeholder.com/150'),
                    child: (avatarUrl == null || avatarUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
            const SizedBox(height: 10),
            Text(
              username ?? 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextButton(
              onPressed: () async {
                final result = await Get.toNamed(AppRoutes.profile);
                if (result == true) {
                  onProfileUpdated();
                }
              },
              child: const Text('Edit Profil'),
            ),
            const Divider(),
            ListTile(
              title: const Text('Logout'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Get.offAllNamed(AppRoutes.splash);
              },
            ),
          ],
        ),
      ),
    );
  }
}
