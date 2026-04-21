class Prompt {
  final String id;
  final String name;
  final String prompt;
  final String frequency;
  final bool enabled;
  final String aiProvider;
  final DateTime createdAt;
  final DateTime? lastRun;

  Prompt({
    required this.id,
    required this.name,
    required this.prompt,
    required this.frequency,
    required this.enabled,
    required this.aiProvider,
    required this.createdAt,
    this.lastRun,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      prompt: json['prompt'] ?? '',
      frequency: json['frequency'] ?? 'daily',
      enabled: json['enabled'] ?? true,
      aiProvider: json['ai_provider'] ?? 'google',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastRun: json['last_run'] != null
          ? DateTime.parse(json['last_run'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'prompt': prompt,
      'frequency': frequency,
      'enabled': enabled,
      'ai_provider': aiProvider,
    };
  }
}