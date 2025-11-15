import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ AGREGAR ESTA IMPORTACIÓN
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/image_upload_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';

class EditStoreScreen extends StatefulWidget {
  const EditStoreScreen({super.key});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final _storeCategoryController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  final _storeEmailController = TextEditingController();
  final _storeWebsiteController = TextEditingController();
  final _storePolicyController = TextEditingController();

  File? _selectedLogoImage;
  File? _selectedBannerImage;
  bool _isLoading = false;
  String? _error;
  String? _storeLogoUrl;
  String? _storeBannerUrl;
  bool _isStoreEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentStore();
  }

  void _loadCurrentStore() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    
    if (currentUser != null) {
      _storeNameController.text = currentUser.storeName ?? '';
      _storeDescriptionController.text = currentUser.storeDescription ?? '';
      _storeCategoryController.text = currentUser.storeCategory ?? '';
      _storeAddressController.text = currentUser.storeAddress ?? '';
      _storePhoneController.text = currentUser.storePhone ?? '';
      _storeEmailController.text = currentUser.storeEmail ?? '';
      _storeWebsiteController.text = currentUser.storeWebsite ?? '';
      _storePolicyController.text = currentUser.storePolicy ?? '';
      _storeLogoUrl = currentUser.storeLogoUrl;
      _storeBannerUrl = currentUser.storeBannerUrl;
      _isStoreEnabled = currentUser.isStoreEnabled;
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          if (isLogo) {
            _selectedLogoImage = File(image.path);
          } else {
            _selectedBannerImage = File(image.path);
          }
        });
      }
    } catch (e) {
      _showError('Error seleccionando imagen: $e');
    }
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      String? newStoreLogoUrl = _storeLogoUrl;
      String? newStoreBannerUrl = _storeBannerUrl;

      // Subir logo si hay uno nuevo
      if (_selectedLogoImage != null) {
        final imageUploadService = ImageUploadService(Supabase.instance.client);
        newStoreLogoUrl = await imageUploadService.uploadStoreLogoImage(
          _selectedLogoImage!, 
          currentUser.id
        );
        if (newStoreLogoUrl == null) {
          throw Exception('Error subiendo logo de la tienda');
        }
      }

      // Subir banner si hay uno nuevo
      if (_selectedBannerImage != null) {
        final imageUploadService = ImageUploadService(Supabase.instance.client);
        newStoreBannerUrl = await imageUploadService.uploadStoreBannerImage(
          _selectedBannerImage!, 
          currentUser.id
        );
        if (newStoreBannerUrl == null) {
          throw Exception('Error subiendo banner de la tienda');
        }
      }

      final error = await authProvider.updateStoreProfile(
        storeName: _storeNameController.text.trim(),
        storeDescription: _storeDescriptionController.text.trim().isNotEmpty ? _storeDescriptionController.text.trim() : null,
        storeCategory: _storeCategoryController.text.trim().isNotEmpty ? _storeCategoryController.text.trim() : null,
        storeAddress: _storeAddressController.text.trim().isNotEmpty ? _storeAddressController.text.trim() : null,
        storePhone: _storePhoneController.text.trim().isNotEmpty ? _storePhoneController.text.trim() : null,
        storeEmail: _storeEmailController.text.trim().isNotEmpty ? _storeEmailController.text.trim() : null,
        storeWebsite: _storeWebsiteController.text.trim().isNotEmpty ? _storeWebsiteController.text.trim() : null,
        storePolicy: _storePolicyController.text.trim().isNotEmpty ? _storePolicyController.text.trim() : null,
        storeLogoUrl: newStoreLogoUrl,
        storeBannerUrl: newStoreBannerUrl,
        isStoreEnabled: _isStoreEnabled,
      );

      if (error != null) {
        throw Exception(error);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tienda actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showError('Error actualizando tienda: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _removeImage(bool isLogo) {
    setState(() {
      if (isLogo) {
        _selectedLogoImage = null;
        _storeLogoUrl = null;
      } else {
        _selectedBannerImage = null;
        _storeBannerUrl = null;
      }
    });
  }

  ImageProvider? _getLogoImage() {
    if (_selectedLogoImage != null) {
      return FileImage(_selectedLogoImage!);
    } else if (_storeLogoUrl != null && _storeLogoUrl!.isNotEmpty) {
      return NetworkImage(_storeLogoUrl!);
    }
    return null;
  }

  ImageProvider? _getBannerImage() {
    if (_selectedBannerImage != null) {
      return FileImage(_selectedBannerImage!);
    } else if (_storeBannerUrl != null && _storeBannerUrl!.isNotEmpty) {
      return NetworkImage(_storeBannerUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Tienda'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: AppDimens.paddingAllM,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppDimens.paddingAllL,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildStoreToggle(),
              const SizedBox(height: 24),
              if (_isStoreEnabled) ...[
                _buildBannerSection(),
                const SizedBox(height: 24),
                _buildLogoSection(),
                const SizedBox(height: 24),
                _buildStoreForm(),
              ] else ...[
                _buildStoreDisabledMessage(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreToggle() {
    return Card(
      child: Padding(
        padding: AppDimens.paddingAllM,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activar Tienda Profesional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Habilita tu tienda para mostrar tus productos de manera profesional',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isStoreEnabled,
              onChanged: (value) {
                setState(() {
                  _isStoreEnabled = value;
                });
              },
              // ignore: deprecated_member_use
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreDisabledMessage() {
    return const Card(
      child: Padding(
        padding: AppDimens.paddingAllL,
        child: Column(
          children: [
            Icon(Icons.store_mall_directory, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tienda Desactivada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Activa la tienda profesional para configurar y mostrar tu catálogo de productos de manera profesional.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Text(
          'Logo de la Tienda',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[100],
              backgroundImage: _getLogoImage(),
              child: _selectedLogoImage == null && (_storeLogoUrl == null || _storeLogoUrl!.isEmpty)
                  ? Icon(
                      Icons.store,
                      size: 50,
                      color: Colors.grey[600],
                    )
                  : null,
            ),
            if (_selectedLogoImage != null || (_storeLogoUrl != null && _storeLogoUrl!.isNotEmpty))
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _removeImage(true),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _pickImage(true),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Cambiar Logo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSection() {
    return Column(
      children: [
        Text(
          'Banner de la Tienda',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppDimens.borderRadiusM),
                image: _getBannerImage() != null
                    ? DecorationImage(
                        image: _getBannerImage()!,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _selectedBannerImage == null && (_storeBannerUrl == null || _storeBannerUrl!.isEmpty)
                  ? Icon(
                      Icons.photo_library,
                      size: 50,
                      color: Colors.grey[600],
                    )
                  : null,
            ),
            if (_selectedBannerImage != null || (_storeBannerUrl != null && _storeBannerUrl!.isNotEmpty))
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeImage(false),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _pickImage(false),
          icon: const Icon(Icons.photo_library),
          label: const Text('Cambiar Banner'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStoreForm() {
    return Column(
      children: [
        TextFormField(
          controller: _storeNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la Tienda *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store),
            hintText: 'Ej: Mi Tienda Online',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El nombre de la tienda es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _storeDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Descripción de la Tienda',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Describe los productos y servicios de tu tienda...',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _storeCategoryController,
          decoration: const InputDecoration(
            labelText: 'Categoría Principal',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
            hintText: 'Ej: Ropa, Electrónica, Hogar...',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _storeAddressController,
          decoration: const InputDecoration(
            labelText: 'Dirección de la Tienda',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
            hintText: 'Dirección física o zona de entrega',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _storePhoneController,
          decoration: const InputDecoration(
            labelText: 'Teléfono de Contacto',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
            hintText: '+53 12345678',
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _storeEmailController,
          decoration: const InputDecoration(
            labelText: 'Email de Contacto',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
            hintText: 'contacto@mitienda.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _storeWebsiteController,
          decoration: const InputDecoration(
            labelText: 'Sitio Web',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.language),
            hintText: 'https://mitienda.com',
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _storePolicyController,
          decoration: const InputDecoration(
            labelText: 'Políticas de la Tienda',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.policy),
            hintText: 'Políticas de envío, devoluciones, garantías...',
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 32),
        if (_error != null)
          Container(
            width: double.infinity,
            padding: AppDimens.paddingAllM,
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(AppDimens.borderRadiusM),
              border: Border.all(color: Colors.red),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (_error != null) const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: AppDimens.buttonHeight,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveStore,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.borderRadiusM),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Text(
                    'GUARDAR CONFIGURACIÓN DE TIENDA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _storeCategoryController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _storeEmailController.dispose();
    _storeWebsiteController.dispose();
    _storePolicyController.dispose();
    super.dispose();
  }
}