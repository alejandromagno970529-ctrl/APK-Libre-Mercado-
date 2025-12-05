import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final_app/models/transaction_agreement.dart';
import 'package:libre_mercado_final_app/utils/logger.dart';

class AgreementProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  final Map<String, List<TransactionAgreement>> _agreementsByChat = {};
  bool _isLoading = false;
  String? _error;

  AgreementProvider(this._supabase);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAgreementsForChat(String chatId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.d('📋 Cargando acuerdos para chat: $chatId');
      
      final response = await _supabase
          .from('transaction_agreements')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false);

      _agreementsByChat[chatId] = (response as List)
          .map((data) => TransactionAgreement.fromJson(Map<String, dynamic>.from(data)))
          .toList();

      AppLogger.d('✅ Acuerdos cargados para chat $chatId: ${_agreementsByChat[chatId]?.length ?? 0}');
    } catch (e) {
      _error = 'Error al cargar acuerdos: $e';
      AppLogger.e('Error cargando acuerdos', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TransactionAgreement> getAgreements(String chatId) {
    return _agreementsByChat[chatId] ?? [];
  }

  Future<TransactionAgreement> createAgreement(TransactionAgreement agreement) async {
    try {
      AppLogger.d('📝 Creando nuevo acuerdo para chat: ${agreement.chatId}');
      
      final response = await _supabase
          .from('transaction_agreements')
          .insert(agreement.toJsonForInsert())
          .select()
          .single();

      final newAgreement = TransactionAgreement.fromJson(response);
      
      if (!_agreementsByChat.containsKey(agreement.chatId)) {
        _agreementsByChat[agreement.chatId] = [];
      }
      _agreementsByChat[agreement.chatId]!.insert(0, newAgreement);
      
      AppLogger.d('✅ Acuerdo creado exitosamente: ${newAgreement.id}');
      notifyListeners();
      
      return newAgreement;
    } catch (e) {
      _error = 'Error al crear acuerdo: $e';
      AppLogger.e('Error creando acuerdo', e);
      rethrow;
    }
  }

  Future<void> updateAgreementStatus(String agreementId, String newStatus) async {
    try {
      AppLogger.d('🔄 Actualizando estado del acuerdo: $agreementId -> $newStatus');
      
      await _supabase
          .from('transaction_agreements')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', agreementId);

      for (final chatId in _agreementsByChat.keys) {
        final index = _agreementsByChat[chatId]!.indexWhere((a) => a.id == agreementId);
        if (index != -1) {
          final oldAgreement = _agreementsByChat[chatId]![index];
          _agreementsByChat[chatId]![index] = TransactionAgreement(
            id: oldAgreement.id,
            chatId: oldAgreement.chatId,
            productId: oldAgreement.productId,
            buyerId: oldAgreement.buyerId,
            sellerId: oldAgreement.sellerId,
            agreedPrice: oldAgreement.agreedPrice,
            meetingLocation: oldAgreement.meetingLocation,
            meetingTime: oldAgreement.meetingTime,
            status: newStatus,
            createdAt: oldAgreement.createdAt,
            updatedAt: DateTime.now(),
          );
          break;
        }
      }
      
      AppLogger.d('✅ Estado del acuerdo actualizado');
      notifyListeners();
    } catch (e) {
      _error = 'Error al actualizar acuerdo: $e';
      AppLogger.e('Error actualizando acuerdo', e);
      rethrow;
    }
  }

  Stream<List<TransactionAgreement>> getAgreementStream(String chatId) {
    return _supabase
        .from('transaction_agreements')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map((data) {
          final list = data as List;
          return list
              .map((agreementData) => TransactionAgreement.fromJson(Map<String, dynamic>.from(agreementData)))
              .toList();
        });
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}