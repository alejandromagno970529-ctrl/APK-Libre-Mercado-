// 4. CREAR perfil especializado para proveedores de servicios (profile_screen_services.dart)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/service_provider.dart';
import '../models/user_model.dart';
import '../models/service_model.dart';
import 'edit_profile_screen.dart';
import '../screens/services/service_detail_screen.dart';
import '../screens/services/add_edit_service_screen.dart';

class ProfileScreenServices extends StatefulWidget {
  final String? userId;
  final bool isCurrentUser;

  const ProfileScreenServices({
    Key? key,
    this.userId,
    this.isCurrentUser = true,
  }) : super(key: key);

  @override
  _ProfileScreenServicesState createState() => _ProfileScreenServicesState();
}

class _ProfileScreenServicesState extends State<ProfileScreenServices> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppUser? _targetUser;
  bool _isLoading = false;
  List<ServiceModel> _userServices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    final authProvider = context.read<AuthProvider>();
    final serviceProvider = context.read<ServiceProvider>();

    String targetId = widget.userId ?? authProvider.currentUser?.id ?? '';

    if (widget.isCurrentUser) {
      _targetUser = authProvider.currentUser;
      if (_targetUser != null) {
        await serviceProvider.fetchMyServices(_targetUser!.id);
        _userServices = serviceProvider.myServices;
      }
    } else {
      _targetUser = await authProvider.getUserProfile(targetId);
      // Aquí necesitaríamos un método para obtener servicios de otro usuario
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userToShow = widget.isCurrentUser ? authProvider.currentUser : _targetUser;

    if (_isLoading || userToShow == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(userToShow),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildProfileHeader(userToShow),
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
                    Tab(text: 'Servicios'),
                    Tab(text: 'Portafolio'),
                    Tab(text: 'Reseñas'),
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
            _buildServicesGrid(userToShow),
            _buildPortfolioSection(userToShow),
            _buildReviewsSection(userToShow),
          ],
        ),
      ),
      floatingActionButton: widget.isCurrentUser
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/add-edit-service'),
              backgroundColor: Colors.black,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  AppBar _buildAppBar(AppUser user) {
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
        user.username,
        style: const TextStyle(
          color: Colors.black, 
          fontWeight: FontWeight.bold,
          fontSize: 18
        ),
      ),
      actions: widget.isCurrentUser ? [
        IconButton(
          icon: const Icon(Icons.add_box_outlined, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, '/add-edit-service'),
          tooltip: 'Crear servicio',
        ),
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.black),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditProfileScreen(),
            ),
          ),
        ),
      ] : [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProfileHeader(AppUser user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(user.avatarUrl),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        if (user.isVerified == true) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.verified_rounded, color: Colors.blue, size: 20),
                        ]
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (user.bio != null && user.bio!.isNotEmpty)
                      Text(
                        user.bio!,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionButtons(user),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        backgroundImage: avatarUrl != null 
            ? CachedNetworkImageProvider(avatarUrl) 
            : null,
        child: avatarUrl == null 
            ? const Icon(Icons.person, size: 40, color: Colors.grey)
            : null,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(_userServices.length.toString(), 'Servicios'),
        _buildStatItem(
          _targetUser?.successfulTransactions?.toString() ?? '0',
          'Contrataciones',
        ),
        _buildStatItem(
          _targetUser?.rating?.toStringAsFixed(1) ?? '0.0',
          'Rating',
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppUser user) {
    if (widget.isCurrentUser) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/add-edit-service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Nuevo Servicio'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Editar Perfil'),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {}, // Contactar
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Contactar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {}, // Seguir
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Seguir'),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildServicesGrid(AppUser user) {
    if (_userServices.isEmpty) {
      return _buildEmptyState(
        icon: Icons.work_outline_rounded,
        title: widget.isCurrentUser 
            ? 'Aún no tienes servicios'
            : 'No hay servicios disponibles',
        subtitle: widget.isCurrentUser
            ? 'Comienza creando tu primer servicio'
            : 'Este proveedor aún no tiene servicios publicados',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _userServices.length,
      itemBuilder: (context, index) {
        final service = _userServices[index];
        return _ServiceGridItem(
          service: service,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(serviceId: service.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioSection(AppUser user) {
    // Combinar todas las imágenes de portafolio de los servicios
    final portfolioImages = _userServices
        .where((service) => service.portfolioImages != null)
        .expand((service) => service.portfolioImages!)
        .toList();

    if (portfolioImages.isEmpty) {
      return _buildEmptyState(
        icon: Icons.collections_rounded,
        title: 'Sin portafolio',
        subtitle: widget.isCurrentUser
            ? 'Agrega imágenes de tus trabajos anteriores en tus servicios'
            : 'Este proveedor aún no tiene portafolio',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: portfolioImages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showPortfolioImage(portfolioImages[index]),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Image.network(
              portfolioImages[index],
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsSection(AppUser user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Reseñas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPortfolioImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _ServiceGridItem extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceGridItem({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: Colors.grey.shade100,
              ),
              child: service.images != null && service.images!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        service.images!.first,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.work_outline_rounded,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
            
            // Contenido
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${service.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    service.priceUnit.toLowerCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          service.location,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}