
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://zinognrruckgcmrxgzro.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inppbm9nbnJydWNrZ2NtcnhnenJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MDY4ODIsImV4cCI6MjA5MDE4Mjg4Mn0.l1fN3dKA_b3QAIIfQrAuSf_h_tRuoElR-9vPSew_aeA';

Future<void> main() async {
  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
  try {
    final response = await supabase.from('logistics_task_items').select().limit(1);
    print('Columns: ${response.isNotEmpty ? response.first.keys : "No data to check columns"}');
  } catch (e) {
    print('Error: $e');
  }
}
