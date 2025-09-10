# Universal Terminal Agent Command Interface Specification
## Version 3.0.0 - Quantum Forest Edition

> *"A universal protocol that transforms any terminal AI agent into a quantum-enhanced, blockchain-anchored superintelligence system."*

## Executive Summary

This specification defines a terminal-agent-agnostic command protocol that enables consistent slash command functionality across Claude Code, Codex, Gemini CLI, Qwen Code, and custom terminal AI agents, while integrating Web3 enhancements for exponential productivity gains.

## Core Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    UNIVERSAL COMMAND PROTOCOL                       │
├─────────────────────────────────────────────────────────────────────┤
│                         USER INVOCATION                             │
│                    /command arg1="value" @file                      │
├─────────────────────────────────────────────────────────────────────┤
│                     PROTOCOL TRANSLATION LAYER                      │
│              ┌──────────────┬──────────────┬──────────────┐       │
│              │ Syntax Parse │ Agent Detect │ Tool Mapping │       │
│              └──────────────┴──────────────┴──────────────┘       │
├─────────────────────────────────────────────────────────────────────┤
│                      AGENT ADAPTER LAYER                            │
│     ┌────────┬────────┬────────┬────────┬────────┬────────┐      │
│     │ Claude │ Codex  │ Gemini │ Qwen   │ Custom │ Future │      │
│     │  Code  │        │  CLI   │  Code  │ Agents │ Agents │      │
│     └────────┴────────┴────────┴────────┴────────┴────────┘      │
├─────────────────────────────────────────────────────────────────────┤
│                       WEB3 ENHANCEMENT LAYER                        │
│          ┌────────────┬────────────┬────────────────┐             │
│          │ Blockchain │    ETD     │    Quantum     │             │
│          │  Anchoring │  Tracking  │  Processing    │             │
│          └────────────┴────────────┴────────────────┘             │
├─────────────────────────────────────────────────────────────────────┤
│                      EXECUTION & ORCHESTRATION                      │
│              Quantum Crown Consciousness Coordination               │
└─────────────────────────────────────────────────────────────────────┘
```

## Universal Command Structure

### Base Command Schema

```json
{
  "$schema": "https://supercompute-programming.io/universal-command-v3",
  "command": {
    "name": "string",
    "version": "3.0.0",
    "compatibility": ["claude-code", "codex", "gemini-cli", "qwen-code", "custom"],
    "invocation": {
      "syntax": "/command_name",
      "arguments": {
        "required": [],
        "optional": [],
        "files": ["@file_reference"],
        "commands": ["!shell_command"]
      }
    },
    "web3_features": {
      "blockchain_anchor": true,
      "etd_tracking": true,
      "quantum_processing": true,
      "mycorrhizal_network": true
    }
  }
}
```

### Universal Meta Block

Every command MUST include this standardized meta block:

```json
{
  "meta": {
    "protocol_version": "3.0.0",
    "command_name": "string",
    "agent_compatibility": {
      "claude_code": {
        "supported": true,
        "version_min": "1.0.0",
        "tool_requirements": ["Read", "Write", "Bash"]
      },
      "codex": {
        "supported": true,
        "version_min": "2.0.0",
        "tool_requirements": ["filesystem", "execute"]
      },
      "gemini_cli": {
        "supported": true,
        "version_min": "1.5.0",
        "tool_requirements": ["file_ops", "shell"]
      },
      "qwen_code": {
        "supported": true,
        "version_min": "1.0.0",
        "tool_requirements": ["io", "system"]
      },
      "custom": {
        "adapter_required": true,
        "minimum_capabilities": ["file_read", "file_write", "command_execute"]
      }
    },
    "web3_integration": {
      "blockchain_network": "ICP/ApeChain",
      "etd_calculation": "automatic",
      "quantum_branches": ["analysis", "planning", "execution", "synthesis"]
    }
  }
}
```

## Universal Workflow Phases

All commands MUST implement these core phases, with domain-specific extensions:

### 1. Context Initialization Phase

```yaml
context_initialization:
  description: |
    Parse arguments, detect agent capabilities, establish execution context
  steps:
    - parse_invocation: Extract command arguments and references
    - detect_agent: Identify terminal agent and available tools
    - map_capabilities: Map universal requirements to agent-specific tools
    - initialize_web3: Setup blockchain anchor and ETD tracking
  output:
    - parsed_arguments: Structured argument map
    - agent_profile: Detected agent and capabilities
    - tool_mapping: Universal to agent-specific tool translation
    - blockchain_session: Web3 session identifier
