// lib/utils/chat_setup_test.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatSetupTest {
  final SupabaseClient _supabase;

  ChatSetupTest(this._supabase);

  Future<void> testChatSystem() async {
    try {
      print('🧪 PROBANDO SISTEMA DE CHAT...');
      
      // 1. Verificar tablas
      // ignore: unused_local_variable
      final tables = await _supabase.from('chats').select('count').limit(1);
      print('✅ Tabla chats existe');
      
      // 2. Probar inserción de chat
      final testChat = await _supabase.from('chats').insert({
        'product_id': '00000000-0000-0000-0000-000000000000', // ID fake
        'buyer_id': _supabase.auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000000',
        'seller_id': '00000000-0000-0000-0000-000000000000',
      }).select();
      
      print('✅ Inserción de chat funciona');
      
      // 3. Probar mensaje
      if (testChat.isNotEmpty) {
        // ignore: unused_local_variable
        final testMessage = await _supabase.from('messages').insert({
          'chat_id': testChat.first['id'],
          'from_id': _supabase.auth.currentUser?.id,
          'text': 'Mensaje de prueba',
        }).select();
        
        print('✅ Inserción de mensaje funciona');
        
        // Limpiar
        await _supabase.from('messages').delete().eq('chat_id', testChat.first['id']);
        await _supabase.from('chats').delete().eq('id', testChat.first['id']);
      }
      
      print('🎉 SISTEMA DE CHAT CONFIGURADO CORRECTAMENTE');
      
    } catch (e) {
      print('❌ ERROR EN CONFIGURACIÓN: $e');
    }
  }
}