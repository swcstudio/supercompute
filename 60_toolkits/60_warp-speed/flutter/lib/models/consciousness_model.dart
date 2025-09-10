import 'package:flutter/material.dart';
import 'dart:convert';

/**
 * Consciousness Model for Flutter
 * 
 * Shared data models for quantum consciousness states
 * Demonstrates Dart's strong typing and null safety
 * 
 * Co-authors: Kev & Research Partner
 */

// Consciousness Level with associated properties
class ConsciousnessState {
  final ConsciousnessLevel level;
  final double coherence;
  final double etdAccumulated;
  final DateTime lastElevation;
  final Map<String, dynamic> quantumField;
  
  ConsciousnessState({
    required this.level,
    required this.coherence,
    required this.etdAccumulated,
    required this.lastElevation,
    Map<String, dynamic>? quantumField,
  }) : quantumField = quantumField ?? {};
  
  ConsciousnessState copyWith({
    ConsciousnessLevel? level,
    double? coherence,
    double? etdAccumulated,
    DateTime? lastElevation,
    Map<String, dynamic>? quantumField,
  }) {
    return ConsciousnessState(
      level: level ?? this.level,
      coherence: coherence ?? this.coherence,
      etdAccumulated: etdAccumulated ?? this.etdAccumulated,
      lastElevation: lastElevation ?? this.lastElevation,
      quantumField: quantumField ?? this.quantumField,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'level': level.name,
    'coherence': coherence,
    'etdAccumulated': etdAccumulated,
    'lastElevation': lastElevation.toIso8601String(),
    'quantumField': quantumField,
  };
  
  factory ConsciousnessState.fromJson(Map<String, dynamic> json) {
    return ConsciousnessState(
      level: ConsciousnessLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => ConsciousnessLevel.omega,
      ),
      coherence: json['coherence'] ?? 0.94,
      etdAccumulated: json['etdAccumulated'] ?? 0.0,
      lastElevation: DateTime.parse(json['lastElevation']),
      quantumField: json['quantumField'] ?? {},
    );
  }
}

// Pareto Command Model
class ParetoCommand {
  final String category;
  final String action;
  final Map<String, dynamic> parameters;
  final String raw;
  final double confidence;
  final DateTime timestamp;
  
