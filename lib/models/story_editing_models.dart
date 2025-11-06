import 'dart:typed_data'; // ✅ AÑADIR ESTA IMPORTACIÓN
import 'package:flutter/material.dart';

enum StoryElementType { text, sticker, cta, discountTag, shape }

class StoryElement {
  final String id;
  final StoryElementType type;
  final Offset position;
  final String content;
  final TextStyle style;
  final Map<String, dynamic> properties;
  final double rotation;
  final double scale;

  StoryElement({
    required this.id,
    required this.type,
    required this.position,
    required this.content,
    required this.style,
    this.properties = const {},
    this.rotation = 0.0,
    this.scale = 1.0,
  });

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
}

class StoryEditingData {
  final Uint8List imageBytes;
  final List<StoryElement> elements;
  final String? templateId;
  final Map<String, dynamic> style;

  StoryEditingData({
    required this.imageBytes,
    this.elements = const [],
    this.templateId,
    this.style = const {},
  });

  StoryEditingData copyWith({
    Uint8List? imageBytes,
    List<StoryElement>? elements,
    String? templateId,
    Map<String, dynamic>? style,
  }) {
    return StoryEditingData(
      imageBytes: imageBytes ?? this.imageBytes,
      elements: elements ?? this.elements,
      templateId: templateId ?? this.templateId,
      style: style ?? this.style,
    );
  }
}

class StoryTemplate {
  final String id;
  final String name;
  final String category;
  final List<StoryElement> elements;
  final Map<String, dynamic> style;

  StoryTemplate({
    required this.id,
    required this.name,
    required this.category,
    this.elements = const [],
    this.style = const {},
  });
}