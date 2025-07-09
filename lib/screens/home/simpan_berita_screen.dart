import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/berita_model.dart';
import 'menu.dart';
import 'user_sidebar.dart';

class SimpanBeritaScreen extends StatefulWidget {
  const SimpanBeritaScreen({super.key});

  @override
  State<SimpanBeritaScreen> createState() => _SimpanBeritaScreenState();
}

class _SimpanBeritaScreenState extends State<SimpanBeritaScreen> {
  List<Berita> _savedBerita = [];
  List<Berita> _allSavedBerita = [];
  List<int> _savedBeritaIds = [];
  bool _isLoading = true;
  int _selectedIndex = 1;
  int? _expandedIndex;

  String? _avatarUrl;
  String? _username;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSavedBerita();
    _loadUserProfile();
  }

  Future<void> _fetchSavedBerita() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        Get.snackbar('Error', 'Anda belum login');
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('berita_disimpan')
          .select('berita_id, berita (id, user_id, title, content, image_url, created_at)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final beritaList = (data as List)
          .map((item) => Berita.fromJson(item['berita']))
          .toList();

      _savedBeritaIds = beritaList.map((b) => b.id).toList();

      if (!mounted) return;
      setState(() {
        _allSavedBerita = beritaList;
        _savedBerita = beritaList;
      });
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Gagal memuat berita: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    if (!mounted) return;
    setState(() {
      _username = response['username'] ?? 'Pengguna';
      _avatarUrl = response['avatar_url'];
    });
  }

  void _onSearchChanged(String query) {
    final keyword = query.toLowerCase();
    setState(() {
      _savedBerita = _allSavedBerita
          .where((berita) => berita.title.toLowerCase().contains(keyword))
          .toList();
    });
  }

  void _onCardTap(int index, GlobalKey key) {
    setState(() {
      _expandedIndex = (_expandedIndex == index) ? null : index;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  Future<void> _unsaveBerita(Berita berita) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('berita_disimpan')
          .delete()
          .eq('user_id', user.id)
          .eq('berita_id', berita.id);

      if (!mounted) return;
      setState(() {
        _savedBerita.removeWhere((b) => b.id == berita.id);
        _allSavedBerita.removeWhere((b) => b.id == berita.id);
        _savedBeritaIds.remove(berita.id);
      });

      if (mounted) {
        Get.snackbar('Berhasil', 'Berita dibatalkan dari simpanan');
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Gagal batal simpan: $e');
      }
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Cari berita berdasarkan judul...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBeritaCard(Berita berita, int index) {
    final isExpanded = _expandedIndex == index;
    final GlobalKey cardKey = GlobalKey();

    return GestureDetector(
      onTap: () => _onCardTap(index, cardKey),
      child: AnimatedContainer(
        key: cardKey,
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: berita.imageUrl != null
                      ? Image.network(
                          berita.imageUrl!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 40),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        berita.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Breaking News',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark, color: Colors.blue),
                  onPressed: () => _unsaveBerita(berita),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(
                berita.content,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onBottomMenuTap(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Get.back(); // Navigasi ke halaman sebelumnya
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: UserSidebar(
        isLoading: _isLoading,
        avatarUrl: _avatarUrl,
        username: _username,
        onProfileUpdated: _loadUserProfile,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 30),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const Text(
              'Berita Disimpan',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 75,
              width: 120,
              child: Image.network(
                'https://yveiqftpcacwvnqbxrco.supabase.co/storage/v1/object/public/berita-images/f31604ab-5389-4a01-bab8-041da6d8ac55/1750476285018.jpg',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _savedBerita.isEmpty
                      ? const Center(child: Text('Belum ada berita yang disimpan.'))
                      : ListView.builder(
                          itemCount: _savedBerita.length,
                          itemBuilder: (context, index) {
                            return _buildBeritaCard(_savedBerita[index], index);
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: BottomMenu(
        selectedIndex: _selectedIndex,
        onTap: _onBottomMenuTap,
      ),
    );
  }
}
