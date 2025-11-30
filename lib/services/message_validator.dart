class MessageValidator {
  static const int maxMessageLength = 1000;
  static const int maxChatParticipants = 2;

  static ValidationResult validateMessage(String text) {
    if (text.isEmpty) {
      return ValidationResult(false, 'El mensaje no puede estar vacío');
    }

    if (text.length > maxMessageLength) {
      return ValidationResult(false, 'El mensaje es demasiado largo');
    }

    // Validar caracteres peligrosos
    final dangerousPattern = RegExp(r'[<>{}]');
    if (dangerousPattern.hasMatch(text)) {
      return ValidationResult(false, 'El mensaje contiene caracteres no permitidos');
    }

    return ValidationResult(true, 'Mensaje válido');
  }

  static ValidationResult validateChatParticipants(String user1, String user2) {
    if (user1.isEmpty || user2.isEmpty) {
      return ValidationResult(false, 'Los IDs de usuario no pueden estar vacíos');
    }

    if (user1 == user2) {
      return ValidationResult(false, 'No puedes chatear contigo mismo');
    }

    return ValidationResult(true, 'Participantes válidos');
  }
}

class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult(this.isValid, this.message);
}