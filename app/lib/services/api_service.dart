import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market.dart';
import '../models/prompt.dart';

class ApiService {
  static const String defaultBaseUrl = 'https://api.finance-app.com';
  String _baseUrl = defaultBaseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  Future<String> getBaseUrl() async {
    return _baseUrl;
  }

  Future<MarketData> getMarketData(String symbol) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/market/$symbol'));
    if (response.statusCode == 200) {
      return MarketData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load market data: ${response.statusCode}');
    }
  }

  Future<MarketHistory> getMarketHistory(String symbol, {String period = '1mo'}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/market/history/$symbol?period=$period'),
    );
    if (response.statusCode == 200) {
      return MarketHistory.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load market history: ${response.statusCode}');
    }
  }

  Future<List<Prompt>> getPrompts() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/prompts'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Prompt.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load prompts: ${response.statusCode}');
    }
  }

  Future<Prompt> createPrompt(Prompt prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/prompts'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(prompt.toJson()),
    );
    if (response.statusCode == 200) {
      return Prompt.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create prompt: ${response.statusCode}');
    }
  }

  Future<Prompt> updatePrompt(String id, Prompt prompt) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/prompts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(prompt.toJson()),
    );
    if (response.statusCode == 200) {
      return Prompt.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update prompt: ${response.statusCode}');
    }
  }

  Future<void> deletePrompt(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/prompts/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete prompt: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> generateNews(String prompt, String provider) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/ai/news'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'prompt': prompt,
        'provider': provider,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to generate news: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getEconomicIndicators() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/econ/indicators'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load indicators: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getBondYields() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/econ/bonds'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load bonds: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getCurrency(String pair) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/econ/currency/$pair'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load currency: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getCommodity(String name) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/econ/commodity/$name'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load commodity: ${response.statusCode}');
    }
  }
}