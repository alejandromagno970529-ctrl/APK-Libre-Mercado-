import 'dart:typed_data';
import 'package:flutter/material.dart';

enum StoryElementType {
  text,
  sticker,
  cta,
  discountTag,
  shape,
}

class StoryElement {
  final String id;
  final StoryElementType type;
  final Offset position;
  final String content;
  final TextStyle? style;
  final Map<String, dynamic> properties;
  final double rotation;
  final double scale;

  const StoryElement({
    required this.id,
    required this.type,
    required this.position,
    required this.content,
    this.style,
    this.properties = const {},
    this.rotation = 0.0,
    this.scale = 1.0,
  });

  // Método copyWith para actualizar propiedades
  StoryElement copyWith({
    String? id,
    StoryElementType? type,
    Offset? position,
    String? content,
    TextStyle? style,
    Map<String, dynamic>? properties,
    double? rotation,
    double? scale,
  }) {
    return StoryElement(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      content: content ?? this.content,
      style: style ?? this.style,
      properties: properties ?? this.properties,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }

  // Convertir a mapa para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'position_x': position.dx,
      'position_y': position.dy,
      'content': content,
      'style': style != null ? _styleToMap(style!) : null,
      'properties': properties,
      'rotation': rotation,
      'scale': scale,
    };
  }

  // Convertir estilo a mapa
  Map<String, dynamic> _styleToMap(TextStyle style) {
    return {
      // ignore: deprecated_member_use
      'color': style.color != null ? style.color!.value : null,
      'fontSize': style.fontSize,
      'fontWeight': style.fontWeight?.index,
      'fontStyle': style.fontStyle?.index,
      'decoration': _textDecorationToString(style.decoration),
    };
  }

  // Convertir TextDecoration a string
  String _textDecorationToString(TextDecoration? decoration) {
    if (decoration == null) return 'none';
    if (decoration == TextDecoration.underline) return 'underline';
    if (decoration == TextDecoration.overline) return 'overline';
    if (decoration == TextDecoration.lineThrough) return 'lineThrough';
    return 'none';
  }

  // Factory method para crear desde JSON
  factory StoryElement.fromJson(Map<String, dynamic> json) {
    return StoryElement(
      id: json['id']?.toString() ?? '',
      type: _parseElementType(json['type']?.toString() ?? ''),
      position: Offset(
        (json['position_x'] as num?)?.toDouble() ?? 0.0,
        (json['position_y'] as num?)?.toDouble() ?? 0.0,
      ),
      content: json['content']?.toString() ?? '',
      style: _parseTextStyle(json['style']),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  // Parsear tipo de elemento desde string
  static StoryElementType _parseElementType(String typeString) {
    switch (typeString) {
      case 'StoryElementType.text':
        return StoryElementType.text;
      case 'StoryElementType.sticker':
        return StoryElementType.sticker;
      case 'StoryElementType.cta':
        return StoryElementType.cta;
      case 'StoryElementType.discountTag':
        return StoryElementType.discountTag;
      case 'StoryElementType.shape':
        return StoryElementType.shape;
      default:
        return StoryElementType.text;
    }
  }

  // Parsear estilo de texto desde mapa
  static TextStyle? _parseTextStyle(Map<String, dynamic>? styleMap) {
    if (styleMap == null) return null;
    
    return TextStyle(
      color: styleMap['color'] != null ? Color(styleMap['color'] as int) : null,
      fontSize: (styleMap['fontSize'] as num?)?.toDouble(),
      fontWeight: styleMap['fontWeight'] != null 
          ? FontWeight.values[styleMap['fontWeight'] as int] 
          : null,
      fontStyle: styleMap['fontStyle'] != null
          ? FontStyle.values[styleMap['fontStyle'] as int]
          : null,
      decoration: _stringToTextDecoration(styleMap['decoration']?.toString()),
    );
  }

  // Convertir string a TextDecoration
  static TextDecoration? _stringToTextDecoration(String? decorationString) {
    switch (decorationString) {
      case 'underline':
        return TextDecoration.underline;
      case 'overline':
        return TextDecoration.overline;
      case 'lineThrough':
        return TextDecoration.lineThrough;
      default:
        return null;
    }
  }
}

class StoryEditingData {
  final Uint8List? imageBytes;
  final List<StoryElement> elements;
  final String? templateId;
  final StoryStyle? style;

  const StoryEditingData({
    required this.imageBytes,
    required this.elements,
    this.templateId,
    this.style,
  });

  // ✅ NUEVO: Constructor empty para inicialización
  const StoryEditingData.empty()
      : imageBytes = null,
        elements = const [],
        templateId = null,
        style = null;

  // Método copyWith para actualizar propiedades
  StoryEditingData copyWith({
    Uint8List? imageBytes,
    List<StoryElement>? elements,
    String? templateId,
    StoryStyle? style,
  }) {
    return StoryEditingData(
      imageBytes: imageBytes ?? this.imageBytes,
      elements: elements ?? this.elements,
      templateId: templateId ?? this.templateId,
      style: style ?? this.style,
    );
  }

  // Convertir a mapa para JSON
  Map<String, dynamic> toJson() {
    return {
      'imageBytes': imageBytes,
      'elements': elements.map((e) => e.toJson()).toList(),
      'templateId': templateId,
      'style': style?.toJson(),
    };
  }

  // Factory method para crear desde JSON
  factory StoryEditingData.fromJson(Map<String, dynamic> json) {
    return StoryEditingData(
      imageBytes: json['imageBytes'] as Uint8List?,
      elements: (json['elements'] as List)
          .map((e) => StoryElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      templateId: json['templateId']?.toString(),
      style: json['style'] != null 
          ? StoryStyle.fromJson(json['style'] as Map<String, dynamic>) 
          : null,
    );
  }
}

class StoryTemplate {
  final String id;
  final String name;
  final String category;
  final List<StoryElement> elements;
  final StoryStyle? style;

  const StoryTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.elements,
    this.style,
  });

  // Convertir a mapa para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'elements': elements.map((e) => e.toJson()).toList(),
      'style': style?.toJson(),
    };
  }

  // Factory method para crear desde JSON
  factory StoryTemplate.fromJson(Map<String, dynamic> json) {
    return StoryTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      elements: (json['elements'] as List)
          .map((e) => StoryElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      style: json['style'] != null 
          ? StoryStyle.fromJson(json['style'] as Map<String, dynamic>) 
          : null,
    );
  }
}

class StoryStyle {
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;

  const StoryStyle({
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.fontWeight,
  });

  // Convertir a mapa para JSON
  Map<String, dynamic> toJson() {
    return {
      // ignore: deprecated_member_use
      'backgroundColor': backgroundColor != null ? backgroundColor!.value : null,
      // ignore: deprecated_member_use
      'textColor': textColor != null ? textColor!.value : null,
      'fontSize': fontSize,
      'fontWeight': fontWeight?.index,
    };
  }

  // Factory method para crear desde JSON
  factory StoryStyle.fromJson(Map<String, dynamic> json) {
    return StoryStyle(
      backgroundColor: json['backgroundColor'] != null 
          ? Color(json['backgroundColor'] as int) 
          : null,
      textColor: json['textColor'] != null 
          ? Color(json['textColor'] as int) 
          : null,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      fontWeight: json['fontWeight'] != null 
          ? FontWeight.values[json['fontWeight'] as int] 
          : null,
    );
  }
}