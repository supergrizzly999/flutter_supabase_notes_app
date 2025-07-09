import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/berita_model.dart';
import 'user_sidebar.dart';
import 'menu.dart';
import 'simpan_berita_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Berita> _beritaList = [];
  List<Berita> _allBeritaList = [];
  List<int> _savedBeritaIds = [];
  bool _isLoading = true;

  String? _avatarUrl;
  String? _username;
  int _selectedIndex = 0;
  int? _expandedIndex;

  final String targetUserId = 'f31604ab-5389-4a01-bab8-041da6d8ac55';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBerita();
    _loadUserProfile();
    _fetchSavedBerita();
  }

  Future<void> _fetchBerita() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('berita')
          .select()
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false);

      _allBeritaList =
          (data as List).map((item) => Berita.fromJson(item)).toList();

      setState(() {
        _beritaList = _allBeritaList;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat berita: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSavedBerita() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('berita_disimpan')
          .select('berita_id')
          .eq('user_id', user.id);

      final ids = (response as List)
          .map((item) => item['berita_id'] as int)
          .toList();

      if (mounted) {
        setState(() {
          _savedBeritaIds = ids;
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil data berita yang disimpan: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    if (userId != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        _username = response['username'] ?? 'Pengguna';
        _avatarUrl = response['avatar_url'];
      });
    }
  }

  Future<void> _toggleSaveBerita(Berita berita) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'Anda belum login');
      return;
    }

    final isSaved = _savedBeritaIds.contains(berita.id);

    try {
      if (isSaved) {
        await Supabase.instance.client
            .from('berita_disimpan')
            .delete()
            .eq('user_id', user.id)
            .eq('berita_id', berita.id);

        Get.snackbar('Berhasil', 'Berita dihapus dari simpanan');
      } else {
        await Supabase.instance.client.from('berita_disimpan').insert({
          'user_id': user.id,
          'berita_id': berita.id,
          'created_at': DateTime.now().toIso8601String(),
        });

        Get.snackbar('Berhasil', 'Berita berhasil disimpan');
      }

      await _fetchSavedBerita();
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
    }
  }

  void _onBottomMenuTap(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Get.to(() => const SimpanBeritaScreen());
    }
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

  void _onSearchChanged(String query) {
    final keyword = query.toLowerCase();
    setState(() {
      _beritaList = _allBeritaList
          .where((berita) => berita.title.toLowerCase().contains(keyword))
          .toList();
    });
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
    final bool isSaved = _savedBeritaIds.contains(berita.id);

    return GestureDetector(
      onTap: () => _onCardTap(index, cardKey),
      child: AnimatedContainer(
        key: cardKey,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.15 * 255).toInt()),
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
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 120,
                          width: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 50),
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
                          fontSize: 18,
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
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.blue : Colors.grey[600],
                  ),
                  onPressed: () => _toggleSaveBerita(berita),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(
                berita.content,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
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
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Beranda',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                  child: _beritaList.isEmpty
                      ? const Center(child: Text('Berita tidak ditemukan.'))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _beritaList.length,
                          itemBuilder: (context, index) {
                            final berita = _beritaList[index];
                            return _buildBeritaCard(berita, index);
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
