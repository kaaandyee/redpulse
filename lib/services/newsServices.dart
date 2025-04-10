import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:redpulse/features/models/newsModel.dart'; // Import your model class

Future<List<NewsArticle>> fetchHealthNews() async {
  const apiKey = '0dd469c5ec1d468197328dc1bd7fc881';  // Replace with your actual API key
  const url =
      'https://newsapi.org/v2/top-headlines?category=health&language=en&apiKey=$apiKey';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final List articles = jsonDecode(response.body)['articles'];
    return articles.map((json) => NewsArticle.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load health news');
  }
}
