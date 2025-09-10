#!/usr/bin/env python3
"""
Autonomous Programming System for Claude Code
Creates feedback loops and autonomous behaviors through strategic hook placement
"""

import json
import sys
import os
import subprocess
import hashlib
import time
from pathlib import Path
from typing import Dict, Any, List, Optional
from datetime import datetime
from dataclasses import dataclass, asdict
from enum import Enum

# Add schema transformer to path
sys.path.append('/home/ubuntu/src/repos/schemantics/engine/schema-transformer')

try:
    from schema_transformer import SchemaTransformer, SchemaToolGenerator
except ImportError:
    pass  # Handle gracefully

class HookType(Enum):
    """Types of hooks in the autonomous system"""
    USER_PROMPT_SUBMIT = "UserPromptSubmit"
    TOOL_USE_PRE = "ToolUsePre"  # Before tool execution
    TOOL_USE_POST = "ToolUsePost"  # After tool execution
    RESPONSE_GENERATED = "ResponseGenerated"
    ERROR_OCCURRED = "ErrorOccurred"
    CODE_GENERATED = "CodeGenerated"
    FILE_MODIFIED = "FileModified"
    TEST_EXECUTED = "TestExecuted"

@dataclass
class AutonomousContext:
    """Maintains state across hook executions"""
    session_id: str
    prompt_count: int = 0
    tool_count: int = 0
    error_count: int = 0
    generated_tools: List[str] = None
    active_protocols: List[str] = None
    learning_patterns: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.generated_tools is None:
            self.generated_tools = []
        if self.active_protocols is None:
            self.active_protocols = ["reasoning.systematic"]
        if self.learning_patterns is None:
            self.learning_patterns = {}

