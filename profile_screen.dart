import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/providers/reputation_provider.dart';
import 'package:libre_mercado_final__app/widgets/reputation_stats_widget.dart';
import 'package:libre_mercado_final__app/screens/profile/edit_profile_screen.dart';
import 'package:libre_mercado_final__app/screens/reputation/ratings_list_screen.dart';
import 'package:libre_mercado_final__app/models/user_model.dart';
import 'package:libre_mercado_final__app/models/rating_model.dart';
import 'package:libre_mercado_final__app/models/product_model.dart'; // ✅ AGREGAR IMPORT

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.userId != null) {
      final reputationProvider = context.read<ReputationProvider>();
      await reputationProvider.getUserRatings(widget.userId!);
    }
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Mis Valoraciones'),
                onTap: () {
                  Navigator.pop(context);
                  final authProvider = context.read<AuthProvider>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RatingsListScreen(
                        userId: authProvider.userId ?? '',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuración - En desarrollo')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final reputationProvider = context.watch<ReputationProvider>();
    
    final isOwnProfile = widget.userId == null || widget.userId == authProvider.currentUser?.id;
    final currentUser = authProvider.currentUser;

    if (currentUser == null && isOwnProfile) {
      return _buildNotLoggedIn();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'Mi Perfil' : 'Perfil de Usuario'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
      body: authProvider.currentUser == null
          ? _buildNotLoggedIn()
          : _buildProfileContent(authProvider, productProvider, reputationProvider, isOwnProfile),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Inicia sesión para ver tu perfil',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
            ),
            child: const Text('INICIAR SESIÓN'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(AuthProvider authProvider, ProductProvider productProvider, ReputationProvider reputationProvider, bool isOwnProfile) {
    final user = authProvider.currentUser!;
    final userProducts = productProvider.userProducts;
    final availableProducts = userProducts.where((p) => p.disponible).length;
    final soldProducts = userProducts.length - availableProducts;

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header del Perfil
            _buildProfileHeader(user, isOwnProfile),
            const SizedBox(height: 20),

            // Estadísticas de Reputación
            ReputationStatsWidget(
              user: user,
              showDetails: true,
            ),
            const SizedBox(height: 16),

            // Valoraciones Recientes
            _buildRecentRatings(reputationProvider, isOwnProfile, user.id),
            const SizedBox(height: 16),

            // Estadísticas de Productos (solo perfil propio)
            if (isOwnProfile) _buildProductStats(userProducts, availableProducts, soldProducts),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user, bool isOwnProfile) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.amber[100],
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.amber[700],
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Información Básica
            Text(
              user.username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            if (user.bio != null && user.bio!.isNotEmpty) ...[
              Text(
                user.bio!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Información de Contacto (solo perfil propio o si el usuario lo permite)
            if (isOwnProfile || user.hasContactInfo) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (user.email.isNotEmpty)
                    _buildContactInfo(Icons.email, user.email),
                  if (user.phone != null && user.phone!.isNotEmpty)
                    _buildContactInfo(Icons.phone, user.phone!),
                ],
              ),
            ],

            // Estado de Verificación
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.isVerified == true ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: user.isVerified == true ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user.isVerified == true ? Icons.verified : Icons.pending,
                    size: 16,
                    color: user.isVerified == true ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.verificationText,
                    style: TextStyle(
                      color: user.isVerified == true ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRecentRatings(ReputationProvider reputationProvider, bool isOwnProfile, String currentUserId) {
    final ratings = reputationProvider.userRatings;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Valoraciones Recientes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (ratings.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RatingsListScreen(
                            userId: isOwnProfile 
                                ? currentUserId
                                : widget.userId!,
                          ),
                        ),
                      );
                    },
                    child: const Text('Ver todas'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (ratings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Aún no hay valoraciones',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: ratings.take(3).map((rating) => _buildRatingItem(rating)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingItem(Rating rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Estrellas
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              const Spacer(),
              Text(
                _formatDate(rating.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rating.comment != null && rating.comment!.isNotEmpty)
            Text(
              rating.comment!,
              style: const TextStyle(fontSize: 14),
            ),
          const SizedBox(height: 4),
          Text(
            'De: ${rating.fromUserName ?? 'Usuario'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductStats(List<Product> userProducts, int availableProducts, int soldProducts) { // ✅ CORREGIDO
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shopping_bag, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'Mis Productos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProductStat('Total', userProducts.length, Icons.list),
                _buildProductStat('Disponibles', availableProducts, Icons.check_circle),
                _buildProductStat('Vendidos', soldProducts, Icons.sell),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductStat(String label, int count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.amber, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Hoy';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}