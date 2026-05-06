import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Service/AuthService.dart';
import '../Layout/DetailArt.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final _supabase = Supabase.instance.client;
  String _userName = '';
  String _userBio = 'Official Art Curator';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() async {
    final profile = await _authService.getProfile();
    if (mounted) {
      setState(() {
        _userName = profile?['full_name'] ?? "Curator";
        _userBio = profile?['bio'] ?? "Official Art Curator";
        _isLoading = false;
      });
    }
  }

  // MODAL EDIT PROFILE & ACCOUNT
  void _showEditProfileSheet() {
    final nameController = TextEditingController(text: _userName);
    final bioController = TextEditingController(text: _userBio);
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "EDIT CURATOR PROFILE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              const Text(
                "FULL NAME",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "Your Name"),
              ),

              const SizedBox(height: 20),

              const Text(
                "CURATOR BIO",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(
                  hintText: "Tell us about your art taste",
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "NEW PASSWORD (OPTIONAL)",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  hintText: "Min 6 characters",
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 18,
                    ),
                    onPressed: () => setSheetState(
                      () => isPasswordVisible = !isPasswordVisible,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAC9362),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: () async {
                  final user = _supabase.auth.currentUser;
                  if (user == null) return;

                  try {
                    // 1. Update Profile (Name & Bio)
                    await _supabase
                        .from('profiles')
                        .update({
                          'full_name': nameController.text,
                          'bio': bioController.text,
                        })
                        .eq('id', user.id);

                    // 2. Update Password if filled
                    if (passwordController.text.isNotEmpty) {
                      await _supabase.auth.updateUser(
                        UserAttributes(password: passwordController.text),
                      );
                    }

                    setState(() {
                      _userName = nameController.text;
                      _userBio = bioController.text;
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile updated!")),
                    );
                  } catch (e) {
                    print("Error updating: $e");
                  }
                },
                child: const Text(
                  "SAVE CHANGES",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'CURATOR PROFILE',
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_outlined,
              color: Colors.black87,
              size: 20,
            ),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFAC9362)),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('bookmarks')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId ?? ''),
              builder: (context, snapshot) {
                final bookmarks = snapshot.data ?? [];

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              const CircleAvatar(
                                radius: 45,
                                backgroundColor: Color(0xFFF5F5F5),
                                child: Icon(
                                  Icons.person_outline,
                                  size: 40,
                                  color: Color(0xFFAC9362),
                                ),
                              ),
                              GestureDetector(
                                onTap: _showEditProfileSheet,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFAC9362),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userBio.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFAC9362),
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // SECTION KOLEKSI SAJA
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              border: Border.symmetric(
                                horizontal: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatColumn(
                                  bookmarks.length.toString(),
                                  "COLLECTIONS",
                                ),
                              ],
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 30, 24, 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'SAVED MASTERPIECES',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    bookmarks.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text(
                                  "No artworks saved yet.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.all(24),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 15,
                                    crossAxisSpacing: 15,
                                    childAspectRatio: 0.7,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildArtCard(bookmarks[index]),
                                childCount: bookmarks.length,
                              ),
                            ),
                          ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFAC9362),
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildArtCard(Map<String, dynamic> art) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetailArtPage(objectId: art['object_id']),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                    image: DecorationImage(
                      image: NetworkImage(art['image_url'] ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    await _supabase
                        .from('bookmarks')
                        .delete()
                        .eq('id', art['id']);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          art['title'] ?? 'Untitled',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          art['artist'] ?? 'Unknown Artist',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