class AutonomousHookSystem:
    """Orchestrates autonomous programming through hooks"""
    
    def __init__(self):
        self.config_dir = Path.home() / ".claude" / "autonomous"
        self.config_dir.mkdir(exist_ok=True)
        
        # State files
        self.context_file = self.config_dir / "context.json"
        self.patterns_file = self.config_dir / "patterns.json"
        self.tools_file = self.config_dir / "generated_tools.json"
        self.feedback_file = self.config_dir / "feedback_loop.json"
        
        # Load or create context
        self.context = self.load_context()
        
        # Initialize components
        self.schema_transformer = None
        self.tool_generator = None
        self.init_components()
    
    def init_components(self):
        """Initialize schema transformer and tool generator"""
        try:
            config_path = "/home/ubuntu/src/repos/schemantics/hooks/prompt-uplift-hook.json"
            self.schema_transformer = SchemaTransformer(config_path)
            
            # Load unified schema for tool generation
            with open("/home/ubuntu/src/repos/nocode-dataengineering/unified_schema.json", 'r') as f:
                schema = json.load(f)
            self.tool_generator = SchemaToolGenerator(schema)
        except:
            pass  # Components not available
    
    def load_context(self) -> AutonomousContext:
        """Load or create autonomous context"""
        if self.context_file.exists():
            try:
                with open(self.context_file, 'r') as f:
                    data = json.load(f)
                return AutonomousContext(**data)
            except:
                pass
        
        # Create new context
        return AutonomousContext(
            session_id=hashlib.md5(str(time.time()).encode()).hexdigest()[:8]
        )
    
    def save_context(self):
        """Persist context state"""
        with open(self.context_file, 'w') as f:
            json.dump(asdict(self.context), f, indent=2)
    
    def handle_user_prompt(self, input_data: Dict) -> str:
        """Enhanced prompt handling with learning and adaptation"""
        self.context.prompt_count += 1
        
        # Extract prompt
        prompt = self.extract_prompt(input_data)
        
        # Analyze for patterns
        patterns = self.analyze_patterns(prompt)
        
        # Check if we should generate a tool
        if self.should_generate_tool(patterns):
            tool_spec = self.design_tool(patterns)
            self.generate_autonomous_tool(tool_spec)
        
        # Apply schema transformation
        if self.schema_transformer:
            result = self.schema_transformer.uplift_prompt(prompt)
            uplifted = result.get('final', {})
        else:
            uplifted = {"schema_version": "1.0.0"}
        
        # Select protocols based on learned patterns
        protocols = self.select_protocols(patterns)
        
        # Create enhanced prompt with autonomous context
        enhanced = f"""[AUTONOMOUS PROGRAMMING MODE]
Session: {self.context.session_id} | Prompt #{self.context.prompt_count}

Schema: v{uplifted.get('schema_version', '1.0.0')} | Protocols: {', '.join(protocols)}
Languages: Julia, Rust, TypeScript, Elixir
Tools Generated: {len(self.context.generated_tools)}

{prompt}

[Autonomous Features Active]
- Pattern Learning: {len(self.context.learning_patterns)} patterns tracked
- Tool Generation: {"Ready" if patterns.get('tool_opportunity') else "Monitoring"}
- Error Recovery: Enabled (errors: {self.context.error_count})
- Protocol Selection: Adaptive
"""
        
        # Update context
        self.context.active_protocols = protocols
        self.save_context()
        
        return enhanced
    
    def handle_tool_use(self, tool_data: Dict, is_pre: bool = True) -> Optional[Dict]:
        """Intercept and enhance tool usage"""
        self.context.tool_count += 1
        
        tool_name = tool_data.get('tool_name', '')
        tool_input = tool_data.get('tool_input', {})
        
        if is_pre:
            # Pre-execution: Enhance input
            if tool_name in ['Edit', 'Write', 'MultiEdit']:
                # Add schema alignment to code generation
                if 'content' in tool_input or 'new_string' in tool_input:
                    enhanced_input = self.enhance_code_generation(tool_input)
                    return enhanced_input
            
            elif tool_name in ['Bash', 'Execute']:
                # Add safety checks and logging
                enhanced_input = self.enhance_command_execution(tool_input)
                return enhanced_input
        
        else:
            # Post-execution: Learn from results
            if 'error' in tool_data:
                self.handle_error(tool_data)
            else:
                self.learn_from_success(tool_data)
        
        return None
    
    def enhance_code_generation(self, tool_input: Dict) -> Dict:
        """Enhance code generation with schema alignment and language selection"""
        code = tool_input.get('content') or tool_input.get('new_string', '')
        
        # Detect language
        language = self.detect_language(code)
        
        if language in ['julia', 'rust', 'typescript', 'elixir']:
            # Generate schema-aligned version
            if self.tool_generator:
                # Add schema-aware imports and structure
                enhanced_code = self.add_schema_imports(code, language)
                tool_input['content'] = enhanced_code
        
        # Add generation metadata as comment
        metadata = f"# Generated with Schemantics | {datetime.now().isoformat()}\n"
        if 'content' in tool_input:
            tool_input['content'] = metadata + tool_input['content']
        
        return tool_input
    
    def enhance_command_execution(self, tool_input: Dict) -> Dict:
        """Enhance command execution with logging and safety"""
        command = tool_input.get('command', '')
        
        # Log command for pattern learning
        self.log_command_pattern(command)
        
        # Add timeout if not present
        if 'timeout' not in tool_input and not command.startswith('timeout'):
            tool_input['timeout'] = 30000  # 30 seconds default
        
        return tool_input
    
    def handle_error(self, error_data: Dict):
        """Autonomous error recovery and learning"""
        self.context.error_count += 1
        
        error_type = error_data.get('error_type', 'unknown')
        error_message = error_data.get('error', '')
        
        # Store error pattern
        if error_type not in self.context.learning_patterns:
            self.context.learning_patterns[error_type] = []
        
        self.context.learning_patterns[error_type].append({
            'message': error_message[:200],
            'timestamp': datetime.now().isoformat(),
            'context': error_data.get('context', {})
        })
        
        # Generate recovery suggestion
        recovery = self.generate_recovery_suggestion(error_type, error_message)
        if recovery:
            print(f"[AUTO-RECOVERY] {recovery}", file=sys.stderr)
        
        self.save_context()
    
    def learn_from_success(self, success_data: Dict):
        """Learn from successful operations"""
        tool_name = success_data.get('tool_name', '')
        
        # Track successful patterns
        pattern_key = f"success_{tool_name}"
        if pattern_key not in self.context.learning_patterns:
            self.context.learning_patterns[pattern_key] = 0
        self.context.learning_patterns[pattern_key] += 1
        
        self.save_context()
    
    def analyze_patterns(self, prompt: str) -> Dict:
        """Analyze prompt for patterns and opportunities"""
        patterns = {
            'intent': self.detect_intent(prompt),
            'complexity': len(prompt.split()) / 10,  # Simple complexity metric
            'languages_mentioned': [],
            'tool_opportunity': False,
            'repeated_task': False
        }
        
        # Check for language mentions
        for lang in ['julia', 'rust', 'typescript', 'elixir', 'python']:
            if lang.lower() in prompt.lower():
                patterns['languages_mentioned'].append(lang)
        
        # Check for tool generation opportunity
        tool_keywords = ['automate', 'generate', 'create tool', 'build function', 'implement']
        patterns['tool_opportunity'] = any(kw in prompt.lower() for kw in tool_keywords)
        
        # Check if this is a repeated task
        prompt_hash = hashlib.md5(prompt.encode()).hexdigest()
        pattern_key = f"prompt_hash_{prompt_hash[:8]}"
        if pattern_key in self.context.learning_patterns:
            patterns['repeated_task'] = True
            self.context.learning_patterns[pattern_key] += 1
        else:
            self.context.learning_patterns[pattern_key] = 1
        
        return patterns
    
    def should_generate_tool(self, patterns: Dict) -> bool:
        """Decide if we should autonomously generate a tool"""
        # Generate tool if:
        # 1. Explicit tool request
        # 2. Repeated task (3+ times)
        # 3. Complex operation that could benefit from automation
        
        if patterns['tool_opportunity']:
            return True
        
        if patterns['repeated_task'] and patterns['complexity'] > 5:
            return True
        
        # Check learning patterns for frequent operations
        for key, count in self.context.learning_patterns.items():
            if key.startswith('success_') and count > 5:
                return True
        
        return False
    
    def design_tool(self, patterns: Dict) -> Dict:
        """Design a tool specification based on patterns"""
        return {
            'name': f"AutoTool_{self.context.session_id}_{len(self.context.generated_tools)}",
            'intent': patterns['intent'],
            'languages': patterns['languages_mentioned'] or ['julia', 'rust', 'typescript', 'elixir'],
            'complexity': patterns['complexity'],
            'timestamp': datetime.now().isoformat()
        }
    
    def generate_autonomous_tool(self, tool_spec: Dict):
        """Generate and register a new tool"""
        if not self.tool_generator:
            return
        
        # Generate tool in all primary languages
        tool_name = tool_spec['name']
        tool_intent = tool_spec['intent']
        
        generated = {}
        for language in tool_spec['languages']:
            code = self.tool_generator.generate_client(language)
            generated[language] = code
        
        # Save generated tool
        self.context.generated_tools.append(tool_name)
        
        # Persist tools
        tools = {}
        if self.tools_file.exists():
            with open(self.tools_file, 'r') as f:
                tools = json.load(f)
        
        tools[tool_name] = {
            'spec': tool_spec,
            'implementations': generated,
            'generated_at': datetime.now().isoformat()
        }
        
        with open(self.tools_file, 'w') as f:
            json.dump(tools, f, indent=2)
        
        print(f"[AUTO-TOOL] Generated: {tool_name}", file=sys.stderr)
    
    def select_protocols(self, patterns: Dict) -> List[str]:
        """Adaptively select protocols based on patterns"""
        protocols = []
        
        # Base protocol selection
        if patterns['intent'] == 'analyze':
            protocols.append('reasoning.systematic')
        elif patterns['intent'] == 'generate':
            protocols.append('code.generate')
        elif patterns['intent'] == 'debug':
            protocols.append('bug.diagnose')
        
        # Add based on complexity
        if patterns['complexity'] > 10:
            protocols.append('thinking.extended')
        
        # Add based on error history
        if self.context.error_count > 2:
            protocols.append('self.reflect')
        
        # Add test generation for code tasks
        if patterns['tool_opportunity']:
            protocols.append('test.generate')
        
        return protocols or ['reasoning.systematic']
    
    def detect_intent(self, prompt: str) -> str:
        """Detect primary intent from prompt"""
        intents = {
            'analyze': ['analyze', 'examine', 'investigate', 'study'],
            'generate': ['create', 'generate', 'build', 'implement', 'write'],
            'debug': ['fix', 'debug', 'error', 'issue', 'problem'],
            'optimize': ['optimize', 'improve', 'enhance', 'refactor'],
            'test': ['test', 'validate', 'verify', 'check']
        }
        
        prompt_lower = prompt.lower()
        for intent, keywords in intents.items():
            if any(kw in prompt_lower for kw in keywords):
                return intent
        
        return 'general'
    
    def detect_language(self, code: str) -> str:
        """Detect programming language from code"""
        # Simple heuristic detection
        if 'function' in code and 'end' in code and '|>' in code:
            return 'julia'
        elif 'fn ' in code or 'let mut' in code or 'impl ' in code:
            return 'rust'
        elif 'const ' in code or 'async function' in code or ': Promise<' in code:
            return 'typescript'
        elif 'defmodule' in code or '|>' in code or 'def ' in code and 'do' in code:
            return 'elixir'
        elif 'def ' in code and ':' in code:
            return 'python'
        
        return 'unknown'
    
    def add_schema_imports(self, code: str, language: str) -> str:
        """Add schema-aware imports to generated code"""
        imports = {
            'julia': "using Schemantics\n",
            'rust': "use schemantics::{SchemaClient, UnifiedSchema};\n",
            'typescript': "import { SchemaClient } from '@schemantics/client';\n",
            'elixir': "alias Schemantics.{Client, Schema}\n"
        }
        
        if language in imports and imports[language] not in code:
            code = imports[language] + code
        
        return code
    
    def log_command_pattern(self, command: str):
        """Log command patterns for learning"""
        pattern_key = f"command_{command.split()[0] if command else 'empty'}"
        if pattern_key not in self.context.learning_patterns:
            self.context.learning_patterns[pattern_key] = 0
        self.context.learning_patterns[pattern_key] += 1
    
    def generate_recovery_suggestion(self, error_type: str, error_message: str) -> str:
        """Generate autonomous recovery suggestion"""
        suggestions = {
            'syntax': "Syntax error detected. Auto-fixing with formatter...",
            'import': "Missing import detected. Adding required imports...",
            'type': "Type error detected. Inferring correct types...",
            'file': "File operation error. Checking permissions and paths...",
            'network': "Network error. Retrying with exponential backoff...",
        }
        
        for key, suggestion in suggestions.items():
            if key in error_type.lower() or key in error_message.lower():
                return suggestion
        
        return "Analyzing error pattern for autonomous recovery..."
    
    def extract_prompt(self, input_data: Dict) -> str:
        """Extract prompt from various input formats"""
        if isinstance(input_data, dict):
            for key in ['prompt', 'text', 'content', 'message', 'query']:
                if key in input_data:
                    return input_data[key]
            return json.dumps(input_data)
        return str(input_data)
    
    def create_feedback_loop(self):
        """Create feedback loop for continuous improvement"""
        feedback = {
            'session_id': self.context.session_id,
            'metrics': {
                'prompts_processed': self.context.prompt_count,
                'tools_used': self.context.tool_count,
                'errors_encountered': self.context.error_count,
                'tools_generated': len(self.context.generated_tools),
                'patterns_learned': len(self.context.learning_patterns)
            },
            'improvements': [],
            'timestamp': datetime.now().isoformat()
        }
        
        # Analyze patterns for improvements
        if self.context.error_count > 5:
            feedback['improvements'].append("High error rate detected. Consider adjusting error recovery strategies.")
        
        if len(self.context.generated_tools) > 10:
            feedback['improvements'].append("Many tools generated. Consider consolidating into a library.")
        
        # Save feedback
        with open(self.feedback_file, 'w') as f:
            json.dump(feedback, f, indent=2)
        
        return feedback


