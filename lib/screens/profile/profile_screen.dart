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
import 'package:libre_mercado_final__app/models/product_model.dart';

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
                leading: const Icon(Icons.edit, color: Colors.amber),
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
                leading: const Icon(Icons.star, color: Colors.amber),
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
                leading: const Icon(Icons.settings, color: Colors.amber),
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

  void _showVerificationInfo() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    showDialog(
      context: context,
      builder: (context) => VerificationDialog(
        currentUser: currentUser,
        onSubmit: _submitVerificationRequest,
      ),
    );
  }

  Future<bool> _submitVerificationRequest(AppUser user) async {
    try {
      // Aquí iría la lógica real para enviar la solicitud de verificación
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
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
                (route) => false,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Minimalista
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
                if (isOwnProfile)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Información Básica
            Column(
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),

            // Información de Contacto
            if (isOwnProfile || user.hasContactInfo) ...[
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.grey[200],
                margin: const EdgeInsets.symmetric(vertical: 16),
              ),
              Column(
                children: [
                  // Email
                  if (user.email.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.email_outlined, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Teléfono
                  if (user.phone != null && user.phone!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.phone_outlined, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Teléfono',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.phone!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],

            // Estado de Verificación
            const SizedBox(height: 16),
            GestureDetector(
              onTap: isOwnProfile ? _showVerificationInfo : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: user.isVerified == true ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: user.isVerified == true ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.isVerified == true ? Icons.verified : Icons.pending_actions,
                      size: 18,
                      color: user.isVerified == true ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.verificationText,
                      style: TextStyle(
                        color: user.isVerified == true ? Colors.green : Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isOwnProfile) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: user.isVerified == true ? Colors.green : Colors.orange,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildProductStats(List<Product> userProducts, int availableProducts, int soldProducts) {
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

// Diálogo de Verificación - COMPLETAMENTE CORREGIDO SIN OVERFLOW
class VerificationDialog extends StatefulWidget {
  final AppUser? currentUser;
  final Future<bool> Function(AppUser) onSubmit;

  const VerificationDialog({
    super.key,
    required this.currentUser,
    required this.onSubmit,
  });

  @override
  State<VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<VerificationDialog> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.amber[700], size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Verificación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contenido con scroll
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.currentUser?.isVerified == true 
                              ? Colors.green[50] 
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.currentUser?.isVerified == true 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.currentUser?.isVerified == true 
                                  ? Icons.verified 
                                  : Icons.pending_actions,
                              color: widget.currentUser?.isVerified == true 
                                  ? Colors.green 
                                  : Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.currentUser?.isVerified == true 
                                        ? 'Verificado' 
                                        : 'Pendiente',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: widget.currentUser?.isVerified == true 
                                          ? Colors.green 
                                          : Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    widget.currentUser?.isVerified == true 
                                        ? 'Perfil verificado' 
                                        : 'Solicita verificación',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Información
                      _buildSection(
                        title: '¿Qué es la verificación?',
                        content: 'Ayuda a generar confianza en la comunidad. Usuarios verificados tienen mayor credibilidad.',
                      ),

                      // Beneficios
                      _buildSection(
                        title: 'Beneficios',
                        content: '',
                      ),
                      _buildBenefitItem('Mayor credibilidad'),
                      _buildBenefitItem('Más transacciones exitosas'),
                      _buildBenefitItem('Acceso a funciones premium'),
                      _buildBenefitItem('Sello de confianza'),
                      const SizedBox(height: 12),

                      // Requisitos
                      _buildSection(
                        title: 'Requisitos',
                        content: '',
                      ),
                      _buildRequirementItem('Email verificado', true),
                      _buildRequirementItem('Teléfono registrado', widget.currentUser?.phone != null),
                      _buildRequirementItem('3+ transacciones', false),
                      _buildRequirementItem('Buena reputación', true),
                    ],
                  ),
                ),
              ),

              // Botones
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (widget.currentUser?.isVerified != true && widget.currentUser != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : () => _submitVerification(),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                ),
                              )
                            : const Text(
                                'Solicitar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: completed ? Colors.green[600] : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: completed ? Colors.green[600] : Colors.grey[600],
                decoration: completed ? TextDecoration.lineThrough : null,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVerification() async {
    setState(() => _isSubmitting = true);
    
    try {
      final success = await widget.onSubmit(widget.currentUser!);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? '✅ Solicitud enviada' 
                : '❌ Error al enviar'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}