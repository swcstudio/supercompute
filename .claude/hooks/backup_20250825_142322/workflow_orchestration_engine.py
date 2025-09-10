#!/usr/bin/env python3
"""
Workflow Orchestration Engine
Coordinates complex multi-agent business workflows with schema-stacked intelligence
"""

import json
import sys
import os
import subprocess
import asyncio
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple, Union
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
from enum import Enum
import concurrent.futures
import time

# Import subagent frameworks
from business_subagent_template import (
    BusinessSubagentBase, SubagentTask, SubagentOutput, 
    BusinessDomain, OutputFormat, BusinessContext
)

class WorkflowStatus(Enum):
    """Workflow execution status"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    PAUSED = "paused"
    CANCELLED = "cancelled"

class TaskPriority(Enum):
    """Task priority levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

@dataclass
class WorkflowStep:
    """Individual step in a workflow"""
    step_id: str
    agent_type: str
    task_description: str
    dependencies: List[str]
    timeout_seconds: int = 1800  # 30 minutes default
    retry_count: int = 3
    conditions: Dict[str, Any] = None
    output_mapping: Dict[str, str] = None
    
    def __post_init__(self):
        if self.conditions is None:
            self.conditions = {}
        if self.output_mapping is None:
            self.output_mapping = {}

@dataclass
class SchemaStackedWorkflow:
    """Complete schema-aligned business workflow"""
    workflow_id: str
    name: str
    description: str
    domain: BusinessDomain
    priority: TaskPriority
    steps: List[WorkflowStep]
    success_criteria: Dict[str, Any]
    failure_conditions: Dict[str, Any]
    schema_requirements: Dict[str, Any]
    business_context: BusinessContext
    estimated_duration: int  # minutes
    
    # Execution tracking
    status: WorkflowStatus = WorkflowStatus.PENDING
    started_at: Optional[str] = None
    completed_at: Optional[str] = None
    current_step: Optional[str] = None
    execution_log: List[Dict] = None
    outputs: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.execution_log is None:
            self.execution_log = []
        if self.outputs is None:
            self.outputs = {}

