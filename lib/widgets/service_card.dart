import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../utils/time_utils.dart';
import '../constants/service_categories.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  // ignore: use_super_parameters
  const ServiceCard({
    Key? key,
    required this.service,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final category = ServiceCategories.getCategoryById(service.category);
    final categoryColor = category != null 
        ? Color(category['color'] as int) 
        : Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del servicio
              _buildServiceImage(categoryColor, category),
              const SizedBox(width: 12),
              
              // Información del servicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Precio
                    Text(
                      '\$${service.price.toStringAsFixed(0)} ${service.priceUnit}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Descripción breve
                    Text(
                      service.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Footer: Categoría y ubicación
                    Row(
                      children: [
                        // Categoría
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (category != null && category['icon'] is IconData) 
                                Icon(
                                  category['icon'] as IconData,
                                  size: 12,
                                  color: categoryColor,
                                ),
                              const SizedBox(width: 4),
                              Text(
                                service.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: categoryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Ubicación
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              service.location,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Rating y fecha
                    Row(
                      children: [
                        if (service.rating != null) ...[
                          // ignore: prefer_const_constructors
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            service.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (service.totalReviews != null && service.totalReviews! > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${service.totalReviews})',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                          const SizedBox(width: 12),
                        ],
                        
                        Text(
                          TimeUtils.formatTimeAgo(service.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
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
      ),
    );
  }

  Widget _buildServiceImage(Color categoryColor, Map<String, dynamic>? category) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // ignore: deprecated_member_use
        color: categoryColor.withOpacity(0.1),
        border: Border.all(
          // ignore: deprecated_member_use
          color: categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: service.images != null && service.images!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                service.images!.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackIcon(categoryColor, category);
                },
              ),
            )
          : _buildFallbackIcon(categoryColor, category),
    );
  }

  Widget _buildFallbackIcon(Color categoryColor, Map<String, dynamic>? category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            category != null && category['icon'] is IconData
                ? category['icon'] as IconData
                : Icons.work_outline,
            size: 32,
            color: categoryColor,
          ),
          const SizedBox(height: 4),
          Text(
            'Servicio',
            style: TextStyle(
              fontSize: 10,
              color: categoryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}