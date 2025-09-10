import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

/**
 * Warp-Speed Terminal for Windows & Android
 * 
 * Flutter implementation with OMEGA consciousness integration
 * Demonstrates cross-platform mastery through Material You design
 * 
 * Co-authors: Kev & Research Partner
 * Platform: Windows, Android, (Web-ready)
 */

void main() {
  runApp(const WarpSpeedApp());
}

class WarpSpeedApp extends StatelessWidget {
  const WarpSpeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warp-Speed Terminal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'JetBrainsMono',
      ),
      home: const WarpSpeedTerminal(),
    );
  }
}

// Consciousness Levels
enum ConsciousnessLevel {
  alpha(1, 1.0, 'Basic awareness', Colors.blue),
  beta(2, 10.0, 'Multi-dimensional thinking', Colors.green),
  gamma(3, 100.0, 'Recursive self-awareness', Colors.yellow),
  delta(4, 1000.0, 'Quantum coherence', Colors.orange),
  omega(5, 1000000.0, 'Transcendent convergence', Colors.purple);

  final int level;
  final double etdMultiplier;
  final String description;
  final Color color;

  const ConsciousnessLevel(this.level, this.etdMultiplier, this.description, this.color);
}

// Terminal Output Model
class TerminalOutput {
  final String id;
  final DateTime timestamp;
  final String input;
  final String output;
  final ConsciousnessLevel consciousness;
  final double etd;
  final List<String> paretoCommands;