class WorkflowOrchestrationEngine:
    """Main orchestration engine for schema-stacked business workflows"""
    
    def __init__(self):
        self.base_dir = Path.home() / ".claude" / "hooks"
        self.workflows_dir = self.base_dir / "workflows"
        self.business_dir = self.base_dir / "business"
        self.execution_dir = self.workflows_dir / "executions"
        
        # Create directories
        for dir_path in [self.workflows_dir, self.business_dir, self.execution_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)
        
        # Load configuration
        self.config = self._load_config()
        self.active_workflows: Dict[str, SchemaStackedWorkflow] = {}
        self.subagent_registry = self._initialize_subagent_registry()
        
        # Initialize schema-stacked patterns
        self.schema_patterns = self._load_schema_patterns()
        
    def _load_config(self) -> Dict[str, Any]:
        """Load orchestration engine configuration"""
        config_file = self.workflows_dir / "orchestration_config.json"
        if config_file.exists():
            with open(config_file, 'r') as f:
                return json.load(f)
        
        # Default configuration
        default_config = {
            "max_concurrent_workflows": 10,
            "max_concurrent_steps": 5,
            "default_timeout": 1800,
            "retry_delays": [30, 120, 300],  # seconds
            "schema_validation": True,
            "auto_dependency_resolution": True,
            "failure_escalation": True,
            "performance_monitoring": True,
            "business_intelligence": True
        }
        
        with open(config_file, 'w') as f:
            json.dump(default_config, f, indent=2)
        
        return default_config
    
    def _initialize_subagent_registry(self) -> Dict[str, str]:
        """Initialize registry of available subagents"""
        return {
            # Core subagents
            "devin-software-engineer": "devin",
            "v0-ui-generator": "v0",
            "corki-coverage-guardian": "corki",
            "veigar-security-reviewer": "veigar",
            "general-purpose": "general",
            
            # Business subagents
            "content-creator": "python3 /home/ubuntu/.claude/hooks/business_subagent_template.py content-creator",
            "social-media": "python3 /home/ubuntu/.claude/hooks/business_subagent_template.py social-media",
            "email-campaign": "python3 /home/ubuntu/.claude/hooks/marketing_subagents.py email-campaign",
            "seo-optimizer": "python3 /home/ubuntu/.claude/hooks/marketing_subagents.py seo-optimizer",
            "analytics-tracker": "python3 /home/ubuntu/.claude/hooks/marketing_subagents.py analytics-tracker",
            "lead-qualifier": "python3 /home/ubuntu/.claude/hooks/sales_customer_success_subagents.py lead-qualifier",
            "proposal-generator": "python3 /home/ubuntu/.claude/hooks/sales_customer_success_subagents.py proposal-generator",
            "customer-success": "python3 /home/ubuntu/.claude/hooks/sales_customer_success_subagents.py customer-success"
        }
    
    def _load_schema_patterns(self) -> Dict[str, Any]:
        """Load schema-stacked workflow patterns"""
        patterns_file = self.workflows_dir / "schema_patterns.json"
        if patterns_file.exists():
            with open(patterns_file, 'r') as f:
                return json.load(f)
        
        # Default schema patterns for schema-stacked workflows
        default_patterns = {
            "data_flow_schemas": {
                "lead_to_customer": {
                    "input_schema": {
                        "lead_data": {"type": "object", "required": ["contact_info", "company", "interest_level"]},
                        "qualification_criteria": {"type": "object", "required": ["budget", "timeline", "decision_maker"]}
                    },
                    "intermediate_schemas": {
                        "qualified_lead": {"type": "object", "required": ["score", "stage", "next_action"]},
                        "proposal": {"type": "object", "required": ["solution", "pricing", "timeline"]},
                        "signed_contract": {"type": "object", "required": ["value", "start_date", "deliverables"]}
                    },
                    "output_schema": {
                        "customer": {"type": "object", "required": ["account_id", "success_plan", "health_score"]}
                    }
                },
                "product_launch": {
                    "input_schema": {
                        "product_info": {"type": "object", "required": ["name", "features", "target_audience"]},
                        "launch_requirements": {"type": "object", "required": ["timeline", "budget", "channels"]}
                    },
                    "intermediate_schemas": {
                        "content_assets": {"type": "object", "required": ["blog_posts", "social_content", "email_campaigns"]},
                        "campaign_setup": {"type": "object", "required": ["tracking", "automation", "analytics"]},
                        "launch_execution": {"type": "object", "required": ["coordinated_publish", "monitoring", "response_handling"]}
                    },
                    "output_schema": {
                        "launch_results": {"type": "object", "required": ["metrics", "feedback", "follow_up_actions"]}
                    }
                }
            },
            "schema_validation_rules": {
                "required_fields": ["timestamp", "workflow_id", "step_id", "status"],
                "schema_compliance_threshold": 0.95,
                "auto_schema_evolution": True
            },
            "workflow_templates": {
                "end_to_end_customer_acquisition": [
                    "content-creator", "seo-optimizer", "social-media", 
                    "analytics-tracker", "lead-qualifier", "proposal-generator", "customer-success"
                ],
                "product_development_cycle": [
                    "devin-software-engineer", "v0-ui-generator", "corki-coverage-guardian", 
                    "veigar-security-reviewer", "content-creator", "social-media"
                ]
            }
        }
        
        with open(patterns_file, 'w') as f:
            json.dump(default_patterns, f, indent=2)
        
        return default_patterns
    
    def create_workflow(self, workflow_definition: Dict[str, Any]) -> SchemaStackedWorkflow:
        """Create a new schema-stacked workflow from definition"""
        
        # Validate workflow definition against schema
        if not self._validate_workflow_schema(workflow_definition):
            raise ValueError("Workflow definition does not meet schema requirements")
        
        # Create workflow steps
        steps = []
        for step_def in workflow_definition.get("steps", []):
            step = WorkflowStep(
                step_id=step_def["step_id"],
                agent_type=step_def["agent_type"],
                task_description=step_def["task_description"],
                dependencies=step_def.get("dependencies", []),
                timeout_seconds=step_def.get("timeout_seconds", self.config["default_timeout"]),
                retry_count=step_def.get("retry_count", 3),
                conditions=step_def.get("conditions", {}),
                output_mapping=step_def.get("output_mapping", {})
            )
            steps.append(step)
        
        # Create business context
        context_data = workflow_definition.get("business_context", {})
        business_context = BusinessContext(
            company_name=context_data.get("company_name", "Schemantics"),
            industry=context_data.get("industry", "Software Development Tools"),
            target_audience=context_data.get("target_audience", "Software Developers"),
            brand_voice=context_data.get("brand_voice", "Technical, Helpful, Innovative"),
            primary_languages=context_data.get("primary_languages", ["Julia", "Rust", "TypeScript", "Elixir"]),
            key_metrics=context_data.get("key_metrics", {
                "user_acquisition": "monthly_signups",
                "engagement": "daily_active_users",
                "retention": "monthly_retention_rate",
                "revenue": "monthly_recurring_revenue"
            })
        )
        
        # Create workflow
        workflow = SchemaStackedWorkflow(
            workflow_id=workflow_definition["workflow_id"],
            name=workflow_definition["name"],
            description=workflow_definition["description"],
            domain=BusinessDomain(workflow_definition.get("domain", "operations")),
            priority=TaskPriority(workflow_definition.get("priority", "medium")),
            steps=steps,
            success_criteria=workflow_definition.get("success_criteria", {}),
            failure_conditions=workflow_definition.get("failure_conditions", {}),
            schema_requirements=workflow_definition.get("schema_requirements", {}),
            business_context=business_context,
            estimated_duration=workflow_definition.get("estimated_duration", len(steps) * 30)
        )
        
        return workflow
    
    def _validate_workflow_schema(self, workflow_def: Dict[str, Any]) -> bool:
        """Validate workflow definition against schema requirements"""
        required_fields = ["workflow_id", "name", "description", "steps"]
        
        for field in required_fields:
            if field not in workflow_def:
                return False
        
        # Validate steps
        for step in workflow_def.get("steps", []):
            required_step_fields = ["step_id", "agent_type", "task_description"]
            for field in required_step_fields:
                if field not in step:
                    return False
            
            # Validate agent type exists
            if step["agent_type"] not in self.subagent_registry:
                return False
        
        return True
    
    async def execute_workflow(self, workflow: SchemaStackedWorkflow) -> Dict[str, Any]:
        """Execute a complete schema-stacked workflow"""
        
        workflow.status = WorkflowStatus.RUNNING
        workflow.started_at = datetime.now().isoformat()
        workflow.execution_log.append({
            "timestamp": workflow.started_at,
            "event": "workflow_started",
            "workflow_id": workflow.workflow_id
        })
        
        self.active_workflows[workflow.workflow_id] = workflow
        
        try:
            # Execute workflow steps with dependency resolution
            execution_results = await self._execute_workflow_steps(workflow)
            
            # Validate final results against success criteria
            if self._validate_success_criteria(workflow, execution_results):
                workflow.status = WorkflowStatus.COMPLETED
                workflow.outputs = execution_results
            else:
                workflow.status = WorkflowStatus.FAILED
                workflow.execution_log.append({
                    "timestamp": datetime.now().isoformat(),
                    "event": "workflow_failed",
                    "reason": "success_criteria_not_met",
                    "results": execution_results
                })
            
        except Exception as e:
            workflow.status = WorkflowStatus.FAILED
            workflow.execution_log.append({
                "timestamp": datetime.now().isoformat(),
                "event": "workflow_error",
                "error": str(e)
            })
            
        finally:
            workflow.completed_at = datetime.now().isoformat()
            self._save_workflow_execution(workflow)
            
            if workflow.workflow_id in self.active_workflows:
                del self.active_workflows[workflow.workflow_id]
        
        return {
            "workflow_id": workflow.workflow_id,
            "status": workflow.status.value,
            "execution_time": self._calculate_execution_time(workflow),
            "outputs": workflow.outputs,
            "success": workflow.status == WorkflowStatus.COMPLETED
        }
    
    async def _execute_workflow_steps(self, workflow: SchemaStackedWorkflow) -> Dict[str, Any]:
        """Execute workflow steps with proper dependency resolution"""
        
        completed_steps = set()
        step_outputs = {}
        pending_steps = {step.step_id: step for step in workflow.steps}
        
        max_iterations = len(workflow.steps) * 2  # Prevent infinite loops
        iteration = 0
        
        while pending_steps and iteration < max_iterations:
            iteration += 1
            
            # Find steps ready to execute (dependencies satisfied)
            ready_steps = []
            for step_id, step in pending_steps.items():
                if all(dep in completed_steps for dep in step.dependencies):
                    ready_steps.append(step)
            
            if not ready_steps:
                # Check for circular dependencies
                remaining_deps = set()
                for step in pending_steps.values():
                    remaining_deps.update(step.dependencies)
                
                if remaining_deps.issubset(set(pending_steps.keys())):
                    raise Exception("Circular dependency detected in workflow steps")
                else:
                    raise Exception("Unresolvable dependencies in workflow steps")
            
            # Execute ready steps concurrently
            tasks = []
            for step in ready_steps:
                task = self._execute_single_step(workflow, step, step_outputs)
                tasks.append(task)
            
            # Wait for step completions
            step_results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Process results
            for i, result in enumerate(step_results):
                step = ready_steps[i]
                if isinstance(result, Exception):
                    raise Exception(f"Step {step.step_id} failed: {str(result)}")
                
                step_outputs[step.step_id] = result
                completed_steps.add(step.step_id)
                del pending_steps[step.step_id]
                
                workflow.execution_log.append({
                    "timestamp": datetime.now().isoformat(),
                    "event": "step_completed",
                    "step_id": step.step_id,
                    "agent_type": step.agent_type,
                    "output_summary": str(result)[:200] + "..." if len(str(result)) > 200 else str(result)
                })
        
        return step_outputs
    
    async def _execute_single_step(self, workflow: SchemaStackedWorkflow, step: WorkflowStep, previous_outputs: Dict[str, Any]) -> Any:
        """Execute a single workflow step"""
        
        workflow.current_step = step.step_id
        
        # Prepare task input with schema stacking
        task_input = self._prepare_schema_stacked_input(workflow, step, previous_outputs)
        
        # Get agent command
        agent_command = self.subagent_registry.get(step.agent_type)
        if not agent_command:
            raise Exception(f"Unknown agent type: {step.agent_type}")
        
        # Execute with retries
        for attempt in range(step.retry_count):
            try:
                result = await self._execute_agent_with_timeout(
                    agent_command, task_input, step.timeout_seconds
                )
                
                # Validate result against schema
                if self._validate_step_output_schema(workflow, step, result):
                    return result
                else:
                    raise Exception("Step output does not meet schema requirements")
                    
            except Exception as e:
                if attempt == step.retry_count - 1:
                    raise e
                
                # Wait before retry
                if attempt < len(self.config["retry_delays"]):
                    await asyncio.sleep(self.config["retry_delays"][attempt])
                else:
                    await asyncio.sleep(self.config["retry_delays"][-1])
    
    def _prepare_schema_stacked_input(self, workflow: SchemaStackedWorkflow, step: WorkflowStep, previous_outputs: Dict[str, Any]) -> Dict[str, Any]:
        """Prepare schema-aligned input for step execution"""
        
        # Base task structure
        task_input = {
            "task_id": f"{workflow.workflow_id}_{step.step_id}",
            "description": step.task_description,
            "domain": workflow.domain.value,
            "priority": workflow.priority.value,
            "context": {
                "workflow_id": workflow.workflow_id,
                "workflow_name": workflow.name,
                "business_context": asdict(workflow.business_context),
                "step_position": f"{list(workflow.steps).index(step) + 1}/{len(workflow.steps)}"
            },
            "requirements": {},
            "success_criteria": workflow.success_criteria.get(step.step_id, {})
        }
        
        # Add dependency outputs with schema mapping
        for dep_id in step.dependencies:
            if dep_id in previous_outputs:
                mapped_key = step.output_mapping.get(dep_id, f"{dep_id}_output")
                task_input["requirements"][mapped_key] = previous_outputs[dep_id]
        
        # Add schema requirements
        if step.step_id in workflow.schema_requirements:
            task_input["schema_requirements"] = workflow.schema_requirements[step.step_id]
        
        return task_input
    
    async def _execute_agent_with_timeout(self, agent_command: str, task_input: Dict[str, Any], timeout_seconds: int) -> Any:
        """Execute agent with timeout and proper error handling"""
        
        # Prepare command
        if agent_command.startswith("python3"):
            # For Python-based subagents, pass input as JSON
            cmd_parts = agent_command.split()
            cmd_parts.append(json.dumps(task_input))
            process_cmd = cmd_parts
        else:
            # For Claude Code subagents, use task tool
            process_cmd = ["claude", "task", agent_command, json.dumps(task_input)]
        
        # Execute with timeout
        try:
            process = await asyncio.create_subprocess_exec(
                *process_cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await asyncio.wait_for(
                process.communicate(),
                timeout=timeout_seconds
            )
            
            if process.returncode != 0:
                raise Exception(f"Agent execution failed: {stderr.decode()}")
            
            # Parse output
            output_text = stdout.decode()
            try:
                return json.loads(output_text)
            except json.JSONDecodeError:
                return {"raw_output": output_text}
                
        except asyncio.TimeoutError:
            raise Exception(f"Agent execution timed out after {timeout_seconds} seconds")
    
    def _validate_step_output_schema(self, workflow: SchemaStackedWorkflow, step: WorkflowStep, output: Any) -> bool:
        """Validate step output against schema requirements"""
        if not self.config["schema_validation"]:
            return True
        
        # Basic schema validation (can be enhanced with jsonschema library)
        if not isinstance(output, dict):
            return False
        
        # Check for required fields
        schema_reqs = workflow.schema_requirements.get(step.step_id, {})
        required_fields = schema_reqs.get("required_fields", [])
        
        for field in required_fields:
            if field not in output:
                return False
        
        return True
    
    def _validate_success_criteria(self, workflow: SchemaStackedWorkflow, execution_results: Dict[str, Any]) -> bool:
        """Validate workflow results against success criteria"""
        
        for criterion, requirement in workflow.success_criteria.items():
            if criterion == "min_successful_steps":
                successful_steps = len([r for r in execution_results.values() if r is not None])
                if successful_steps < requirement:
                    return False
            
            elif criterion == "required_outputs":
                for required_output in requirement:
                    if required_output not in execution_results:
                        return False
            
            elif criterion == "schema_compliance":
                # Check overall schema compliance
                compliance_score = self._calculate_schema_compliance(execution_results)
                if compliance_score < requirement:
                    return False
        
        return True
    
    def _calculate_schema_compliance(self, results: Dict[str, Any]) -> float:
        """Calculate overall schema compliance score"""
        if not results:
            return 0.0
        
        compliant_outputs = 0
        for result in results.values():
            if isinstance(result, dict) and "status" in result:
                compliant_outputs += 1
        
        return compliant_outputs / len(results)
    
    def _calculate_execution_time(self, workflow: SchemaStackedWorkflow) -> int:
        """Calculate workflow execution time in seconds"""
        if not workflow.started_at or not workflow.completed_at:
            return 0
        
        start = datetime.fromisoformat(workflow.started_at)
        end = datetime.fromisoformat(workflow.completed_at)
        return int((end - start).total_seconds())
    
    def _save_workflow_execution(self, workflow: SchemaStackedWorkflow):
        """Save workflow execution results"""
        execution_file = self.execution_dir / f"{workflow.workflow_id}_{int(datetime.now().timestamp())}.json"
        
        with open(execution_file, 'w') as f:
            json.dump({
                "workflow": asdict(workflow),
                "execution_summary": {
                    "total_steps": len(workflow.steps),
                    "execution_time_seconds": self._calculate_execution_time(workflow),
                    "status": workflow.status.value,
                    "outputs_count": len(workflow.outputs) if workflow.outputs else 0
                }
            }, f, indent=2)
    
    def create_predefined_workflows(self) -> Dict[str, SchemaStackedWorkflow]:
        """Create common business workflow templates"""
        
        workflows = {}
        
        # Customer Acquisition Workflow
        workflows["customer_acquisition"] = self.create_workflow({
            "workflow_id": "customer_acquisition_flow",
            "name": "End-to-End Customer Acquisition",
            "description": "Complete customer acquisition from content creation to customer success",
            "domain": "sales",
            "priority": "high",
            "steps": [
                {
                    "step_id": "content_creation",
                    "agent_type": "content-creator",
                    "task_description": "Create lead magnet content and educational materials",
                    "dependencies": []
                },
                {
                    "step_id": "seo_optimization",
                    "agent_type": "seo-optimizer",
                    "task_description": "Optimize content for search engines and lead generation",
                    "dependencies": ["content_creation"],
                    "output_mapping": {"content_creation": "content_to_optimize"}
                },
                {
                    "step_id": "social_promotion",
                    "agent_type": "social-media",
                    "task_description": "Create social media promotion campaign",
                    "dependencies": ["content_creation"],
                    "output_mapping": {"content_creation": "content_to_promote"}
                },
                {
                    "step_id": "email_campaign",
                    "agent_type": "email-campaign",
                    "task_description": "Set up email nurture sequence",
                    "dependencies": ["content_creation", "seo_optimization"]
                },
                {
                    "step_id": "analytics_setup",
                    "agent_type": "analytics-tracker",
                    "task_description": "Set up tracking and analytics for lead generation",
                    "dependencies": ["seo_optimization", "social_promotion", "email_campaign"]
                },
                {
                    "step_id": "lead_qualification",
                    "agent_type": "lead-qualifier",
                    "task_description": "Set up lead qualification and scoring system",
                    "dependencies": ["analytics_setup"]
                },
                {
                    "step_id": "proposal_generation",
                    "agent_type": "proposal-generator",
                    "task_description": "Create proposal templates and automation",
                    "dependencies": ["lead_qualification"]
                },
                {
                    "step_id": "customer_onboarding",
                    "agent_type": "customer-success",
                    "task_description": "Set up customer onboarding and success processes",
                    "dependencies": ["proposal_generation"]
                }
            ],
            "success_criteria": {
                "min_successful_steps": 7,
                "required_outputs": ["content_creation", "lead_qualification", "customer_onboarding"],
                "schema_compliance": 0.9
            },
            "schema_requirements": {
                "content_creation": {"required_fields": ["content", "format", "target_audience"]},
                "lead_qualification": {"required_fields": ["scoring_criteria", "qualification_process"]},
                "customer_onboarding": {"required_fields": ["onboarding_plan", "success_metrics"]}
            },
            "estimated_duration": 240  # 4 hours
        })
        
        # Product Launch Workflow
        workflows["product_launch"] = self.create_workflow({
            "workflow_id": "product_launch_campaign",
            "name": "Complete Product Launch Campaign",
            "description": "Comprehensive product launch with coordinated marketing",
            "domain": "marketing",
            "priority": "critical",
            "steps": [
                {
                    "step_id": "launch_content",
                    "agent_type": "content-creator",
                    "task_description": "Create product launch announcement and documentation",
                    "dependencies": []
                },
                {
                    "step_id": "launch_seo",
                    "agent_type": "seo-optimizer",
                    "task_description": "Optimize launch content for maximum visibility",
                    "dependencies": ["launch_content"]
                },
                {
                    "step_id": "social_campaign",
                    "agent_type": "social-media",
                    "task_description": "Create comprehensive social media launch campaign",
                    "dependencies": ["launch_content"]
                },
                {
                    "step_id": "email_announcement",
                    "agent_type": "email-campaign",
                    "task_description": "Create email announcement campaign",
                    "dependencies": ["launch_content"]
                },
                {
                    "step_id": "launch_analytics",
                    "agent_type": "analytics-tracker",
                    "task_description": "Set up comprehensive launch tracking",
                    "dependencies": ["launch_seo", "social_campaign", "email_announcement"]
                }
            ],
            "success_criteria": {
                "min_successful_steps": 4,
                "required_outputs": ["launch_content", "social_campaign", "launch_analytics"],
                "schema_compliance": 0.95
            },
            "estimated_duration": 180  # 3 hours
        })
        
        return workflows

def main():
    """Main entry point for workflow orchestration"""
    if len(sys.argv) < 2:
        print("Usage: workflow_orchestration_engine.py <command> [args...]", file=sys.stderr)
        print("Commands:", file=sys.stderr)
        print("  create_workflow <workflow_definition.json>", file=sys.stderr)
        print("  execute_workflow <workflow_id>", file=sys.stderr)
        print("  list_workflows", file=sys.stderr)
        print("  status <workflow_id>", file=sys.stderr)
        print("  create_predefined", file=sys.stderr)
        sys.exit(1)
    
    command = sys.argv[1]
    engine = WorkflowOrchestrationEngine()
    
    if command == "create_workflow":
        if len(sys.argv) < 3:
            print("Error: workflow definition file required", file=sys.stderr)
            sys.exit(1)
        
        with open(sys.argv[2], 'r') as f:
            workflow_def = json.load(f)
        
        workflow = engine.create_workflow(workflow_def)
        print(json.dumps({
            "success": True,
            "workflow_id": workflow.workflow_id,
            "message": "Workflow created successfully"
        }, indent=2))
    
    elif command == "execute_workflow":
        if len(sys.argv) < 3:
            print("Error: workflow_id required", file=sys.stderr)
            sys.exit(1)
        
        # This would need workflow loading logic
        print("Error: Workflow execution requires workflow loading implementation", file=sys.stderr)
        sys.exit(1)
    
    elif command == "create_predefined":
        workflows = engine.create_predefined_workflows()
        
        # Save workflows to files
        for name, workflow in workflows.items():
            workflow_file = engine.workflows_dir / f"{name}.json"
            with open(workflow_file, 'w') as f:
                json.dump(asdict(workflow), f, indent=2)
        
        print(json.dumps({
            "success": True,
            "workflows_created": list(workflows.keys()),
            "message": "Predefined workflows created successfully"
        }, indent=2))
    
    else:
        print(f"Error: Unknown command '{command}'", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()