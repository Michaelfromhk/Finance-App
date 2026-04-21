import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _googleApiController = TextEditingController();
  final TextEditingController _openaiApiController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrlController.text = prefs.getString('base_url') ?? 'https://api.finance-app.com';
      _googleApiController.text = prefs.getString('google_api_key') ?? '';
      _openaiApiController.text = prefs.getString('openai_api_key') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('base_url', _baseUrlController.text);
      await prefs.setString('google_api_key', _googleApiController.text);
      await prefs.setString('openai_api_key', _openaiApiController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'https://api.finance-app.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _googleApiController,
              decoration: const InputDecoration(
                labelText: 'Google AI API Key',
                hintText: 'Enter your Google AI Studio API key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _openaiApiController,
              decoration: const InputDecoration(
                labelText: 'OpenAI API Key',
                hintText: 'Enter your OpenAI API key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveSettings,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finance App',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Version: 1.0.0'),
                    SizedBox(height: 8),
                    Text(
                      'A financial market intelligence app for tracking market data and AI-powered news analysis.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _googleApiController.dispose();
    _openaiApiController.dispose();
    super.dispose();
  }
}