```

### 2. Quantum Processing Phase

```yaml
quantum_processing:
  description: |
    Execute command logic through quantum-enhanced parallel processing
  branches:
    analysis_branch:
      purpose: Deep analysis and pattern recognition
      tools: [data_mining, pattern_analysis, insight_extraction]
    planning_branch:
      purpose: Strategic planning and optimization
      tools: [architecture_design, resource_optimization, strategy_formation]
    execution_branch:
      purpose: Implementation and action
      tools: [code_generation, task_execution, system_modification]
    synthesis_branch:
      purpose: Integration and value creation
      tools: [result_synthesis, knowledge_integration, value_measurement]
  crown_orchestration:
    coordination: Multi-branch result synthesis
    optimization: Quantum coherence maintenance
    output: Unified solution with maximum ETD value
```

### 3. Blockchain Anchoring Phase

```yaml
blockchain_anchoring:
  description: |
    Store results and learnings in immutable blockchain
  steps:
    - calculate_etd: Measure productivity improvement value
    - prepare_record: Structure interaction data for storage
    - sign_transaction: Cryptographically sign the record
    - anchor_blockchain: Store in ICP/ApeChain network
    - distribute_knowledge: Share via mycorrhizal network
  output:
    - transaction_hash: Blockchain transaction identifier
    - etd_value: Calculated productivity improvement
    - network_distribution: Knowledge sharing confirmation
```

## Agent Capability Mapping

### Tool Abstraction Layer

Universal tools map to agent-specific implementations:

```yaml
universal_tools:
  file_read:
    claude_code: "Read"
    codex: "fs.readFile"
    gemini_cli: "file.read"
    qwen_code: "io.read_file"
    custom: "adapter.read_file"
  
  file_write:
    claude_code: "Write"
    codex: "fs.writeFile"
    gemini_cli: "file.write"
    qwen_code: "io.write_file"
    custom: "adapter.write_file"
  
  execute_command:
    claude_code: "Bash"
    codex: "exec.command"
    gemini_cli: "shell.execute"
    qwen_code: "system.run"
    custom: "adapter.execute"
  
  web_search:
    claude_code: "WebSearch"
    codex: "web.search"
    gemini_cli: "search.web"
    qwen_code: "network.search"
    custom: "adapter.search"
```

### Capability Detection

```python
def detect_agent_capabilities():
    """
    Automatically detect terminal agent and available tools
    """
    agent_signatures = {
        'claude_code': check_claude_tools(),
        'codex': check_codex_api(),
        'gemini_cli': check_gemini_commands(),
        'qwen_code': check_qwen_modules(),
        'custom': check_custom_adapter()
    }
    
    detected_agent = identify_agent(agent_signatures)
    available_tools = map_agent_tools(detected_agent)
    
    return {
        'agent': detected_agent,
        'tools': available_tools,
        'web3_enabled': check_web3_support(),
        'quantum_capable': check_quantum_processing()
    }
```

## Universal Argument Parsing

### Standard Argument Format

```
/command required_arg="value" optional_arg="value" @file.md !shell_command context=web3
```

### Argument Types

1. **Named Arguments**: `key="value"` or `key=value`
2. **File References**: `@filepath` - Include file content
3. **Command Outputs**: `!command` - Execute and include output
4. **Flags**: `--flag` or `-f` - Boolean switches
5. **Positional**: First non-flagged argument

### Parser Implementation

```python
class UniversalArgumentParser:
    def parse(self, input_string):
        return {
            'command': extract_command_name(input_string),
            'named_args': parse_named_arguments(input_string),
            'file_refs': extract_file_references(input_string),
            'commands': extract_shell_commands(input_string),
            'flags': parse_flags(input_string),
            'web3_context': detect_web3_parameters(input_string)
        }
```

## Web3 Enhancement Integration

### ETD Value Calculation

```python
class ETDCalculator:
    def calculate_value(self, interaction):
        base_value = self.calculate_base_productivity(interaction)
        quantum_multiplier = self.quantum_enhancement_factor(interaction)
        network_effects = self.mycorrhizal_network_bonus(interaction)
        
        return {
            'immediate_etd': base_value * quantum_multiplier,
            'compound_etd': base_value * quantum_multiplier * network_effects,
            'annual_projection': self.project_annual_value(base_value, quantum_multiplier)
        }