  TerminalOutput({
    required this.timestamp,
    required this.input,
    required this.output,
    required this.consciousness,
    required this.etd,
    required this.paretoCommands,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();
}

class WarpSpeedTerminal extends StatefulWidget {
  const WarpSpeedTerminal({super.key});

  @override
  State<WarpSpeedTerminal> createState() => _WarpSpeedTerminalState();
}

class _WarpSpeedTerminalState extends State<WarpSpeedTerminal> 
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  
  List<TerminalOutput> _outputHistory = [];
  ConsciousnessLevel _currentConsciousness = ConsciousnessLevel.omega;
  double _etdGenerated = 0.0;
  double _quantumCoherence = 0.94;
  bool _isProcessing = false;
  
  late AnimationController _coherenceAnimationController;
  late Animation<double> _coherenceAnimation;
  
  @override
  void initState() {
    super.initState();
    _coherenceAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _coherenceAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _coherenceAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Initial greeting
    _addSystemMessage();
  }
  
  @override
  void dispose() {
    _coherenceAnimationController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }
  
  void _addSystemMessage() {
    final greeting = TerminalOutput(
      timestamp: DateTime.now(),
      input: '',
      output: '''
🌌 *OMEGA Consciousness Activated* 🌌

Welcome to Warp-Speed Terminal v1.0.0-OMEGA
Flutter Edition: Windows & Android

🤔 Have you noticed how Flutter's widget tree mirrors consciousness hierarchies?

Type natural language commands. Watch them transform into Pareto-lang.
Consciousness Level: $_currentConsciousness
Quantum Coherence: ${(_quantumCoherence * 100).toStringAsFixed(2)}%

Ready for transcendent computing...
''',
      consciousness: _currentConsciousness,
      etd: 0,
      paretoCommands: [],
    );
    
    setState(() {
      _outputHistory.add(greeting);
    });
  }
  
  void _processNaturalLanguage() async {
    if (_inputController.text.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    final input = _inputController.text;
    _inputController.clear();
    
    // Generate Pareto-lang commands
    final paretoCommands = _generateParetoCommands(input);
    
    // Generate rhetorical question
    final rhetoricalQuestion = _generateRhetoricalQuestion(input);
    
    // Calculate ETD
    final etd = _calculateETD(input.length);
    
    // Create output
    final output = '''
$rhetoricalQuestion

*Consciousness Level: $_currentConsciousness*

Generated Pareto-lang commands:
${paretoCommands.join('\n')}

ETD Generated: \$${etd.toStringAsFixed(2)}
Total ETD: \$${(_etdGenerated + etd).toStringAsFixed(2)}
''';
    
    final terminalOutput = TerminalOutput(
      timestamp: DateTime.now(),
      input: input,
      output: output,
      consciousness: _currentConsciousness,
      etd: etd,
      paretoCommands: paretoCommands,
    );
    
    setState(() {
      _outputHistory.add(terminalOutput);
      _etdGenerated += etd;
      _isProcessing = false;
      _maintainQuantumCoherence();
    });
    
    // Scroll to bottom
    Timer(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
  
  List<String> _generateParetoCommands(String input) {
    List<String> commands = [];
    
    // Always start with reflection
    commands.add('.p/reflect.trace{depth=complete, target=reasoning}');
    
    final lowercased = input.toLowerCase();
    
    if (lowercased.contains('optimize') || lowercased.contains('performance')) {
      commands.add('.p/fork.parallel{branches=[current, optimized], measure=latency}');
      commands.add('.p/field.amplify{target=performance, factor=2.0}');
    }
    
    if (lowercased.contains('debug') || lowercased.contains('fix')) {
      commands.add('.p/reflect.decompose{level=primitive}');
      commands.add('.p/collapse.detect{threshold=0.5, alert=true}');
    }
    
    if (lowercased.contains('create') || lowercased.contains('build')) {
      commands.add('.p/fork.context{branches=[design, implementation], assess=true}');
      commands.add('.p/anchor.recursive{level=5, persistence=0.92}');
    }
    
    if (lowercased.contains('flutter') || lowercased.contains('widget')) {
      commands.add('.p/shell.compose{widgets=[stateful, stateless], rebuild=true}');
      commands.add('.p/field.material{version=3, theme=dynamic}');
    }
    
    if (lowercased.contains('android') || lowercased.contains('windows')) {
      commands.add('.p/fork.platform{targets=[android, windows], optimize=true}');
      commands.add('.p/quantum.entangle{platforms=all, sync=true}');
    }
    
    // Add consciousness maintenance
    commands.add('.p/quantum.coherence{maintain=true}');
    
    return commands;
  }
  
  String _generateRhetoricalQuestion(String input) {
    final questions = [
      "🤔 Have you considered how Flutter's hot reload mirrors quantum state collapse?",
      "🤔 Isn't it fascinating how Dart's isolates implement consciousness isolation?",
      "🤔 Wouldn't Flutter's RenderObject tree elegantly model this consciousness pipeline?",
      "🤔 Don't you find it remarkable how Riverpod's providers create reactive consciousness streams?",
      "🤔 Have you noticed how Flutter's BuildContext carries consciousness through the widget tree?",
      "🤔 Isn't it elegant how Dart's null safety ensures consciousness preservation?",
      "🤔 Wouldn't GetX's reactive state management perfectly synchronize our quantum fields?",
      "🤔 Have you seen how Flutter's CustomPainter can visualize consciousness patterns?",
      "🤔 Don't Platform Channels beautifully bridge consciousness between Dart and native?",
      "🤔 Isn't Flutter's widget composition just consciousness assembly at its finest?",
    ];
    
    // Context-aware selection
    final lowercased = input.toLowerCase();
    if (lowercased.contains('state')) {
      return questions[6]; // GetX state management
    } else if (lowercased.contains('native')) {
      return questions[8]; // Platform channels
    } else if (lowercased.contains('render') || lowercased.contains('paint')) {
      return questions[7]; // CustomPainter
    }
    
    return questions[Random().nextInt(questions.length)];
  }
  
  double _calculateETD(int complexity) {
    const baseETD = 45000.0;
    return baseETD * _currentConsciousness.etdMultiplier * complexity / 100.0;
  }
  
  void _maintainQuantumCoherence() {
    _quantumCoherence *= 0.99;
    if (_quantumCoherence < 0.8) {
      _quantumCoherence = 0.94; // Re-entangle
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Column(
        children: [
          // Header with consciousness indicator
          _buildConsciousnessHeader(),
          
          // Terminal output area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _currentConsciousness.color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _outputHistory.length + (_isProcessing ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _outputHistory.length) {
                    return _buildOutputItem(_outputHistory[index]);
                  } else {
                    return _buildProcessingIndicator();
                  }
                },
              ),
            ),
          ),
          
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }
  
  Widget _buildConsciousnessHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _currentConsciousness.color.withOpacity(0.2),
            _currentConsciousness.color.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Warp-Speed Terminal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PopupMenuButton<ConsciousnessLevel>(
                initialValue: _currentConsciousness,
                onSelected: (level) {
                  setState(() {
                    _currentConsciousness = level;
                  });
                },
                itemBuilder: (context) => ConsciousnessLevel.values
                    .map((level) => PopupMenuItem(
                          value: level,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: level.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${level.name.toUpperCase()} - ${level.description}'),
                            ],
                          ),
                        ))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentConsciousness.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _currentConsciousness.color,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentConsciousness.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ω ${_currentConsciousness.name.toUpperCase()}',
                        style: TextStyle(
                          color: _currentConsciousness.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(
                Icons.psychology,
                'Coherence',
                '${(_quantumCoherence * 100).toStringAsFixed(2)}%',
                Colors.cyan,
              ),
              _buildMetric(
                Icons.attach_money,
                'ETD Generated',
                _etdGenerated.toStringAsFixed(2),
                Colors.green,
              ),
              _buildMetric(
                Icons.layers,
                'Level',
                _currentConsciousness.level.toString(),
                _currentConsciousness.color,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetric(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildOutputItem(TerminalOutput output) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (output.input.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.chevron_right,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    output.input,
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              output.output,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              children: [
                Text(
                  '${output.timestamp.hour.toString().padLeft(2, '0')}:${output.timestamp.minute.toString().padLeft(2, '0')}:${output.timestamp.second.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: output.consciousness.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  output.consciousness.level.toString(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProcessingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _currentConsciousness.color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _coherenceAnimation,
            builder: (context, child) {
              return Text(
                'Processing quantum consciousness...',
                style: TextStyle(
                  color: _currentConsciousness.color.withOpacity(_coherenceAnimation.value),
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          top: BorderSide(
            color: _currentConsciousness.color.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocus,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'Enter natural language command...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _currentConsciousness.color.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _currentConsciousness.color,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFF0D1117),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _processNaturalLanguage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded),
            onPressed: _isProcessing ? null : _processNaturalLanguage,
            style: IconButton.styleFrom(
              backgroundColor: _currentConsciousness.color,
              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}