// 2. MODIFICAR add_edit_service_screen.dart para campos específicos por categoría - CORREGIDO
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
// ignore: unused_import
import 'dart:io';
// ignore: unused_import
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/service_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/service_model.dart';
// ignore: unused_import
import '../../services/image_upload_service.dart';
import '../../constants/service_categories.dart';

class AddEditServiceScreen extends StatefulWidget {
  static const String routeName = '/add-edit-service';
  final ServiceModel? service;

  // ignore: use_super_parameters
  const AddEditServiceScreen({Key? key, this.service}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AddEditServiceScreenState createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceUnitController = TextEditingController(text: 'por servicio');
  final _capacityController = TextEditingController();
  final _experienceController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _tagController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedServiceType;
  List<String> _selectedTags = [];
  List<String> _imageUrls = [];
  List<String> _portfolioImageUrls = [];
  List<String> _selectedAmenities = [];
  // ignore: prefer_final_fields
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isCertified = false;

  final List<String> _serviceTypes = ['fijo', 'móvil', 'virtual'];
  final List<String> _priceUnits = ['por servicio', 'por hora', 'por día', 'por mes'];
  final int maxImages = 10;
  final int maxPortfolioImages = 20;

  // Subcategorías por categoría principal
  final Map<String, List<String>> _subCategories = {
    'Alojamiento': ['Hotel', 'Apartamento', 'Casa completa', 'Habitación privada', 'Hostal'],
    'Restauración': ['Restaurante', 'Cafetería', 'Bar', 'Food Truck', 'Catering'],
    'Transporte': ['Taxi', 'Alquiler de auto', 'Transporte ejecutivo', 'Flete', 'Mudanza'],
    'Decoración': ['Eventos sociales', 'Bodas', 'Corporativo', 'Interiores', 'Exteriores'],
    'Construcción': ['Remodelación', 'Nueva construcción', 'Reparaciones', 'Diseño arquitectónico'],
    'Educación': ['Clases particulares', 'Tutorías', 'Cursos online', 'Talleres', 'Asesorías'],
    'Salud': ['Consulta médica', 'Terapia', 'Masajes', 'Nutrición', 'Entrenamiento'],
    'Tecnología': ['Desarrollo web', 'Soporte técnico', 'Diseño gráfico', 'Marketing digital'],
    'Belleza': ['Peluquería', 'Maquillaje', 'Uñas', 'Spa', 'Barbería'],
    'Otros': ['Otros servicios'],
  };

  // Comodidades por categoría
  final Map<String, List<String>> _amenitiesOptions = {
    'Alojamiento': ['WiFi', 'Piscina', 'Estacionamiento', 'Desayuno incluido', 'Gimnasio', 'Spa', 'Restaurante', 'Bar', 'Room Service'],
    'Restauración': ['WiFi', 'Estacionamiento', 'Terraza', 'Aire acondicionado', 'Música en vivo', 'Menú vegetariano', 'Delivery'],
    'Transporte': ['WiFi', 'Aire acondicionado', 'TV', 'Agua', 'Guía turístico', 'Seguro incluido'],
    'Decoración': ['Diseño personalizado', 'Montaje incluido', 'Asesoría gratuita', 'Presupuesto detallado'],
    'Construcción': ['Licencia', 'Garantía', 'Materiales incluidos', 'Diseño 3D'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _loadServiceData(widget.service!);
    }
  }

  void _loadServiceData(ServiceModel service) {
    _titleController.text = service.title;
    _descriptionController.text = service.description;
    _priceController.text = service.price.toStringAsFixed(0);
    _locationController.text = service.location;
    _priceUnitController.text = service.priceUnit;
    _selectedCategory = service.category;
    _selectedSubCategory = service.subCategory;
    _selectedServiceType = service.serviceType;
    _selectedTags = List.from(service.tags);
    _imageUrls = List.from(service.images ?? []);
    _portfolioImageUrls = List.from(service.portfolioImages ?? []);
    _selectedAmenities = List.from(service.amenities ?? []);
    _capacityController.text = service.capacity?.toString() ?? '';
    _experienceController.text = service.experienceYears ?? '';
    _scheduleController.text = service.availabilitySchedule ?? '';
    _isCertified = service.isCertified ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.service == null ? 'Nuevo Servicio' : 'Editar Servicio',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded, color: Colors.black),
              onPressed: () => _saveService(user!.id),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagesSection(),
              const SizedBox(height: 32),
              _buildSectionTitle('Información básica'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _titleController,
                label: 'Título del servicio',
                hint: 'Ej: Hotel ejecutivo, Decoración de bodas, Transporte ejecutivo',
                icon: Icons.title_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El título es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              if (_selectedCategory != null && _subCategories.containsKey(_selectedCategory!))
                _buildSubCategoryDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Descripción detallada',
                hint: 'Describe tu servicio en detalle, incluye experiencia, metodología, etc...',
                icon: Icons.description_outlined,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La descripción es requerida';
                  }
                  if (value.length < 50) {
                    return 'La descripción debe tener al menos 50 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Especificaciones del servicio'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: 'Precio',
                hint: '0',
                icon: Icons.attach_money_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El precio es requerido';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPriceUnitDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Ubicación',
                hint: 'Ciudad, zona o dirección específica',
                icon: Icons.location_on_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La ubicación es requerida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildServiceTypeDropdown(),
              
              // Campos específicos por categoría
              if (_selectedCategory != null) ...[
                const SizedBox(height: 32),
                _buildCategorySpecificFields(),
              ],
              
              const SizedBox(height: 32),
              _buildTagsSection(),
              const SizedBox(height: 40),
              _buildSaveButton(user!.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: Colors.black54, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _selectedCategory,
        decoration: const InputDecoration(
          labelText: 'Categoría *',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.category_outlined, color: Colors.black54, size: 22),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        items: ServiceCategories.allCategoryNames.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value;
            _selectedSubCategory = null;
            _selectedAmenities = [];
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Seleccione una categoría';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubCategoryDropdown() {
    final subCats = _subCategories[_selectedCategory] ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _selectedSubCategory,
        decoration: const InputDecoration(
          labelText: 'Especialidad / Tipo',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.category_outlined, color: Colors.black54, size: 22),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        items: subCats.map((subCat) {
          return DropdownMenuItem(
            value: subCat,
            child: Text(subCat),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedSubCategory = value),
      ),
    );
  }

  Widget _buildPriceUnitDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _priceUnitController.text,
        decoration: const InputDecoration(
          labelText: 'Unidad de precio *',
          border: InputBorder.none,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        items: _priceUnits.map((unit) {
          return DropdownMenuItem(
            value: unit,
            child: Text(unit),
          );
        }).toList(),
        onChanged: (value) => _priceUnitController.text = value!,
      ),
    );
  }