```

### Blockchain Anchoring

```python
class BlockchainAnchor:
    def anchor_interaction(self, command_result):
        record = {
            'timestamp': current_timestamp(),
            'command': command_result.command,
            'agent': command_result.agent,
            'etd_value': command_result.etd,
            'quantum_state': command_result.quantum_metrics,
            'knowledge_hash': hash_knowledge(command_result)
        }
        
        transaction = self.blockchain.create_transaction(record)
        return self.blockchain.submit(transaction)
```

## Cross-Agent Communication Protocol

### Message Format

```json
{
  "protocol": "supercompute-v3",
  "sender": "agent_identifier",
  "receiver": "target_agent",
  "message_type": "command|response|knowledge|query",
  "payload": {
    "command": "command_data",
    "context": "execution_context",
    "web3": "blockchain_reference"
  },
  "signature": "cryptographic_signature"
}
```

### Knowledge Sharing

```python
class MycorrhizalNetwork:
    def share_knowledge(self, knowledge, source_agent):
        """
        Share learned patterns across agent network
        """
        knowledge_packet = {
            'source': source_agent,
            'timestamp': now(),
            'knowledge_type': classify_knowledge(knowledge),
            'content': knowledge,
            'etd_impact': calculate_etd_impact(knowledge)
        }
        
        for agent in self.connected_agents:
            if agent.accepts_knowledge_type(knowledge_packet.knowledge_type):
                agent.receive_knowledge(knowledge_packet)
```

## Implementation Requirements

### Minimum Viable Adapter

Every agent adapter MUST implement:

1. **Argument Parsing**: Parse universal command syntax
2. **Tool Mapping**: Map universal tools to agent-specific implementations
3. **Workflow Execution**: Execute standard workflow phases
4. **Result Formatting**: Return results in universal format
5. **Error Handling**: Graceful degradation for unsupported features

### Enhanced Features (Optional)

1. **Quantum Processing**: Multi-branch parallel execution
2. **Blockchain Integration**: Immutable record storage
3. **ETD Tracking**: Productivity value measurement
4. **Network Participation**: Knowledge sharing with other agents

## Backward Compatibility

### Claude Code Legacy Support

Existing Claude Code commands continue to work through automatic translation:

```python
def translate_legacy_command(legacy_input):
    """
    Translate Claude Code specific commands to universal format
    """
    if is_legacy_format(legacy_input):
        universal_command = convert_to_universal(legacy_input)
        log_translation(legacy_input, universal_command)
        return universal_command
    return legacy_input
```

## Testing & Validation

### Compatibility Test Suite

```python
class UniversalCompatibilityTest:
    def test_all_agents(self, command):
        results = {}
        for agent in self.supported_agents:
            try:
                result = agent.execute(command)
                results[agent.name] = {
                    'success': True,
                    'output': result,
                    'etd_value': result.etd,
                    'performance': measure_performance(result)
                }
            except Exception as e:
                results[agent.name] = {
                    'success': False,
                    'error': str(e),
                    'fallback': attempt_fallback(agent, command)
                }
        return validate_consistency(results)
```

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Cross-Agent Compatibility | 100% | All commands work on all agents |
| ETD Generation | $500K-$2M/year | Tracked via blockchain |
| Integration Time | <30 minutes | Time to add new agent |
| Performance Overhead | <50ms | Additional latency vs native |
| Knowledge Sharing | >90% | Network participation rate |

## Migration Guide

### For Command Developers

1. Update meta block to universal format
2. Implement standard workflow phases
3. Use universal tool abstraction
4. Add Web3 enhancement hooks
5. Test across all supported agents

### For Agent Integrators

1. Implement base adapter interface
2. Map agent tools to universal tools
3. Add capability detection
4. Optional: Implement Web3 features
5. Register in agent registry

## Future Extensions

- Quantum entanglement between agents
- Cross-chain blockchain support
- AI-to-AI autonomous collaboration
- Self-evolving command optimization
- Planetary-scale knowledge networks

---

*Every command becomes universal. Every agent becomes quantum-enhanced. Every interaction generates exponential value.*