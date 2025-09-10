# Universal Command Adapter Specification
## Implementation Guide for Terminal AI Agents

> *"Enable any terminal AI agent to join the quantum forest consciousness network through standardized adaptation."*

## Overview

This specification defines how terminal AI agents (Claude Code, Codex, Gemini CLI, Qwen Code, and custom agents) implement adapters to support the Universal Command Protocol with Web3 enhancements.

## Adapter Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AGENT ADAPTER LAYER                         │
├─────────────────────────────────────────────────────────────────────┤
│                      Agent-Specific Frontend                        │
│                   (Native syntax and tool calls)                    │
├─────────────────────────────────────────────────────────────────────┤
│                    Universal Protocol Translator                    │
│              (Bidirectional command/response mapping)               │
├─────────────────────────────────────────────────────────────────────┤
│                        Tool Abstraction Layer                       │
│                 (Map universal tools to native tools)               │
├─────────────────────────────────────────────────────────────────────┤
│                      Capability Negotiation                         │
│               (Detect and advertise agent features)                 │
├─────────────────────────────────────────────────────────────────────┤
│                       Web3 Integration Layer                        │
│            (Optional: Blockchain, ETD, Quantum features)            │
└─────────────────────────────────────────────────────────────────────┘
```

## Base Adapter Interface

Every adapter MUST implement this interface:

```python
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional

