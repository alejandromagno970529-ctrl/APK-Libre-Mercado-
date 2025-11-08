import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/story_model.dart';
import '../../providers/story_provider.dart';
import '../../providers/auth_provider.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final bool isOwner;

  const StoryViewScreen({
    super.key, 
    required this.stories,
    required this.initialIndex,
    required this.isOwner,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  late PageController _storyPageController;
  late PageController _imagePageController;
  late int _currentStoryIndex;
  late int _currentImageIndex;
  bool _isDeleting = false;
  bool _storyDeleted = false;
  double _dragDelta = 0.0;
  late Timer _timer;
  bool _isTimerActive = false;

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _currentImageIndex = 0;
    _storyPageController = PageController(initialPage: widget.initialIndex);
    _imagePageController = PageController();
    
    // ✅ INICIAR TIMER PARA ACTUALIZAR TIEMPO DINÁMICAMENTE
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _storyPageController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  // ✅ MÉTODO PARA INICIAR TIMER
  void _startTimer() {
    _isTimerActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isTimerActive) {
        setState(() {
          // Solo actualizar el estado para forzar rebuild y actualizar tiempo
        });
        
        // Verificar si la historia actual expiró
        if (_currentStory.isExpired && mounted) {
          _goToNextStoryOrClose();
        }
      } else {
        timer.cancel();
      }
    });
  }

  // ✅ MÉTODO PARA IR A LA SIGUIENTE HISTORIA O CERRAR
  void _goToNextStoryOrClose() {
    if (_canSwipeToNextStory()) {
      _goToNextStory();
    } else {
      Navigator.pop(context);
    }
  }

  Story get _currentStory => widget.stories[_currentStoryIndex];
  // ignore: unused_element
  String get _currentImageUrl => _currentStory.imageUrls[_currentImageIndex];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final storyProvider = Provider.of<StoryProvider>(context);
    final currentUserId = authProvider.currentUser?.id;

    // Si la historia fue eliminada, cerrar inmediatamente
    if (_storyDeleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _onTapDown(details),
        onVerticalDragStart: (_) => _onVerticalDragStart(),
        onVerticalDragUpdate: (details) => _onVerticalDragUpdate(details),
        onVerticalDragEnd: (_) => _onVerticalDragEnd(),
        child: Stack(
          children: [
            // ✅ PAGINADOR PRINCIPAL PARA NAVEGACIÓN ENTRE HISTORIAS
            PageView.builder(
              controller: _storyPageController,
              itemCount: widget.stories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentStoryIndex = index;
                  _currentImageIndex = 0; // Resetear índice de imagen al cambiar de historia
                });
              },
              itemBuilder: (context, storyIndex) {
                final story = widget.stories[storyIndex];
                return _buildStoryContent(story, storyIndex);
              },
            ),

            // Header con información del usuario - ACTUALIZADO CON TIEMPO DINÁMICO
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      _currentStory.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentStory.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // ✅ TIEMPO RESTANTE DINÁMICO
                        Text(
                          _currentStory.timeRemaining,
                          style: TextStyle(
                            color: _currentStory.isAboutToExpire ? Colors.red : Colors.white70,
                            fontSize: 12,
                            fontWeight: _currentStory.isAboutToExpire ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        // ✅ TIEMPO TRANSCURRIDO DESDE LA PUBLICACIÓN
                        Text(
                          _currentStory.timeSincePublished,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ BARRA DE PROGRESO MEJORADA CON PROGRESO DINÁMICO
            if (!_isDeleting)
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  children: List.generate(widget.stories.length, (index) {
                    final story = widget.stories[index];
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(
                          right: index < widget.stories.length - 1 ? 4 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Stack(
                          children: [
                            // Fondo
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Progreso
                            if (index == _currentStoryIndex)
                              AnimatedBuilder(
                                animation: _storyPageController,
                                builder: (context, child) {
                                  double progress = 0.0;
                                  if (_storyPageController.position.haveDimensions) {
                                    progress = (_storyPageController.page! - _currentStoryIndex).abs();
                                    progress = 1.0 - progress.clamp(0.0, 1.0);
                                  }
                                  // ✅ USAR EL PROGRESO DINÁMICO ACTUAL
                                  final dynamicProgress = story.progressPercentage;
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: progress * dynamicProgress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: story.isAboutToExpire ? Colors.red : Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                },
                              )
                            else if (index < _currentStoryIndex)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // ✅ INDICADORES DE IMÁGENES (Puntos para navegación interna)
            if (!_isDeleting && _currentStory.imageUrls.length > 1)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_currentStory.imageUrls.length, (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentImageIndex 
                              ? Colors.white 
                              // ignore: deprecated_member_use
                              : Colors.white.withOpacity(0.5),
                        ),
                      );
                    }),
                  ),
                ),
              ),

            // ✅ BOTONES EN LA ESQUINA SUPERIOR DERECHA
            if (!_isDeleting)
              Positioned(
                top: 40,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón de eliminar - Solo visible para el propietario de la historia actual
                    if (_isOwnerOfCurrentStory(currentUserId))
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () {
                            _showDeleteConfirmation(context, storyProvider);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    
                    // Botón de cerrar
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ✅ INDICADORES DE GESTO (Flechas para navegación entre historias)
            if (!_isDeleting && _currentStoryIndex > 0)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _canSwipeToPreviousStory() ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

            if (!_isDeleting && _currentStoryIndex < widget.stories.length - 1)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _canSwipeToNextStory() ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

            // ✅ OVERLAY DE CARGA durante eliminación
            if (_isDeleting)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Eliminando historia...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ CONSTRUIR CONTENIDO DE CADA HISTORIA CON CARRUSEL INTERNO
  Widget _buildStoryContent(Story story, int storyIndex) {
    return PageView.builder(
      controller: storyIndex == _currentStoryIndex ? _imagePageController : null,
      itemCount: story.imageUrls.length,
      onPageChanged: (imageIndex) {
        if (storyIndex == _currentStoryIndex) {
          setState(() {
            _currentImageIndex = imageIndex;
          });
        }
      },
      itemBuilder: (context, imageIndex) {
        return _buildSingleImage(story.imageUrls[imageIndex]);
      },
    );
  }

  // ✅ CONSTRUIR UNA SOLA IMAGEN CON INTERACTIVIDAD
  Widget _buildSingleImage(String imageUrl) {
    return InteractiveViewer(
      panEnabled: !_isDeleting,
      scaleEnabled: !_isDeleting,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 3.0,
      child: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'Error al cargar la imagen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Cerrando...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTODOS PARA GESTOS Y NAVEGACIÓN
  void _onTapDown(TapDownDetails details) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double tapX = details.globalPosition.dx;
    
    // Navegación entre imágenes de la misma historia
    if (tapX < screenWidth * 0.3) {
      // Tap izquierdo: imagen anterior o historia anterior
      if (_currentImageIndex > 0) {
        _goToPreviousImage();
      } else if (_canSwipeToPreviousStory()) {
        _goToPreviousStory();
      }
    } else if (tapX > screenWidth * 0.7) {
      // Tap derecho: siguiente imagen o siguiente historia
      if (_currentImageIndex < _currentStory.imageUrls.length - 1) {
        _goToNextImage();
      } else if (_canSwipeToNextStory()) {
        _goToNextStory();
      } else {
        // Última imagen de la última historia: cerrar
        Navigator.pop(context);
      }
    }
  }

  void _onVerticalDragStart() {
    _dragDelta = 0.0;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragDelta += details.primaryDelta ?? 0.0;
  }

  void _onVerticalDragEnd() {
    // Swipe hacia abajo para cerrar (más de 50px)
    if (_dragDelta > 50) {
      Navigator.pop(context);
    }
    _dragDelta = 0.0;
  }

  // ✅ MÉTODOS DE NAVEGACIÓN ENTRE IMÁGENES
  bool _canSwipeToPreviousImage() => _currentImageIndex > 0;
  bool _canSwipeToNextImage() => _currentImageIndex < _currentStory.imageUrls.length - 1;

  void _goToPreviousImage() {
    if (_canSwipeToPreviousImage()) {
      _imagePageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextImage() {
    if (_canSwipeToNextImage()) {
      _imagePageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ✅ MÉTODOS DE NAVEGACIÓN ENTRE HISTORIAS
  bool _canSwipeToPreviousStory() => _currentStoryIndex > 0;
  bool _canSwipeToNextStory() => _currentStoryIndex < widget.stories.length - 1;

  void _goToPreviousStory() {
    if (_canSwipeToPreviousStory()) {
      _storyPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextStory() {
    if (_canSwipeToNextStory()) {
      _storyPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isOwnerOfCurrentStory(String? currentUserId) {
    return currentUserId == _currentStory.userId;
  }

  // ✅ DIÁLOGO DE CONFIRMACIÓN PARA ELIMINAR
  void _showDeleteConfirmation(BuildContext context, StoryProvider storyProvider) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Eliminar Historia',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta historia? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteStory(context, storyProvider);
            },
            child: const Text(
              'Eliminar', 
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO PARA ELIMINAR HISTORIA
  Future<void> _deleteStory(BuildContext context, StoryProvider storyProvider) async {
    if (_isDeleting) return;
    
    setState(() {
      _isDeleting = true;
    });

    try {
      final success = await storyProvider.deleteStory(_currentStory.id);
      
      if (success) {
        setState(() {
          _storyDeleted = true;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Historia eliminada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
      } else {
        setState(() {
          _isDeleting = false;
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${storyProvider.error ?? "No se pudo eliminar la historia"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}