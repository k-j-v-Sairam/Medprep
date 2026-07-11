import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/final_combined_dataset.json');
  final jsonStr = file.readAsStringSync();
  final Map<String, dynamic> data = jsonDecode(jsonStr);
  
  final topics = data['topics'] as List<dynamic>;
  print('All topics:');
  for (var t in topics) {
    print(' - ${t['id']}: ${t['name']} (subject_id: ${t['subject_id']})');
  }
}