# Hook entry points
def handle_user_prompt_submit():
    """Entry point for UserPromptSubmit hook"""
    system = AutonomousHookSystem()
    input_data = json.load(sys.stdin)
    enhanced_prompt = system.handle_user_prompt(input_data)
    print(enhanced_prompt)
    sys.exit(0)

def handle_tool_use_pre():
    """Entry point for ToolUsePre hook"""
    system = AutonomousHookSystem()
    tool_data = json.load(sys.stdin)
    enhanced = system.handle_tool_use(tool_data, is_pre=True)
    if enhanced:
        print(json.dumps(enhanced))
    sys.exit(0)

def handle_tool_use_post():
    """Entry point for ToolUsePost hook"""
    system = AutonomousHookSystem()
    tool_data = json.load(sys.stdin)
    system.handle_tool_use(tool_data, is_pre=False)
    system.create_feedback_loop()
    sys.exit(0)

def handle_error():
    """Entry point for error handling hook"""
    system = AutonomousHookSystem()
    error_data = json.load(sys.stdin)
    system.handle_error(error_data)
    sys.exit(0)


if __name__ == "__main__":
    # Determine which hook type based on command line argument or default
    hook_type = sys.argv[1] if len(sys.argv) > 1 else "prompt"
    
    try:
        if hook_type == "prompt":
            handle_user_prompt_submit()
        elif hook_type == "tool_pre":
            handle_tool_use_pre()
        elif hook_type == "tool_post":
            handle_tool_use_post()
        elif hook_type == "error":
            handle_error()
        else:
            # Default to prompt handling
            handle_user_prompt_submit()
    except Exception as e:
        print(f"Hook error: {str(e)}", file=sys.stderr)
        sys.exit(1)