import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../utils/logger.dart';
import '../../constants.dart';
// ✅ NUEVAS IMPORTACIONES DE TIENDA
import '../../screens/store_screen.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // ✅ NUEVO: Parámetro opcional para ver perfil de otros usuarios
  final bool isCurrentUser; // ✅ NUEVO: Indicador si es el usuario actual

  const ProfileScreen({
    super.key,
    this.userId,
    this.isCurrentUser = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      AppLogger.d('👤 Cargando perfil...');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String targetUserId;

      // ✅ DETERMINAR QUÉ USUARIO CARGAR
      if (widget.userId != null) {
        // Perfil de otro usuario
        targetUserId = widget.userId!;
        AppLogger.d('📱 Cargando perfil de usuario: $targetUserId');
      } else {
        // Perfil del usuario actual
        final currentUser = authProvider.currentUser;
        if (currentUser == null) {
          throw Exception('Usuario no autenticado');
        }
        targetUserId = currentUser.id;
        AppLogger.d('👤 Cargando perfil propio: $targetUserId');
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', targetUserId)
          .single();

      setState(() {
        _profileData = response;
        _isLoading = false;
      });

      AppLogger.d('✅ Perfil cargado exitosamente');
    } catch (e) {
      AppLogger.e('Error cargando perfil', e);
      setState(() {
        _error = 'Error al cargar perfil: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ NUEVO: Obtener título dinámico para AppBar
  String get _appBarTitle {
    if (_profileData != null && !widget.isCurrentUser) {
      return 'Perfil de ${_profileData!['username'] ?? 'Usuario'}';
    }
    return 'Mi Perfil';
  }

  Widget _buildProfileInfo() {
    if (_profileData == null) return const SizedBox();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: _profileData!['avatar_url'] != null
                      ? NetworkImage(_profileData!['avatar_url'] as String)
                      : null,
                  child: _profileData!['avatar_url'] == null
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey[600],
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profileData!['username'] as String? ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profileData!['email'] as String? ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // ✅ NUEVO: Badge de tienda si está habilitada
                      if (currentUser?.hasStore == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.store,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentUser!.storeBadge,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reputación: ${(_profileData!['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'}',
                                style: const TextStyle(
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
              ],
            ),
            
            // ✅ NUEVA SECCIÓN: Vista previa de tienda
            if (currentUser?.hasStore == true && widget.isCurrentUser) ...[
              const SizedBox(height: 16),
              _buildStorePreview(currentUser!),
            ],
            
            const SizedBox(height: 16),
            
            const Text(
              'Información de Contacto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Teléfono', _profileData!['phone'] as String? ?? 'No agregado'),
            _buildInfoRow('Miembro desde', _formatDate(_profileData!['created_at'])),
          ],
        ),
      ),
    );
  }

  // ✅ NUEVO MÉTODO: Vista previa de tienda en el perfil
  Widget _buildStorePreview(AppUser user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreScreen(
              userId: user.id,
              isCurrentUser: true,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.borderRadiusM),
          border: Border.all(color: AppColors.border),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner preview
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimens.borderRadiusM),
                  topRight: Radius.circular(AppDimens.borderRadiusM),
                ),
                image: user.storeBannerUrl != null
                    ? DecorationImage(
                        image: NetworkImage(user.storeBannerUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                // ignore: deprecated_member_use
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: user.storeBannerUrl == null
                  ? Center(
                      child: Icon(
                        Icons.storefront,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: AppDimens.paddingAllM,
              child: Row(
                children: [
                  // Logo preview
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadiusM),
                      border: Border.all(color: AppColors.border),
                      image: user.storeLogoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(user.storeLogoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.white,
                    ),
                    child: user.storeLogoUrl == null
                        ? Icon(
                            Icons.store,
                            size: 24,
                            color: AppColors.textSecondary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.storeDisplayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.storeStatsText,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              user.storeRatingText,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final dateTime = DateTime.parse(date);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
      return 'Fecha no disponible';
    } catch (e) {
      return 'Fecha no disponible';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle), // ✅ Título dinámico
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // ✅ SOLO MOSTRAR ACCIONES SI ES EL USUARIO ACTUAL
          if (widget.isCurrentUser) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
              tooltip: 'Editar Perfil',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadProfile,
              tooltip: 'Actualizar',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildProfileInfo(),
                      const SizedBox(height: 16),
                      // ✅ SOLO MOSTRAR ACCIONES SI ES EL USUARIO ACTUAL
                      if (widget.isCurrentUser) _buildActionsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildActionsSection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // ✅ NUEVA ACCIÓN: Mi Tienda
            _buildActionTile(
              icon: Icons.store,
              title: currentUser?.hasStore == true ? 'Mi Tienda' : 'Crear Tienda',
              subtitle: currentUser?.hasStore == true 
                  ? 'Gestionar mi tienda profesional' 
                  : 'Activar tienda profesional',
              onTap: () {
                if (currentUser?.hasStore == true) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreScreen(isCurrentUser: true),
                    ),
                  );
                } else {
                  Navigator.pushNamed(context, '/edit-store');
                }
              },
            ),
            
            _buildActionTile(
              icon: Icons.rate_review,
              title: 'Mis Calificaciones',
              subtitle: 'Ver mis reseñas y reputación',
              onTap: () {
                Navigator.pushNamed(context, '/ratings');
              },
            ),
            _buildActionTile(
              icon: Icons.shopping_bag,
              title: 'Mis Productos',
              subtitle: 'Gestionar mis productos publicados',
              onTap: () {
                _showComingSoonSnackbar();
              },
            ),
            _buildActionTile(
              icon: Icons.chat,
              title: 'Mis Mensajes',
              subtitle: 'Ver mis conversaciones',
              onTap: () {
                _showComingSoonSnackbar();
              },
            ),
            _buildActionTile(
              icon: Icons.settings,
              title: 'Configuración',
              subtitle: 'Ajustes de la cuenta',
              onTap: () {
                _showComingSoonSnackbar();
              },
            ),
            const Divider(),
            _buildActionTile(
              icon: Icons.logout,
              title: 'Cerrar Sesión',
              subtitle: 'Salir de tu cuenta',
              onTap: _logout,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[600]),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: Text(
        subtitle, 
        style: TextStyle(
          color: color != null 
              // ignore: deprecated_member_use
              ? color.withOpacity(0.7) 
              : Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚀 Función en desarrollo - Próximamente'),
        backgroundColor: Colors.black,
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authProvider = context.read<AuthProvider>();
        await authProvider.signOut();
        
        Navigator.pushNamedAndRemoveUntil(
          context, 
          AppRoutes.login, 
          (route) => false
        );
      } catch (e) {
        AppLogger.e('Error durante logout', e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}