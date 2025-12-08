// 5. AGREGAR pantalla de onboarding para proveedores de servicios
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'profile_screen_services.dart';

class ServiceProviderOnboardingScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const ServiceProviderOnboardingScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ServiceProviderOnboardingScreenState createState() => _ServiceProviderOnboardingScreenState();
}

class _ServiceProviderOnboardingScreenState extends State<ServiceProviderOnboardingScreen> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Registra tu perfil',
    'Crea tus primeros servicios',
    'Gestiona tus contrataciones',
    'Recibe pagos seguros',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    // ignore: unused_local_variable
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Comienza como Proveedor',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progreso
            _buildProgressIndicator(),
            const SizedBox(height: 40),
            
            // Contenido del paso actual
            Expanded(
              child: _buildStepContent(_currentStep),
            ),
            
            // Botones de navegación
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso ${_currentStep + 1} de ${_steps.length}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _steps[_currentStep],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 4,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _steps.length,
            itemBuilder: (context, index) {
              return Container(
                width: (MediaQuery.of(context).size.width - 48) / _steps.length,
                margin: EdgeInsets.only(
                  right: index < _steps.length - 1 ? 4 : 0,
                ),
                decoration: BoxDecoration(
                  color: index <= _currentStep ? Colors.black : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Crea un perfil profesional',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Completa tu perfil con información profesional, experiencia y especialidades. Los clientes confían en proveedores con perfiles completos.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _buildFeatureItem(
          icon: Icons.verified_rounded,
          title: 'Verificación de identidad',
          subtitle: 'Aumenta tu credibilidad',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.photo_library_rounded,
          title: 'Portafolio de trabajos',
          subtitle: 'Muestra tu experiencia',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.star_rounded,
          title: 'Sistema de reseñas',
          subtitle: 'Construye tu reputación',
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.work_outline_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Publica tus servicios',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Crea servicios detallados con fotos, precios, disponibilidad y especificaciones. Entre más detallado, más clientes te encontrarán.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _buildFeatureItem(
          icon: Icons.category_rounded,
          title: 'Categorías específicas',
          subtitle: 'Alojamiento, Restauración, Transporte, etc.',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.attach_money_rounded,
          title: 'Precios flexibles',
          subtitle: 'Por hora, día, servicio o proyecto',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.schedule_rounded,
          title: 'Gestión de disponibilidad',
          subtitle: 'Controla tus horarios y fechas',
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.handshake_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Gestiona contrataciones',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Recibe solicitudes, coordina detalles y gestiona tus servicios a través de nuestra plataforma. Todo en un solo lugar.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _buildFeatureItem(
          icon: Icons.chat_rounded,
          title: 'Chat integrado',
          subtitle: 'Comunícate directamente con clientes',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.calendar_today_rounded,
          title: 'Calendario de citas',
          subtitle: 'Organiza tu agenda automáticamente',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.notifications_rounded,
          title: 'Notificaciones instantáneas',
          subtitle: 'Nunca pierdas una oportunidad',
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.payment_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Recibe pagos seguros',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Pagos seguros a través de nuestra plataforma. Recibe tu dinero de forma rápida y segura, con protección para ambas partes.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _buildFeatureItem(
          icon: Icons.security_rounded,
          title: 'Pagos seguros',
          subtitle: 'Protección para clientes y proveedores',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.speed_rounded,
          title: 'Depósitos rápidos',
          subtitle: 'Disponible en 1-2 días hábiles',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.receipt_long_rounded,
          title: 'Facturación automática',
          subtitle: 'Recibos y comprobantes digitales',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.black),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() => _currentStep--);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Anterior'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (_currentStep < _steps.length - 1) {
                setState(() => _currentStep++);
              } else {
                _completeOnboarding();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _currentStep < _steps.length - 1 ? 'Siguiente' : 'Comenzar',
            ),
          ),
        ),
      ],
    );
  }

  void _completeOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceProviderProfileScreen(isCurrentUser: true),
      ),
    );
  }
}