import 'dart:convert';
import 'package:http/http.dart' as http;

class LinkPreviewService {
  static const String _baseUrl = 'http://localhost:3001/api';

  /// Extract metadata from a single URL
  static Future<LinkPreviewData?> getPreview(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/preview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LinkPreviewData.fromJson(data);
      } else {
        print(
          'Error getting preview: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error in getPreview: $e');
      return null;
    }
  }

  /// Extract metadata from multiple URLs
  static Future<List<LinkPreviewData>> getPreviews(List<String> urls) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/previews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'urls': urls}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => LinkPreviewData.fromJson(item)).toList();
      } else {
        print(
          'Error getting previews: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error in getPreviews: $e');
      return [];
    }
  }

  /// Check if backend is healthy
  static Future<bool> isHealthy() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking health: $e');
      return false;
    }
  }

  /// Clear the preview cache
  static Future<bool> clearCache() async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/clear-cache'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error clearing cache: $e');
      return false;
    }
  }
}

class LinkPreviewData {
  final String title;
  final String description;
  final String image;
  final String url;
  final String siteName;
  final bool hasError;

  LinkPreviewData({
    required this.title,
    required this.description,
    required this.image,
    required this.url,
    required this.siteName,
    this.hasError = false,
  });

  factory LinkPreviewData.fromJson(Map<String, dynamic> json) {
    return LinkPreviewData(
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? 'No description available',
      image: json['image'] ?? '',
      url: json['url'] ?? '',
      siteName: json['siteName'] ?? '',
      hasError: json['error'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'image': image,
      'url': url,
      'siteName': siteName,
      'error': hasError,
    };
  }

  @override
  String toString() {
    return 'LinkPreviewData(title: $title, description: $description, url: $url)';
  }
}
