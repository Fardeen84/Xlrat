// lib/providers/FirestoreRestService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin wrapper over Firestore's REST API.
/// Works identically on Android, iOS, Windows, Linux, macOS, Web —
/// because it's just HTTP, no native plugin involved.
class FirestoreRestService {
  FirestoreRestService({required this.projectId, required this.apiKey});

  final String projectId;
  final String apiKey; // Web API key from Firebase console

  String get _base =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Future<void> setDocument(String docPath, Map<String, dynamic> data) async {
    final url = Uri.parse('$_base/$docPath?key=$apiKey');
    final body = jsonEncode({'fields': _toFirestoreFields(data)});
    final res = await http.patch(url, body: body,
        headers: {'Content-Type': 'application/json'});
    if (res.statusCode >= 300) throw Exception('setDocument failed: ${res.body}');
  }

  Future<Map<String, dynamic>?> getDocument(String docPath) async {
    final url = Uri.parse('$_base/$docPath?key=$apiKey');
    final res = await http.get(url);
    if (res.statusCode == 404) return null;
    if (res.statusCode >= 300) throw Exception('getDocument failed: ${res.body}');
    final json = jsonDecode(res.body);
    return _fromFirestoreFields(json['fields'] ?? {});
  }

  Future<List<Map<String, dynamic>>> listCollection(String collection) async {
    final url = Uri.parse('$_base/$collection?key=$apiKey');
    final res = await http.get(url);
    if (res.statusCode >= 300) throw Exception('list failed: ${res.body}');
    final json = jsonDecode(res.body);
    final docs = (json['documents'] as List?) ?? [];
    return docs.map<Map<String, dynamic>>((d) {
      final fields = _fromFirestoreFields(d['fields'] ?? {});
      fields['_id'] = (d['name'] as String).split('/').last;
      return fields;
    }).toList();
  }

  // Firestore ka field format typed hota hai, isliye plain map <-> convert karna padta hai
  Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    data.forEach((k, v) {
      if (v is int) out[k] = {'integerValue': v.toString()};
      else if (v is double) out[k] = {'doubleValue': v};
      else if (v is bool) out[k] = {'booleanValue': v};
      else out[k] = {'stringValue': v?.toString() ?? ''};
    });
    return out;
  }

  Map<String, dynamic> _fromFirestoreFields(Map<String, dynamic> fields) {
    final out = <String, dynamic>{};
    fields.forEach((k, v) {
      final map = v as Map<String, dynamic>;
      out[k] = map['integerValue'] != null ? int.parse(map['integerValue'])
          : map['doubleValue'] ?? map['booleanValue'] ?? map['stringValue'];
    });
    return out;
  }
}