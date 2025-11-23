// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/reputation_provider.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../models/rating_model.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/product/product_detail_screen.dart';
import '../../services/verification_service.dart'; // ✅ NUEVO SERVICIO
import '../../utils/logger.dart'; // Asegúrate de importar tu logger

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
  // ✅ Estado para la selección de imagen de verificación
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
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Método para seleccionar imagen
  Future<void> _pickVerificationImage(StateSetter modalSetState) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200, // Buena calidad para documentos
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        modalSetState(() {
          _verificationImage = File(image.path);
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

  // ✅ Método para subir y finalizar la verificación
  Future<void> _submitVerification(BuildContext modalContext, AppUser user, String name, String idNumber, String address) async {
    if (_verificationImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, sube una foto de tu documento.')),
      );
      return;
    }

    // Usamos el StateSetter del diálogo para mostrar el progreso
    // Esto requiere pasar el StateSetter desde el builder del showModalBottomSheet
    // Como alternativa más simple, usaremos una variable global temporal para este ejemplo
    
    // En un caso real, lo ideal es manejar esto con un Provider.

    try {
      // Mostrar indicador de carga
      showDialog(
        context: modalContext,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.black)),
      );

      final verificationService = VerificationService(Supabase.instance.client);
      
      // 1. Subir la imagen
      final documentPath = await verificationService.uploadVerificationDocument(
        _verificationImage!,
        user.id,
      );

      // 2. Actualizar el perfil en Supabase con los datos y la ruta del documento
      // NOTA: Necesitarás añadir los campos 'first_name', 'last_name', 'national_id', 'address' a tu tabla 'profiles'
      // si quieres guardar estos datos específicos.
      // Por ahora, guardaremos la ruta del documento y actualizaremos el estado.
      
      final supabase = Supabase.instance.client;
      await supabase.from('profiles').update({
        'verification_status': 'pending',
        'verification_document_url': documentPath,
        'verification_submitted_at': DateTime.now().toIso8601String(),
        // Descomenta y adapta si decides añadir los campos de texto a tu tabla
        // 'full_name': name,
        // 'national_id_number': idNumber,
        // 'address': address,
      }).eq('id', user.id);

      // Cerrar el diálogo de carga
      Navigator.pop(modalContext);
      // Cerrar el modal de verificación
      Navigator.pop(modalContext);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Solicitud enviada. Revisaremos tus documentos pronto.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar el perfil para reflejar el nuevo estado
        final authProvider = context.read<AuthProvider>();
        await authProvider.loadUserProfile(user.id);
        setState(() {
          _targetUser = authProvider.currentUser;
        });
      }

    } catch (e) {
      // Cerrar el diálogo de carga si hubo error
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
      // Limpiar la imagen seleccionada
      _verificationImage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().currentUser;
    final userToShow = widget.isCurrentUser ? authUser : _targetUser;

    if (userToShow == null || _isLoadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, userToShow),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: userToShow.hasStore 
                  ? _buildStoreHeader(context, userToShow) 
                  : _buildStandardHeader(context, userToShow),
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

  // ---------------------------------------------------------------------------
  // APP BAR & MENÚ
  // ---------------------------------------------------------------------------
  AppBar _buildAppBar(BuildContext context, AppUser user) {
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
        IconButton(
          icon: const Icon(Icons.add_box_outlined, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, '/add-product'),
          tooltip: 'Crear publicación',
        ),
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _showCompleteMenu(context, user),
        ),
      ] : [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CABECERAS (STANDARD & STORE)
  // ---------------------------------------------------------------------------
  Widget _buildStandardHeader(BuildContext context, AppUser user) {
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
                    _buildStatItem("Ventas", user.successfulTransactions ?? 0),
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
          _buildActionButtons(user),
        ],
      ),
    );
  }

  Widget _buildStoreHeader(BuildContext context, AppUser user) {
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
                            _buildStatItem("Ventas", user.storeTotalSales),
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
                    _buildActionButtons(user),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PESTAÑA 1: GRILLA DE PRODUCTOS
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // PESTAÑA 2: REPUTACIÓN
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // MENÚ Y FUNCIONALIDADES AVANZADAS
  // ---------------------------------------------------------------------------
  void _showCompleteMenu(BuildContext context, AppUser user) {
    final authProvider = context.read<AuthProvider>();
    
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
                user.isVerified == true ? Icons.verified : Icons.verified_outlined, 
                color: user.isVerified == true ? Colors.blue : Colors.black
              ),
              title: const Text("Verificación de Cuenta"),
              subtitle: Text(user.isVerified == true ? "Cuenta verificada" : "Solicitar verificación"),
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

  // GRÁFICO DE NEGOCIO (CORREGIDO)
  void _showBusinessStatsSheet(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.55, 
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Rendimiento del Negocio", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Resumen visual de los últimos 7 días", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = (constraints.maxWidth / 7) * 0.6;
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final heights = [0.3, 0.7, 0.4, 0.9, 0.5, 0.8, 0.6]; 
                        final days = ["L", "M", "X", "J", "V", "S", "D"];
                        final isToday = index == 6;
                        
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: barWidth,
                              height: constraints.maxHeight * heights[index] * 0.8, 
                              decoration: BoxDecoration(
                                color: isToday ? Colors.black : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              days[index], 
                              style: TextStyle(
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? Colors.black : Colors.grey
                              )
                            ),
                          ],
                        );
                      }),
                    );
                  }
                ),
              ),
              
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBusinessMetric("Ventas Totales", "${user.successfulTransactions ?? 0}"),
                    _buildBusinessMetric("Ingresos (Est.)", "\$${(user.successfulTransactions ?? 0) * 150}"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  // DIÁLOGO DE TIENDA (CORREGIDO)
  void _showStoreSettingsDialog(BuildContext context, AuthProvider authProvider, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(user.hasStore ? "Configuración" : "Activar Tienda"),
        content: Text(user.hasStore 
          ? "¿Deseas desactivar el modo tienda? Tus productos seguirán visibles pero perderás el banner."
          : "Al activar el modo tienda, tendrás un banner personalizado, estadísticas y un badge profesional."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          if (user.hasStore)
            TextButton(
              onPressed: () async {
                await authProvider.updateStoreProfile(
                  storeName: user.storeName ?? '',
                  storeDescription: user.storeDescription,
                  storeCategory: user.storeCategory,
                  storeAddress: user.storeAddress,
                  storePhone: user.storePhone,
                  storeEmail: user.storeEmail,
                  storeWebsite: user.storeWebsite,
                  storePolicy: user.storePolicy,
                  storeLogoUrl: user.storeLogoUrl,
                  storeBannerUrl: user.storeBannerUrl,
                  isStoreEnabled: false, 
                );
                Navigator.pop(context);
              },
              child: const Text("Desactivar", style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/edit-store'); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(user.hasStore ? "Editar Tienda" : "Activar Ahora"),
          ),
        ],
      ),
    );
  }

  // ✅ VERIFICACIÓN CON SUBIDA DE IMAGEN (CORREGIDO)
  void _handleVerificationAction(BuildContext context, AppUser user) {
    if (user.isVerified == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Tu cuenta ya está verificada!")));
      return;
    }

    final nameController = TextEditingController();
    final idController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Resetear la imagen al abrir el modal
    _verificationImage = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) => StatefulBuilder( // ✅ Usar StatefulBuilder para actualizar el modal
        builder: (BuildContext context, StateSetter modalSetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              // ✅ Restringir altura para evitar overflow
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: SingleChildScrollView( 
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(child: Icon(Icons.security, size: 40, color: Colors.black)),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text("Solicitar Verificación", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Para verificar tu identidad, necesitamos tus datos reales y una foto de tu documento.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildTextField("Nombre y Apellidos", Icons.person, nameController),
                      const SizedBox(height: 16),
                      _buildTextField("Carnet de Identidad (CI)", Icons.badge, idController, isNumber: true),
                      const SizedBox(height: 16),
                      _buildTextField("Dirección Particular", Icons.home, addressController),
                      
                      const SizedBox(height: 24),
                      const Text("Foto del Documento", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      
                      // ✅ ÁREA DE SELECCIÓN DE IMAGEN
                      GestureDetector(
                        onTap: () => _pickVerificationImage(modalSetState),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _verificationImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_verificationImage!, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, size: 40, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text("Toca para subir foto del CI", style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // ✅ BOTÓN DE ENVÍO
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              _submitVerification(modalContext, user, nameController.text, idController.text, addressController.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text("Enviar Solicitud", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, size: 20, color: Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Este campo es obligatorio';
        return null;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS AUXILIARES
  // ---------------------------------------------------------------------------
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
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
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

  Widget _buildActionButtons(AppUser user) {
    if (widget.isCurrentUser) {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              text: "Editar perfil",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
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