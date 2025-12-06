import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Servicios',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono circular minimalista
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.work_outline,
                size: 48,
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 32),
            
            // Texto principal
            const Text(
              'Servicios Profesionales',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2C2C),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            
            // Descripción
            const Text(
              'Ofrece o encuentra servicios profesionales\nen tu área local',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B6B6B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Separador visual
            Container(
              height: 1,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(horizontal: 40),
            ),
            const SizedBox(height: 32),
            
            // Lista de categorías de servicios (placeholder)
            Column(
              children: [
                _buildServiceCategory('🏨 Hoteles & Hospedaje', Colors.blue.shade50),
                const SizedBox(height: 12),
                _buildServiceCategory('🎨 Decoración & Diseño', Colors.purple.shade50),
                const SizedBox(height: 12),
                _buildServiceCategory('🍽️ Restaurantes & Bares', Colors.orange.shade50),
                const SizedBox(height: 12),
                _buildServiceCategory('🔧 Reparaciones & Mantenimiento', Colors.green.shade50),
              ],
            ),
            const SizedBox(height: 40),
            
            // Mensaje de "Próximamente" sutil
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade100),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: Color(0xFFE65100)),
                  SizedBox(width: 8),
                  Text(
                    'Disponible próximamente',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE65100),
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

  Widget _buildServiceCategory(String title, Color backgroundColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}