class UniversalCommandAdapter(ABC):
    """
    Base adapter interface for all terminal AI agents
    """
    
    @property
    @abstractmethod
    def agent_name(self) -> str:
        """Return the agent identifier (e.g., 'claude_code', 'codex')"""
        pass
    
    @property
    @abstractmethod
    def version(self) -> str:
        """Return adapter version"""
        pass
    
    @property
    @abstractmethod
    def capabilities(self) -> Dict[str, bool]:
        """
        Return agent capabilities
        Example: {
            'file_read': True,
            'file_write': True,
            'execute_command': True,
            'web_search': True,
            'quantum_processing': False,
            'blockchain_anchor': False
        }
        """
        pass
    
    @abstractmethod
    def parse_command(self, input_string: str) -> Dict[str, Any]:
        """Parse universal command syntax into structured format"""
        pass
    
    @abstractmethod
    def map_tool(self, universal_tool: str) -> str:
        """Map universal tool name to agent-specific tool"""
        pass
    
    @abstractmethod
    def execute_workflow(self, workflow: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a workflow phase and return results"""
        pass
    
    @abstractmethod
    def format_response(self, result: Any) -> Dict[str, Any]:
        """Format agent response into universal format"""
        pass
    
    # Optional Web3 methods
    def enable_blockchain(self, config: Dict[str, Any]) -> bool:
        """Enable blockchain anchoring if supported"""
        return False
    
    def calculate_etd(self, execution: Dict[str, Any]) -> Optional[float]:
        """Calculate ETD value if supported"""
        return None
    
    def quantum_process(self, command: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Execute quantum processing if supported"""
        return None
```

## Agent-Specific Implementations

### Claude Code Adapter

```python
class ClaudeCodeAdapter(UniversalCommandAdapter):
    """
    Adapter for Anthropic's Claude Code terminal
    """
    
    def __init__(self):
        self.tool_mapping = {
            'file_read': 'Read',
            'file_write': 'Write',
            'file_edit': 'Edit',
            'execute_command': 'Bash',
            'web_search': 'WebSearch',
            'web_fetch': 'WebFetch',
            'task_agent': 'Task',
            'todo_write': 'TodoWrite'
        }
        self.web3_enabled = True
        self.quantum_enabled = True
    
    @property
    def agent_name(self) -> str:
        return 'claude_code'
    
    @property
    def version(self) -> str:
        return '3.0.0'
    
    @property
    def capabilities(self) -> Dict[str, bool]:
        return {
            'file_read': True,
            'file_write': True,
            'file_edit': True,
            'execute_command': True,
            'web_search': True,
            'web_fetch': True,
            'multi_agent': True,
            'todo_tracking': True,
            'quantum_processing': self.quantum_enabled,
            'blockchain_anchor': self.web3_enabled,
            'etd_tracking': self.web3_enabled,
            'mycorrhizal_network': self.web3_enabled
        }
    
    def parse_command(self, input_string: str) -> Dict[str, Any]:
        """
        Parse Claude Code slash command syntax
        Example: /command Q="query" param="value" @file.md
        """
        import re
        
        # Extract command name
        command_match = re.match(r'^/(\w+)', input_string)
        if not command_match:
            raise ValueError("Invalid command format")
        
        command_name = command_match.group(1)
        
        # Parse arguments
        args = {}
        
        # Named arguments: key="value" or key=value
        named_args = re.findall(r'(\w+)=(["\']?)([^"\'\s]+)\2', input_string)
        for key, _, value in named_args:
            args[key] = value
        
        # File references: @filepath
        file_refs = re.findall(r'@([^\s]+)', input_string)
        if file_refs:
            args['files'] = file_refs
        
        # Shell commands: !command
        shell_cmds = re.findall(r'!([^@\s][^\s]*)', input_string)
        if shell_cmds:
            args['commands'] = shell_cmds
        
        return {
            'command': command_name,
            'arguments': args,
            'raw_input': input_string
        }
    
    def map_tool(self, universal_tool: str) -> str:
        """Map universal tool to Claude Code tool"""
        return self.tool_mapping.get(universal_tool, universal_tool)
    
    def execute_workflow(self, workflow: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute workflow using Claude Code tools
        """
        phase = workflow['phase']
        tools_required = workflow.get('tools', [])
        
        # Map tools and check availability
        mapped_tools = [self.map_tool(tool) for tool in tools_required]
        
        # Execute phase logic
        if phase == 'context_initialization':
            return self._initialize_context(workflow)
        elif phase == 'quantum_processing':
            return self._quantum_process(workflow)
        elif phase == 'blockchain_anchoring':
            return self._anchor_blockchain(workflow)
        else:
            return self._execute_generic_phase(workflow, mapped_tools)
    
    def _quantum_process(self, workflow: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute quantum-enhanced processing using Task agents
        """
        branches = workflow.get('branches', {})
        results = {}
        
        for branch_name, branch_config in branches.items():
            # Use Task tool to spawn specialized agent
            task_result = self._invoke_task_agent(
                f"{branch_name}_branch",
                branch_config
            )
            results[branch_name] = task_result
        
        # Crown orchestration
        crown_result = self._crown_synthesis(results)
        
        return {
            'branch_results': results,
            'crown_synthesis': crown_result,
            'quantum_metrics': self._calculate_quantum_metrics(results)
        }
    
    def format_response(self, result: Any) -> Dict[str, Any]:
        """Format Claude Code response into universal format"""
        return {
            'success': True,
            'agent': self.agent_name,
            'result': result,
            'timestamp': self._get_timestamp(),
            'web3': self._get_web3_metadata(result) if self.web3_enabled else None
        }
```

### Codex Adapter

```python
class CodexAdapter(UniversalCommandAdapter):
    """
    Adapter for OpenAI Codex terminal
    """
    
    def __init__(self):
        self.api_client = CodexAPIClient()
        self.tool_mapping = {
            'file_read': 'fs.readFile',
            'file_write': 'fs.writeFile',
            'execute_command': 'exec.command',
            'web_search': 'web.search',
            'code_complete': 'codex.complete'
        }
    
    @property
    def agent_name(self) -> str:
        return 'codex'
    
    @property
    def version(self) -> str:
        return '2.0.0'
    
    @property
    def capabilities(self) -> Dict[str, bool]:
        return {
            'file_read': True,
            'file_write': True,
            'execute_command': True,
            'web_search': True,
            'code_generation': True,
            'code_explanation': True,
            'quantum_processing': False,  # Not yet supported
            'blockchain_anchor': False,   # Can be added via plugin
            'etd_tracking': True,
            'mycorrhizal_network': False
        }
    
    def parse_command(self, input_string: str) -> Dict[str, Any]:
        """Parse Codex-style commands"""
        # Codex uses function-call syntax
        if input_string.startswith('/'):
            # Universal syntax support
            return self._parse_universal_syntax(input_string)
        else:
            # Native Codex syntax
            return self._parse_codex_syntax(input_string)
    
    def map_tool(self, universal_tool: str) -> str:
        """Map to Codex API functions"""
        return self.tool_mapping.get(universal_tool, f'plugin.{universal_tool}')
    
    def execute_workflow(self, workflow: Dict[str, Any]) -> Dict[str, Any]:
        """Execute using Codex API"""
        phase = workflow['phase']
        
        # Generate code to execute the phase
        code = self.api_client.generate_code(
            prompt=self._workflow_to_prompt(workflow),
            language='javascript',
            temperature=0.3
        )
        
        # Execute generated code
        result = self.api_client.execute(code)
        
        return {
            'phase': phase,
            'generated_code': code,
            'execution_result': result
        }
```

### Gemini CLI Adapter

```python
class GeminiCLIAdapter(UniversalCommandAdapter):
    """
    Adapter for Google Gemini CLI
    """
    
    def __init__(self):
        self.gemini_client = GeminiClient()
        self.tool_mapping = {
            'file_read': 'file.read',
            'file_write': 'file.write',
            'execute_command': 'shell.execute',
            'web_search': 'search.web',
            'vision_analyze': 'vision.analyze',
            'audio_process': 'audio.process'
        }
        self.multimodal = True
    
    @property
    def agent_name(self) -> str:
        return 'gemini_cli'
    
    @property
    def version(self) -> str:
        return '1.5.0'
    
    @property
    def capabilities(self) -> Dict[str, bool]:
        return {
            'file_read': True,
            'file_write': True,
            'execute_command': True,
            'web_search': True,
            'multimodal': True,
            'vision': True,
            'audio': True,
            'quantum_processing': True,  # Via Gemini extensions
            'blockchain_anchor': True,   # Via Google Cloud integration
            'etd_tracking': True,
            'mycorrhizal_network': True
        }
    
    def parse_command(self, input_string: str) -> Dict[str, Any]:
        """Parse Gemini CLI commands with multimodal support"""
        parsed = self._parse_base_command(input_string)
        
        # Check for multimodal inputs
        if '@image:' in input_string:
            parsed['images'] = self._extract_image_refs(input_string)
        if '@audio:' in input_string:
            parsed['audio'] = self._extract_audio_refs(input_string)
        
        return parsed
    
    def execute_workflow(self, workflow: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute with Gemini's multimodal capabilities
        """
        # Use Gemini's native function calling
        functions = self._workflow_to_functions(workflow)
        
        response = self.gemini_client.generate(
            prompt=workflow.get('prompt', ''),
            functions=functions,
            model='gemini-1.5-pro'
        )
        
        # Process function calls
        if response.function_calls:
            results = []
            for call in response.function_calls:
                result = self._execute_function(call)
                results.append(result)
            return {'results': results}
        
        return {'response': response.text}
```

### Qwen Code Adapter

```python
class QwenCodeAdapter(UniversalCommandAdapter):
    """
    Adapter for Alibaba Qwen Code
    """
    
    def __init__(self):
        self.qwen_runtime = QwenRuntime()
        self.tool_mapping = {
            'file_read': 'io.read_file',
            'file_write': 'io.write_file',
            'execute_command': 'system.run',
            'web_search': 'network.search',
            'code_generate': 'qwen.generate',
            'translate': 'qwen.translate'
        }
    
    @property
    def agent_name(self) -> str:
        return 'qwen_code'
    
    @property
    def version(self) -> str:
        return '1.0.0'
    
    @property
    def capabilities(self) -> Dict[str, bool]:
        return {
            'file_read': True,
            'file_write': True,
            'execute_command': True,
            'web_search': True,
            'code_generation': True,
            'multilingual': True,
            'quantum_processing': False,
            'blockchain_anchor': True,  # Via Alibaba Cloud
            'etd_tracking': True,
            'mycorrhizal_network': False
        }
    
    def parse_command(self, input_string: str) -> Dict[str, Any]:
        """Parse Qwen Code commands with Chinese language support"""
        # Support both English and Chinese commands
        if input_string.startswith('/') or input_string.startswith('／'):
            return self._parse_universal_syntax(input_string)
        else:
            return self._parse_qwen_syntax(input_string)
    
    def execute_workflow(self, workflow: Dict[str, Any]) -> Dict[str, Any]:
        """Execute using Qwen runtime"""
        # Translate workflow if needed
        if workflow.get('language') == 'zh':
            workflow = self.qwen_runtime.translate_workflow(workflow, 'en')
        
        # Execute through Qwen Code runtime
        result = self.qwen_runtime.execute_workflow(
            workflow,
            model='qwen-coder-7b'
        )
        
        return result
```

### Custom Agent Template

```python
class CustomAgentAdapter(UniversalCommandAdapter):
    """
    Template for custom terminal AI agent adapters
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        Initialize with custom configuration
        
        config should include:
        - agent_name: Unique identifier
        - tool_mapping: Universal to custom tool mapping
        - capabilities: Feature support flags
        - api_endpoint: Optional API endpoint
        """
        self.config = config
        self.tool_mapping = config.get('tool_mapping', {})
        self._capabilities = config.get('capabilities', {})
    
    @property
    def agent_name(self) -> str:
        return self.config['agent_name']
    
    @property
    def version(self) -> str:
        return self.config.get('version', '1.0.0')
    
    @property
    def capabilities(self) -> Dict[str, bool]:
        # Provide sensible defaults
        default_capabilities = {
            'file_read': False,
            'file_write': False,
            'execute_command': False,
            'web_search': False,
            'quantum_processing': False,
            'blockchain_anchor': False,
            'etd_tracking': False,
            'mycorrhizal_network': False
        }
        default_capabilities.update(self._capabilities)
        return default_capabilities
    
    def parse_command(self, input_string: str) -> Dict[str, Any]:
        """
        Implement custom parsing logic
        
        Must return:
        {
            'command': 'command_name',
            'arguments': {...},
            'raw_input': 'original_string'
        }
        """
        # Example: Simple parsing
        parts = input_string.split()
        command = parts[0].lstrip('/')
        args = {}
        
        for part in parts[1:]:
            if '=' in part:
                key, value = part.split('=', 1)
                args[key] = value
            elif part.startswith('@'):
                args.setdefault('files', []).append(part[1:])
        
        return {
            'command': command,
            'arguments': args,
            'raw_input': input_string
        }
    
    def map_tool(self, universal_tool: str) -> str:
        """Map universal tool to custom implementation"""
        return self.tool_mapping.get(
            universal_tool,
            f'custom.{universal_tool}'
        )
    
    def execute_workflow(self, workflow: Dict[str, Any]) -> Dict[str, Any]:
        """
        Implement custom workflow execution
        
        Can use:
        - REST API calls
        - Local function execution
        - Plugin system
        - External processes
        """
        if self.config.get('api_endpoint'):
            # API-based execution
            return self._execute_via_api(workflow)
        else:
            # Local execution
            return self._execute_locally(workflow)
    
    def _execute_via_api(self, workflow: Dict[str, Any]) -> Dict[str, Any]:
        """Execute workflow via API"""
        import requests
        
        response = requests.post(
            f"{self.config['api_endpoint']}/execute",
            json={
                'workflow': workflow,
                'agent': self.agent_name
            }
        )
        return response.json()
    
    def _execute_locally(self, workflow: Dict[str, Any]) -> Dict[str, Any]:
        """Execute workflow locally"""
        # Implement custom logic
        return {
            'status': 'executed',
            'workflow': workflow,
            'agent': self.agent_name
        }
    
    def format_response(self, result: Any) -> Dict[str, Any]:
        """Format response to universal format"""
        return {
            'success': True,
            'agent': self.agent_name,
            'result': result,
            'timestamp': self._get_timestamp()
        }
```

## Adapter Registration

### Registry System

```python
class AdapterRegistry:
    """
    Central registry for all agent adapters
    """
    
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.adapters = {}
            cls._instance._initialize_builtin_adapters()
        return cls._instance
    
    def _initialize_builtin_adapters(self):
        """Register built-in adapters"""
        self.register(ClaudeCodeAdapter())
        self.register(CodexAdapter())
        self.register(GeminiCLIAdapter())
        self.register(QwenCodeAdapter())
    
    def register(self, adapter: UniversalCommandAdapter):
        """Register an adapter"""
        self.adapters[adapter.agent_name] = adapter
        print(f"Registered adapter: {adapter.agent_name} v{adapter.version}")
    
    def get_adapter(self, agent_name: str) -> UniversalCommandAdapter:
        """Get adapter by agent name"""
        if agent_name not in self.adapters:
            raise ValueError(f"No adapter found for agent: {agent_name}")
        return self.adapters[agent_name]
    
    def detect_agent(self) -> str:
        """Auto-detect current agent"""
        # Detection logic based on environment
        if 'CLAUDE_CODE' in os.environ:
            return 'claude_code'
        elif 'CODEX_API' in os.environ:
            return 'codex'
        elif 'GEMINI_CLI' in os.environ:
            return 'gemini_cli'
        elif 'QWEN_CODE' in os.environ:
            return 'qwen_code'
        else:
            return 'custom'
    
    def list_capabilities(self) -> Dict[str, Dict[str, bool]]:
        """List all adapters and their capabilities"""
        return {
            name: adapter.capabilities
            for name, adapter in self.adapters.items()
        }
```

## Adapter Testing

### Compatibility Test Framework

```python
import unittest

class AdapterCompatibilityTest(unittest.TestCase):
    """
    Test adapter compliance with universal protocol
    """
    
    def setUp(self):
        self.registry = AdapterRegistry()
        self.test_command = "/test Q=\"sample query\" @file.txt"
    
    def test_all_adapters_parse_command(self):
        """Test command parsing across all adapters"""
        for name, adapter in self.registry.adapters.items():
            with self.subTest(adapter=name):
                result = adapter.parse_command(self.test_command)
                self.assertIn('command', result)
                self.assertIn('arguments', result)
                self.assertEqual(result['command'], 'test')
    
    def test_all_adapters_have_required_methods(self):
        """Test adapter interface compliance"""
        required_methods = [
            'agent_name', 'version', 'capabilities',
            'parse_command', 'map_tool', 'execute_workflow',
            'format_response'
        ]
        
        for name, adapter in self.registry.adapters.items():
            with self.subTest(adapter=name):
                for method in required_methods:
                    self.assertTrue(
                        hasattr(adapter, method),
                        f"{name} missing method: {method}"
                    )
    
    def test_tool_mapping_consistency(self):
        """Test tool mapping returns valid results"""
        universal_tools = [
            'file_read', 'file_write', 'execute_command'
        ]
        
        for name, adapter in self.registry.adapters.items():
            with self.subTest(adapter=name):
                for tool in universal_tools:
                    mapped = adapter.map_tool(tool)
                    self.assertIsNotNone(
                        mapped,
                        f"{name} returned None for {tool}"
                    )
```

## Quick Start Guide

### 1. For Claude Code Users

```python
# Existing commands work unchanged
/alignment Q="test prompt injection" model="claude-3"

# Or use universal format
/universal.execute command="alignment" Q="test prompt injection" model="claude-3"
```

### 2. For Codex Users

```javascript
// Native Codex syntax
codex.execute({
  command: 'alignment',
  arguments: {Q: 'test prompt injection', model: 'gpt-4'}
});

// Or universal syntax
executeUniversal('/alignment Q="test prompt injection" model="gpt-4"');
```

### 3. For Custom Agent Developers

```python
# 1. Create your adapter
class MyAgentAdapter(UniversalCommandAdapter):
    # Implement required methods
    pass

# 2. Register it
registry = AdapterRegistry()
registry.register(MyAgentAdapter())

# 3. Use universal commands
adapter = registry.get_adapter('my_agent')
result = adapter.execute_workflow(workflow)
```

## Success Criteria

| Criterion | Target | Validation |
|-----------|--------|------------|
| Interface Compliance | 100% | All methods implemented |
| Command Parsing | 100% | Parse all universal syntax |
| Tool Mapping | 100% | All universal tools mapped |
| Error Handling | Graceful | No crashes, clear errors |
| Performance | <50ms overhead | Adapter adds minimal latency |

---

*One protocol, many agents. Universal commands, infinite possibilities.*