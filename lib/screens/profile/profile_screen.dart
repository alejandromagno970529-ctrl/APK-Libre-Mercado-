import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/reputation_provider.dart';
import '../../providers/service_provider.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../models/rating_model.dart';
import '../../screens/profile/edit_profile_screen.dart';
// ignore: unused_import
import '../../screens/profile/profile_screen_services.dart';
import '../../screens/product/product_detail_screen.dart';
import '../../services/verification_service.dart';
import '../../widgets/verification_status_widget.dart';
import '../../utils/logger.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final bool isCurrentUser;

  const ProfileScreen({
    super.key,
    this.userId,
    this.isCurrentUser = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppUser? _targetUser;
  bool _isLoadingProfile = false;
  // ignore: unused_field
  File? _verificationImage;
  // ignore: unused_field
  bool _isUploadingVerification = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final authProvider = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();
    final reputationProvider = context.read<ReputationProvider>();
    final serviceProvider = context.read<ServiceProvider>();

    String targetId;

    if (widget.isCurrentUser) {
      targetId = authProvider.currentUser?.id ?? '';
      _targetUser = authProvider.currentUser;
    } else {
      targetId = widget.userId ?? '';
      setState(() => _isLoadingProfile = true);
      _targetUser = await authProvider.getUserProfile(targetId);
      setState(() => _isLoadingProfile = false);
    }

    if (targetId.isNotEmpty) {
      await productProvider.fetchUserProducts(targetId);
      await reputationProvider.getUserRatings(targetId);
      if (widget.isCurrentUser) {
        await serviceProvider.fetchMyServices(targetId);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickVerificationImage(StateSetter modalSetState, Function(File) onImageSelected) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        modalSetState(() {
          onImageSelected(File(image.path));
        });
      }
    } catch (e) {
      AppLogger.e('Error seleccionando imagen de verificación', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _submitVerification(
    BuildContext modalContext, 
    AppUser user, 
    String name, 
    String idNumber, 
    String address, 
    File documentImage
  ) async {
    setState(() => _isUploadingVerification = true);

    try {
      showDialog(
        context: modalContext,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.black)),
      );

      final verificationService = VerificationService(Supabase.instance.client);
      final documentPath = await verificationService.uploadVerificationDocument(
        documentImage,
        user.id,
      );

      // ignore: use_build_context_synchronously
      final authProvider = context.read<AuthProvider>();
      await authProvider.submitVerification(
        userId: user.id,
        documentUrl: documentPath,
        fullName: name,
        nationalId: idNumber,
        address: address,
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(modalContext);
      // ignore: use_build_context_synchronously
      Navigator.pop(modalContext);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Solicitud enviada. Revisaremos tus documentos pronto.'),
            backgroundColor: Colors.green,
          ),
        );
        
        await authProvider.loadUserProfile(user.id);
        setState(() {
          _targetUser = authProvider.currentUser;
        });
      }

    } catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.pop(modalContext);
      AppLogger.e('Error enviando verificación', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar la solicitud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingVerification = false);
      _verificationImage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().currentUser;
    final serviceProvider = context.watch<ServiceProvider>();
    final userToShow = widget.isCurrentUser ? authUser : _targetUser;

    if (userToShow == null || _isLoadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    final hasServices = serviceProvider.myServices.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, userToShow, hasServices),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (widget.isCurrentUser && !userToShow.isVerificationVerified)
                    VerificationStatusWidget(user: userToShow),
                  
                  userToShow.hasStore 
                      ? _buildStoreHeader(context, userToShow) 
                      : _buildStandardHeader(context, userToShow),
                ],
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.black,
                  indicatorWeight: 2.0,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on_sharp, size: 24)),
                    Tab(icon: Icon(Icons.star_border_outlined, size: 26)),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsGrid(userToShow),
            _buildReputationList(userToShow),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, AppUser user, bool hasServices) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: !widget.isCurrentUser 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        user.hasStore ? user.storeDisplayName : user.username,
        style: const TextStyle(
          color: Colors.black, 
          fontWeight: FontWeight.bold,
          fontSize: 18
        ),
      ),
      actions: widget.isCurrentUser ? [
        // Opción para ir a servicios si es proveedor
        if (hasServices)
          IconButton(
            icon: const Icon(Icons.work_outline_rounded, color: Colors.black),
            onPressed: () => _navigateToServiceProviderProfile(context),
            tooltip: 'Mis servicios',
          ),
        IconButton(
          icon: const Icon(Icons.add_box_outlined, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, '/add-product'),
          tooltip: 'Crear publicación',
        ),
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _showCompleteMenu(context, user, hasServices),
        ),
      ] : [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStandardHeader(BuildContext context, AppUser user) {
    final serviceProvider = context.watch<ServiceProvider>();
    final hasServices = serviceProvider.myServices.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(user.avatarUrl, size: 86, isStore: false),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("Productos", user.actualProductCount ?? 0),
                    _buildStatItem("Servicios", serviceProvider.myServices.length),
                    _buildStatItem("Rating", user.rating?.toStringAsFixed(1) ?? "N/A"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                user.username,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (user.isVerified == true) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: Colors.blue, size: 16),
              ]
            ],
          ),
          if (user.bio != null && user.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(user.bio!, style: const TextStyle(fontSize: 14)),
            ),
          const SizedBox(height: 16),
          _buildActionButtons(user, hasServices),
        ],
      ),
    );
  }

  Widget _buildStoreHeader(BuildContext context, AppUser user) {
    final serviceProvider = context.watch<ServiceProvider>();
    final hasServices = serviceProvider.myServices.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 140,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: user.storeBannerUrl != null
              ? CachedNetworkImage(
                  imageUrl: user.storeBannerUrl!,
                  fit: BoxFit.cover,
                  placeholder: (c, url) => Container(color: Colors.grey.shade200),
                  errorWidget: (c, u, e) => Icon(Icons.store, color: Colors.grey.shade400, size: 40),
                )
              : Icon(Icons.store_mall_directory, color: Colors.grey.shade300, size: 50),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildAvatar(user.storeLogoUrl ?? user.avatarUrl, size: 84, isStore: true),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12), 
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem("Productos", user.storeTotalProducts),
                            _buildStatItem("Servicios", serviceProvider.myServices.length),
                            _buildStatItem("Rating", user.storeRatingText),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Transform.translate(
                offset: const Offset(0, -30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.storeDisplayName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                        const SizedBox(width: 6),
                        if (user.isVerified == true)
                          const Icon(Icons.verified, color: Colors.blue, size: 18),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.storeBadge.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (user.storeDescription != null)
                      Text(
                        user.storeDescription!,
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                      ),
                    if (user.storeLocationText != 'Ubicación no especificada')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(user.storeLocationText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildActionButtons(user, hasServices),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductsGrid(AppUser user) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final userProducts = provider.userProducts
            .where((p) => p.userId == user.id)
            .toList();

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black));
        }

        if (userProducts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.grid_off,
            title: "Sin publicaciones",
            subtitle: widget.isCurrentUser 
              ? "¡Sube tu primer producto!" 
              : "Este usuario aún no tiene productos.",
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(top: 2),
          physics: const NeverScrollableScrollPhysics(), 
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1, 
          ),
          itemCount: userProducts.length,
          itemBuilder: (context, index) {
            final product = userProducts[index];
            return _ProfileGridItem(
              product: product,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReputationList(AppUser user) {
    return Consumer<ReputationProvider>(
      builder: (context, provider, _) {
        final ratings = provider.userRatings;

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black));
        }

        if (ratings.isEmpty) {
          return _buildEmptyState(
            icon: Icons.star_border,
            title: "Sin calificaciones",
            subtitle: "Aún no hay reseñas para este perfil.",
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ratings.length,
          separatorBuilder: (c, i) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final map = ratings[index];
            final rating = Rating.fromMap(map);
            final fromUserMap = map['from_user'] as Map<String, dynamic>?;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: fromUserMap?['avatar_url'] != null 
                          ? NetworkImage(fromUserMap!['avatar_url']) 
                          : null,
                      child: fromUserMap?['avatar_url'] == null 
                          ? const Icon(Icons.person, size: 18, color: Colors.grey) 
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fromUserMap?['username'] ?? 'Usuario',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < rating.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(rating.createdAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                if (rating.comment != null && rating.comment!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 42),
                    child: Text(rating.comment!, style: const TextStyle(fontSize: 14)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCompleteMenu(BuildContext context, AppUser user, bool hasServices) {
    final authProvider = context.read<AuthProvider>();
    // ignore: unused_local_variable
    final serviceProvider = context.read<ServiceProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 4, width: 40,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            
            // Opción para ser proveedor de servicios
            if (!hasServices)
              ListTile(
                leading: const Icon(Icons.work_outline_rounded, color: Colors.black),
                title: const Text("Ser Proveedor de Servicios"),
                subtitle: const Text("Ofrece servicios profesionalmente"),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToServiceOnboarding(context);
                },
              ),
            
            // Opción para ir al perfil de proveedor (si ya tiene servicios)
            if (hasServices)
              ListTile(
                leading: const Icon(Icons.work_history_rounded, color: Colors.black),
                title: const Text("Mi perfil de proveedor"),
                subtitle: const Text("Gestiona tus servicios y portafolio"),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToServiceProviderProfile(context);
                },
              ),
            
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded, color: Colors.black),
              title: const Text("Panel de Negocio"),
              subtitle: const Text("Ver estadísticas gráficas"),
              onTap: () {
                Navigator.pop(context);
                _showBusinessStatsSheet(context, user);
              },
            ),

            ListTile(
              leading: Icon(user.hasStore ? Icons.storefront : Icons.add_business, color: Colors.black),
              title: Text(user.hasStore ? "Configuración de Tienda" : "Convertir en Tienda"),
              subtitle: Text(user.hasStore ? "Administrar tu tienda" : "Vende profesionalmente"),
              onTap: () {
                Navigator.pop(context);
                _showStoreSettingsDialog(context, authProvider, user);
              },
            ),

            ListTile(
              leading: Icon(
                user.isVerificationVerified ? Icons.verified : Icons.verified_outlined, 
                color: user.isVerificationVerified ? Colors.blue : Colors.black
              ),
              title: const Text("Verificación de Cuenta"),
              subtitle: Text(user.isVerificationVerified ? "Cuenta verificada" : "Solicitar verificación"),
              onTap: () {
                Navigator.pop(context);
                _handleVerificationAction(context, user);
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                authProvider.signOut();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
            )
          ],
        ),
      ),
    );
  }

  void _showBusinessStatsSheet(BuildContext context, AppUser user) {
    final productProvider = context.read<ProductProvider>();
    final serviceProvider = context.read<ServiceProvider>();
    
    final userProducts = productProvider.userProducts.where((p) => p.userId == user.id).toList();
    final availableProducts = userProducts.where((p) => p.disponible).length;
    final soldProducts = userProducts.where((p) => !p.disponible).length;
    final servicesCount = serviceProvider.myServices.length;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '📊 Panel de Negocio',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            
            // Estadísticas principales
            _buildStatCard(
              icon: Icons.shopping_bag,
              title: 'Productos Activos',
              value: availableProducts.toString(),
              color: Colors.green,
            ),
            
            const SizedBox(height: 12),
            _buildStatCard(
              icon: Icons.work_outline_rounded,
              title: 'Servicios Activos',
              value: servicesCount.toString(),
              color: Colors.blue,
            ),
            
            const SizedBox(height: 12),
            _buildStatCard(
              icon: Icons.attach_money,
              title: 'Productos Vendidos',
              value: soldProducts.toString(),
              color: Colors.orange,
            ),
            
            const SizedBox(height: 12),
            _buildStatCard(
              icon: Icons.star,
              title: 'Rating Promedio',
              value: user.rating?.toStringAsFixed(1) ?? '0.0',
              color: Colors.amber,
            ),
            
            const SizedBox(height: 24),
            const Text(
              '📈 Estadísticas gráficas próximamente...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cerrar Panel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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

  void _showStoreSettingsDialog(BuildContext context, AuthProvider authProvider, AppUser user) {
    if (user.hasStore) {
      // Navegar a la pantalla de edición de tienda
      Navigator.pushNamed(context, '/edit-store');
    } else {
      // Mostrar diálogo para convertir en tienda
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🏪 Convertir en Tienda'),
          content: const Text(
            '¿Quieres convertir tu perfil en una tienda profesional?\n\n'
            'Beneficios:\n'
            '✅ Logo y banner personalizados\n'
            '✅ Información de contacto\n'
            '✅ Estadísticas de ventas\n'
            '✅ Mayor visibilidad\n'
            '✅ Catálogo organizado',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/edit-store');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Convertir en Tienda'),
            ),
          ],
        ),
      );
    }
  }

  void _handleVerificationAction(BuildContext context, AppUser user) {
    if (user.isVerificationVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Tu cuenta ya está verificada"))
      );
      return;
    }

    if (user.isVerificationPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📋 Tu verificación está en revisión"))
      );
      return;
    }

    _showVerificationModal(context, user);
  }

  void _showVerificationModal(BuildContext context, AppUser user) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    File? verificationImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user, size: 50, color: Colors.black),
                      const SizedBox(height: 16),
                      const Text(
                        'Verificación de Identidad',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Protege la comunidad subiendo una foto de tu documento de identidad',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildVerificationField('Nombre Completo', Icons.person, nameController),
                      const SizedBox(height: 16),
                      _buildVerificationField('Número de Identidad', Icons.badge, idController, isNumber: true),
                      const SizedBox(height: 16),
                      _buildVerificationField('Dirección', Icons.home, addressController),
                      
                      const SizedBox(height: 24),
                      const Text(
                        'Foto del Documento de Identidad',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      GestureDetector(
                        onTap: () => _pickVerificationImage(modalSetState, (file) {
                          verificationImage = file;
                        }),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: verificationImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(verificationImage!, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, size: 40, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Toca para subir documento', 
                                      style: TextStyle(color: Colors.grey[600])
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate() && verificationImage != null) {
                              _submitVerification(
                                modalContext,
                                user,
                                nameController.text,
                                idController.text,
                                addressController.text,
                                verificationImage!,
                              );
                            } else if (verificationImage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Por favor, sube una foto de tu documento')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('ENVIAR SOLICITUD'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerificationField(
    String label, 
    IconData icon, 
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Este campo es obligatorio';
        return null;
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight > 0 ? constraints.maxHeight : 300),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: Icon(icon, size: 40, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 16),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 8),
                    Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildAvatar(String? url, {required double size, required bool isStore}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1), 
            blurRadius: 4, 
            offset: const Offset(0, 2)
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        backgroundImage: url != null ? CachedNetworkImageProvider(url) : null,
        child: url == null 
            ? Icon(isStore ? Icons.store : Icons.person, size: size * 0.5, color: Colors.grey) 
            : null,
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildActionButtons(AppUser user, bool hasServices) {
    if (widget.isCurrentUser) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  text: "Editar perfil",
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const EditProfileScreen())
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  text: "Compartir",
                  onTap: () {}, 
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Botón para ser proveedor si no tiene servicios
          if (!hasServices)
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                text: "Ser Proveedor de Servicios",
                onTap: () => _navigateToServiceOnboarding(context),
                isPrimary: true,
              ),
            ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              text: "Contactar",
              isPrimary: true,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: _ActionButton(text: "Seguir", onTap: null),
          ),
        ],
      );
    }
  }

  void _navigateToServiceOnboarding(BuildContext context) {
    Navigator.pushNamed(context, '/service-provider-onboarding');
  }

  void _navigateToServiceProviderProfile(BuildContext context) {
    Navigator.pushNamed(context, '/service-provider-profile');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 30) return "${date.day}/${date.month}/${date.year}";
    if (diff.inDays > 0) return "Hace ${diff.inDays}d";
    if (diff.inHours > 0) return "Hace ${diff.inHours}h";
    return "Ahora";
  }
}

// -----------------------------------------------------------------------------
// WIDGETS INTERNOS PEQUEÑOS
// -----------------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _ActionButton({required this.text, this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.black : Colors.grey[100],
        foregroundColor: isPrimary ? Colors.white : Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _ProfileGridItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProfileGridItem({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImages = product.imagenUrls != null && product.imagenUrls!.isNotEmpty;
    final isSold = !product.disponible;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.grey.shade200,
            child: hasImages
                ? CachedNetworkImage(
                    imageUrl: product.imagenUrl!, 
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: Colors.grey.shade200),
                    errorWidget: (c, u, e) => const Icon(Icons.error, size: 20, color: Colors.grey),
                  )
                : const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
          ),
          if (isSold)
            Container(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Text(
                  "VENDIDO",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          if (hasImages && product.imagenUrls!.length > 1)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.filter_none, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}