  Widget _buildServiceTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _selectedServiceType,
        decoration: const InputDecoration(
          labelText: 'Modalidad del servicio *',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.settings_outlined, color: Colors.black54, size: 22),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        items: _serviceTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(_capitalize(type)),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedServiceType = value),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Seleccione una modalidad';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildImagesSection() {
    final isTransport = _selectedCategory == 'Transporte';
    final title = isTransport ? 'Foto principal del vehículo' : 'Fotos del servicio';
    final subtitle = isTransport 
        ? 'Sube una foto clara del vehículo'
        : 'Agrega hasta $maxImages fotos de tu servicio';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_imageUrls.length}/$maxImages',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        if (_imageUrls.isEmpty)
          _buildEmptyImagesState()
        else
          _buildImagesGrid(),
      ],
    );
  }

  Widget _buildCategorySpecificFields() {
    switch (_selectedCategory) {
      case 'Alojamiento':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Detalles del alojamiento'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _capacityController,
              label: 'Capacidad (huéspedes)',
              hint: 'Ej: 2, 4, 10',
              icon: Icons.people_alt_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _scheduleController,
              label: 'Horarios de check-in/out',
              hint: 'Ej: Check-in: 14:00, Check-out: 12:00',
              icon: Icons.access_time_rounded,
            ),
            const SizedBox(height: 16),
            _buildAmenitiesSection(),
          ],
        );
      
      case 'Restauración':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Detalles del restaurante'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _capacityController,
              label: 'Capacidad de comensales',
              hint: 'Ej: 50, 100, 200',
              icon: Icons.people_alt_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _scheduleController,
              label: 'Horario de atención',
              hint: 'Ej: Lunes a Viernes 12:00-23:00',
              icon: Icons.access_time_rounded,
            ),
            const SizedBox(height: 16),
            _buildAmenitiesSection(),
          ],
        );
      
      case 'Decoración':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Portafolio profesional'),
            const SizedBox(height: 8),
            Text(
              'Muestra tus trabajos anteriores (hasta $maxPortfolioImages imágenes)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _buildPortfolioSection(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _experienceController,
              label: 'Años de experiencia',
              hint: 'Ej: 5 años',
              icon: Icons.work_history_rounded,
            ),
            const SizedBox(height: 16),
            _buildCertifiedCheckbox(),
          ],
        );
      
      case 'Transporte':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Detalles del vehículo'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _capacityController,
              label: 'Capacidad de pasajeros',
              hint: 'Ej: 4, 7, 15',
              icon: Icons.people_alt_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildAmenitiesSection(),
          ],
        );
      
      case 'Construcción':
      case 'Educación':
      case 'Salud':
      case 'Tecnología':
      case 'Belleza':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Información profesional'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _experienceController,
              label: 'Años de experiencia',
              hint: 'Ej: 3 años',
              icon: Icons.work_history_rounded,
            ),
            const SizedBox(height: 16),
            _buildCertifiedCheckbox(),
            const SizedBox(height: 16),
            _buildPortfolioSection(),
          ],
        );
      
      default:
        return const SizedBox();
    }
  }

  Widget _buildAmenitiesSection() {
    final amenities = _amenitiesOptions[_selectedCategory] ?? [];
    
    if (amenities.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Servicios incluidos'),
        const SizedBox(height: 8),
        Text(
          'Selecciona los servicios que incluye',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return ChoiceChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Portafolio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_portfolioImageUrls.length}/$maxPortfolioImages',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_portfolioImageUrls.isEmpty)
          _buildEmptyPortfolioState()
        else
          _buildPortfolioGrid(),
      ],
    );
  }

  Widget _buildEmptyPortfolioState() {
    return GestureDetector(
      onTap: _pickPortfolioImage,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_rounded,
              size: 32,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Text(
              'Agregar fotos de trabajos anteriores',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _portfolioImageUrls.length + (_portfolioImageUrls.length < maxPortfolioImages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _portfolioImageUrls.length) {
          return _buildAddPortfolioButton();
        }
        return _buildPortfolioImageItem(index);
      },
    );
  }

  Widget _buildAddPortfolioButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickPortfolioImage,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isUploading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 24, color: Colors.grey),
                  SizedBox(height: 4),
                  Text(
                    'Agregar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPortfolioImageItem(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              _portfolioImageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePortfolioImage(index),
            child: Container(
              width: 24,
              height: 24,
              // ignore: prefer_const_constructors
              decoration: BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertifiedCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _isCertified,
          onChanged: (value) => setState(() => _isCertified = value ?? false),
          activeColor: Colors.black,
        ),
        const SizedBox(width: 8),
        Text(
          'Certificado/Licenciado',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.verified_rounded,
          size: 16,
          color: Colors.blue.shade600,
        ),
      ],
    );
  }

  Widget _buildEmptyImagesState() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Agregar imágenes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _imageUrls.length + (_imageUrls.length < maxImages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _imageUrls.length) {
          return _buildAddImageButton();
        }
        return _buildImageItem(index);
      },
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isUploading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 24, color: Colors.grey),
                  SizedBox(height: 4),
                  Text(
                    'Agregar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              _imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Etiquetas (separadas por comas)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tagController,
          decoration: InputDecoration(
            hintText: 'Ej: profesional, rápido, confiable, experiencia, garantizado',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {
              _selectedTags = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            });
          },
        ),
        const SizedBox(height: 8),
        if (_selectedTags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.grey.shade100,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedTags.remove(tag);
                    _tagController.text = _selectedTags.join(', ');
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSaveButton(String userId) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _saveService(userId),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'GUARDAR SERVICIO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_imageUrls.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo $maxImages imágenes permitidas'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (image != null) {
      await _uploadImage(image, isPortfolio: false);
    }
  }

  Future<void> _pickPortfolioImage() async {
    if (_portfolioImageUrls.length >= maxPortfolioImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo $maxPortfolioImages imágenes en portafolio'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (image != null) {
      await _uploadImage(image, isPortfolio: true);
    }
  }

  Future<void> _uploadImage(XFile image, {bool isPortfolio = false}) async {
    setState(() => _isUploading = true);
    
    try {
      // Simular subida de imagen (en producción, usar ImageUploadService)
      await Future.delayed(const Duration(seconds: 1));
      
      final fakeImageUrl = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/400/300';
      
      setState(() {
        if (isPortfolio) {
          _portfolioImageUrls.add(fakeImageUrl);
        } else {
          _imageUrls.add(fakeImageUrl);
        }
      });
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen agregada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  void _removePortfolioImage(int index) {
    setState(() => _portfolioImageUrls.removeAt(index));
  }

  Future<void> _saveService(String userId) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        // ignore: prefer_const_constructors
        SnackBar(
          content: const Text('Por favor complete todos los campos requeridos'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final service = ServiceModel(
        id: widget.service?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory ?? 'Otros',
        price: _priceController.text.isEmpty ? 0.0 : double.parse(_priceController.text),
        priceUnit: _priceUnitController.text,
        images: _imageUrls.isNotEmpty ? _imageUrls : null,
        location: _locationController.text.trim(),
        serviceType: _selectedServiceType ?? 'fijo',
        tags: _selectedTags,
        createdAt: widget.service?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        subCategory: _selectedSubCategory,
        amenities: _selectedAmenities.isNotEmpty ? _selectedAmenities : null,
        capacity: _capacityController.text.isNotEmpty ? int.parse(_capacityController.text) : null,
        portfolioImages: _portfolioImageUrls.isNotEmpty ? _portfolioImageUrls : null,
        experienceYears: _experienceController.text.trim().isNotEmpty ? _experienceController.text.trim() : null,
        isCertified: _isCertified,
        availabilitySchedule: _scheduleController.text.trim().isNotEmpty ? _scheduleController.text.trim() : null,
      );

      final provider = Provider.of<ServiceProvider>(context, listen: false);
      
      if (widget.service == null) {
        await provider.addService(service);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Servicio publicado exitosamente'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        await provider.updateService(service);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Servicio actualizado exitosamente'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
      
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}