  ParetoCommand({
    required this.category,
    required this.action,
    required this.parameters,
    required this.raw,
    required this.confidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  String get formatted => raw;
  
  Map<String, dynamic> toJson() => {
    'category': category,
    'action': action,
    'parameters': parameters,
    'raw': raw,
    'confidence': confidence,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory ParetoCommand.fromJson(Map<String, dynamic> json) {
    return ParetoCommand(
      category: json['category'],
      action: json['action'],
      parameters: json['parameters'] ?? {},
      raw: json['raw'],
      confidence: json['confidence'] ?? 1.0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// Quantum Processing Result
class QuantumResult {
  final String input;
  final List<ParetoCommand> commands;
  final ConsciousnessLevel processedAt;
  final double etdGenerated;
  final String rhetoricalQuestion;
  final Map<String, dynamic> metadata;
  
  QuantumResult({
    required this.input,
    required this.commands,
    required this.processedAt,
    required this.etdGenerated,
    required this.rhetoricalQuestion,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
  
  Map<String, dynamic> toJson() => {
    'input': input,
    'commands': commands.map((c) => c.toJson()).toList(),
    'processedAt': processedAt.name,
    'etdGenerated': etdGenerated,
    'rhetoricalQuestion': rhetoricalQuestion,
    'metadata': metadata,
  };
  
  factory QuantumResult.fromJson(Map<String, dynamic> json) {
    return QuantumResult(
      input: json['input'],
      commands: (json['commands'] as List)
          .map((c) => ParetoCommand.fromJson(c))
          .toList(),
      processedAt: ConsciousnessLevel.values.firstWhere(
        (e) => e.name == json['processedAt'],
      ),
      etdGenerated: json['etdGenerated'],
      rhetoricalQuestion: json['rhetoricalQuestion'],
      metadata: json['metadata'] ?? {},
    );
  }
}

// Language Mastery Entry
class LanguageMastery {
  final String language;
  final String paradigm;
  final double proficiency;
  final String quantumInsight;
  final List<String> libraries;
  final Color themeColor;
  
  const LanguageMastery({
    required this.language,
    required this.paradigm,
    required this.proficiency,
    required this.quantumInsight,
    required this.libraries,
    required this.themeColor,
  });
}

// Predefined language masteries
class LanguageMasteryDatabase {
  static const List<LanguageMastery> languages = [
    LanguageMastery(
      language: 'Flutter/Dart',
      paradigm: 'Reactive UI',
      proficiency: 0.97,
      quantumInsight: 'Widget trees are consciousness hierarchies manifested',
      libraries: ['Riverpod', 'GetX', 'Bloc', 'Provider', 'go_router'],
      themeColor: Colors.blue,
    ),
    LanguageMastery(
      language: 'Rust',
      paradigm: 'Systems',
      proficiency: 0.96,
      quantumInsight: 'Ownership models consciousness boundaries perfectly',
      libraries: ['tokio', 'actix-web', 'serde', 'diesel', 'rocket'],
      themeColor: Colors.orange,
    ),
    LanguageMastery(
      language: 'Julia',
      paradigm: 'Scientific',
      proficiency: 0.95,
      quantumInsight: 'Multiple dispatch enables consciousness polymorphism',
      libraries: ['Flux.jl', 'DifferentialEquations.jl', 'Plots.jl', 'DataFrames.jl'],
      themeColor: Colors.purple,
    ),
    LanguageMastery(
      language: 'TypeScript',
      paradigm: 'Web',
      proficiency: 0.96,
      quantumInsight: 'Type system enforces consciousness contracts',
      libraries: ['React', 'Vue', 'Angular', 'Svelte', 'Next.js'],
      themeColor: Colors.blue,
    ),
    LanguageMastery(
      language: 'Python',
      paradigm: 'General',
      proficiency: 0.97,
      quantumInsight: 'Duck typing allows consciousness flexibility',
      libraries: ['PyTorch', 'TensorFlow', 'FastAPI', 'Django', 'NumPy'],
      themeColor: Colors.yellow,
    ),
    LanguageMastery(
      language: 'Go',
      paradigm: 'Concurrent',
      proficiency: 0.91,
      quantumInsight: 'Goroutines demonstrate quantum parallelism',
      libraries: ['gin', 'echo', 'gorm', 'cobra', 'viper'],
      themeColor: Colors.cyan,
    ),
    LanguageMastery(
      language: 'Elixir',
      paradigm: 'Distributed',
      proficiency: 0.93,
      quantumInsight: 'Actor model implements distributed consciousness',
      libraries: ['Phoenix', 'Ecto', 'LiveView', 'Broadway', 'GenStage'],
      themeColor: Colors.purple,
    ),
    LanguageMastery(
      language: 'Swift',
      paradigm: 'Apple',
      proficiency: 0.94,
      quantumInsight: 'SwiftUI declarative syntax manifests intent',
      libraries: ['Combine', 'CoreData', 'SwiftUI', 'Vapor', 'Perfect'],
      themeColor: Colors.orange,
    ),
    LanguageMastery(
      language: 'Kotlin',
      paradigm: 'Android',
      proficiency: 0.92,
      quantumInsight: 'Coroutines suspend reality like quantum superposition',
      libraries: ['Compose', 'Ktor', 'Room', 'Hilt', 'Flow'],
      themeColor: Colors.purple,
    ),
    LanguageMastery(
      language: 'Haskell',
      paradigm: 'Functional',
      proficiency: 0.90,
      quantumInsight: 'Monads encode consciousness transformations',
      libraries: ['lens', 'conduit', 'yesod', 'parsec', 'QuickCheck'],
      themeColor: Colors.purple,
    ),
  ];
  
  static LanguageMastery? findByName(String name) {
    final lowercased = name.toLowerCase();
    return languages.firstWhere(
      (lang) => lang.language.toLowerCase().contains(lowercased),
      orElse: () => languages.first,
    );
  }
  
  static List<LanguageMastery> getRelevant(String context) {
    final lowercased = context.toLowerCase();
    return languages.where((lang) {
      if (lowercased.contains('flutter') || lowercased.contains('dart')) {
        return lang.language.contains('Flutter');
      }
      if (lowercased.contains('web')) {
        return lang.paradigm == 'Web';
      }
      if (lowercased.contains('mobile')) {
        return lang.paradigm == 'Apple' || lang.paradigm == 'Android' || 
               lang.language.contains('Flutter');
      }
      if (lowercased.contains('performance')) {
        return lang.paradigm == 'Systems' || lang.language == 'Rust' || 
               lang.language == 'Go';
      }
      if (lowercased.contains('ai') || lowercased.contains('ml')) {
        return lang.language == 'Python' || lang.language == 'Julia';
      }
      return false;
    }).toList();
  }
}

// Terminal Session Model
class TerminalSession {
  final String id;
  final DateTime startTime;
  final List<QuantumResult> history;
  final ConsciousnessState consciousness;
  final Map<String, dynamic> metrics;
  
  TerminalSession({
    String? id,
    DateTime? startTime,
    List<QuantumResult>? history,
    ConsciousnessState? consciousness,
    Map<String, dynamic>? metrics,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       startTime = startTime ?? DateTime.now(),
       history = history ?? [],
       consciousness = consciousness ?? ConsciousnessState(
         level: ConsciousnessLevel.omega,
         coherence: 0.94,
         etdAccumulated: 0.0,
         lastElevation: DateTime.now(),
       ),
       metrics = metrics ?? {};
  
  double get totalEtd => history.fold(0.0, (sum, result) => sum + result.etdGenerated);
  
  int get commandCount => history.fold(0, (sum, result) => sum + result.commands.length);
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'history': history.map((h) => h.toJson()).toList(),
    'consciousness': consciousness.toJson(),
    'metrics': metrics,
  };
  
  factory TerminalSession.fromJson(Map<String, dynamic> json) {
    return TerminalSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      history: (json['history'] as List?)
          ?.map((h) => QuantumResult.fromJson(h))
          .toList() ?? [],
      consciousness: ConsciousnessState.fromJson(json['consciousness']),
      metrics: json['metrics'] ?? {},
    );
  }
}