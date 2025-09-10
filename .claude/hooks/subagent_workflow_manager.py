#!/usr/bin/env python3
"""
Subagent Workflow Manager
Intelligent subagent selection and workflow orchestration for autonomous business operations
"""

import json
import sys
import os
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum

class SubagentType(Enum):
    """Available subagent types"""
    DEVIN = "devin-software-engineer"
    V0 = "v0-ui-generator"
    CORKI = "corki-coverage-guardian"
    VEIGAR = "veigar-security-reviewer"
    GENERAL = "general-purpose"
    
    # Business subagents (to be implemented)
    CONTENT_CREATOR = "content-creator-agent"
    SOCIAL_MEDIA = "social-media-agent"
    EMAIL_CAMPAIGN = "email-campaign-agent"
    SEO_OPTIMIZER = "seo-optimizer-agent"
    ANALYTICS_TRACKER = "analytics-tracker-agent"
    LEAD_QUALIFIER = "lead-qualifier-agent"
    PROPOSAL_GENERATOR = "proposal-generator-agent"
    CUSTOMER_SUCCESS = "customer-success-agent"

class TaskCategory(Enum):
    """Task categories for intelligent routing"""
    DEVELOPMENT = "development"
    UI_DEVELOPMENT = "ui_development"
    TESTING = "testing"
    SECURITY = "security"
    RESEARCH = "research"
    CONTENT = "content"
    MARKETING = "marketing"
    COMMUNICATION = "communication"
    SALES = "sales"
    CUSTOMER_SUCCESS = "customer_success"
    ANALYTICS = "analytics"

@dataclass
class WorkflowStep:
    """Represents a step in a business workflow"""
    agent: SubagentType
    task_template: str
    depends_on: List[str]
    success_criteria: Dict[str, Any]
    timeout_minutes: int = 30

@dataclass
class BusinessWorkflow:
    """Represents a complete business workflow"""
    name: str
    description: str
    trigger_patterns: List[str]
    steps: List[WorkflowStep]
    success_metrics: Dict[str, Any]

class SubagentWorkflowManager:
    """Manages subagent workflows and intelligent routing"""
    
    def __init__(self):
        self.base_dir = Path.home() / ".claude" / "hooks"
        self.subagents_dir = self.base_dir / "subagents"
        self.workflows_dir = self.base_dir / "workflows"
        self.business_dir = self.base_dir / "business"
        
        # Create directories
        for dir_path in [self.subagents_dir, self.workflows_dir, self.business_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)
        
        # Load existing data
        self.performance_data = self._load_json(self.subagents_dir / "performance.json")
        self.task_patterns = self._load_json(self.subagents_dir / "task_patterns.json")
        self.workflow_sequences = self._load_json(self.workflows_dir / "agent_sequences.json")
        
        # Initialize business workflows
        self.business_workflows = self._initialize_business_workflows()
    
    def _load_json(self, file_path: Path) -> Dict:
        """Load JSON file or return empty dict"""
        if file_path.exists():
            try:
                with open(file_path, 'r') as f:
                    return json.load(f)
            except:
                pass
        return {}
    
    def _save_json(self, file_path: Path, data: Dict):
        """Save data to JSON file"""
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)
    
    def categorize_task(self, task_description: str) -> TaskCategory:
        """Categorize a task based on its description"""
        task_lower = task_description.lower()
        
        # Development tasks
        if any(keyword in task_lower for keyword in [
            "implement", "code", "function", "class", "feature", "bug", 
            "refactor", "develop", "programming", "algorithm"
        ]):
            return TaskCategory.DEVELOPMENT
        
        # UI development tasks
        if any(keyword in task_lower for keyword in [
            "ui", "component", "interface", "design", "frontend", "react", 
            "web", "layout", "styling", "responsive"
        ]):
            return TaskCategory.UI_DEVELOPMENT
        
        # Testing tasks
        if any(keyword in task_lower for keyword in [
            "test", "coverage", "unit test", "integration test", "testing", 
            "quality assurance", "qa"
        ]):
            return TaskCategory.TESTING
        
        # Security tasks
        if any(keyword in task_lower for keyword in [
            "security", "audit", "vulnerability", "review", "secure", 
            "authentication", "authorization", "encryption"
        ]):
            return TaskCategory.SECURITY
        
        # Content creation tasks
        if any(keyword in task_lower for keyword in [
            "content", "blog", "article", "documentation", "write", "copy", 
            "documentation", "guide", "tutorial"
        ]):
            return TaskCategory.CONTENT
        
        # Marketing tasks
        if any(keyword in task_lower for keyword in [
            "marketing", "campaign", "social", "promote", "launch", 
            "announcement", "brand", "awareness"
        ]):
            return TaskCategory.MARKETING
        
        # Communication tasks
        if any(keyword in task_lower for keyword in [
            "email", "newsletter", "customer", "outreach", "communication", 
            "message", "notification"
        ]):
            return TaskCategory.COMMUNICATION
        
        # Sales tasks
        if any(keyword in task_lower for keyword in [
            "sales", "proposal", "quote", "lead", "prospect", "deal", 
            "conversion", "revenue"
        ]):
            return TaskCategory.SALES
        
        # Customer success tasks
        if any(keyword in task_lower for keyword in [
            "customer success", "onboarding", "support", "help", "training", 
            "adoption", "retention"
        ]):
            return TaskCategory.CUSTOMER_SUCCESS
        
        # Analytics tasks
        if any(keyword in task_lower for keyword in [
            "analytics", "metrics", "tracking", "measurement", "performance", 
            "data", "insights", "reporting"
        ]):
            return TaskCategory.ANALYTICS
        
        # Research tasks (default for investigation-type tasks)
        if any(keyword in task_lower for keyword in [
            "research", "analyze", "investigate", "understand", "explore", 
            "study", "examine"
        ]):
            return TaskCategory.RESEARCH
        
        return TaskCategory.RESEARCH  # Default fallback
    
    def suggest_best_agent(self, task_description: str) -> Tuple[SubagentType, float]:
        """Suggest the best subagent for a task based on learned patterns"""
        task_category = self.categorize_task(task_description)
        
        # Base agent suggestions by category
        category_agents = {
            TaskCategory.DEVELOPMENT: [SubagentType.DEVIN],
            TaskCategory.UI_DEVELOPMENT: [SubagentType.V0, SubagentType.DEVIN],
            TaskCategory.TESTING: [SubagentType.CORKI],
            TaskCategory.SECURITY: [SubagentType.VEIGAR],
            TaskCategory.RESEARCH: [SubagentType.GENERAL],
            TaskCategory.CONTENT: [SubagentType.CONTENT_CREATOR, SubagentType.GENERAL],
            TaskCategory.MARKETING: [SubagentType.SOCIAL_MEDIA, SubagentType.CONTENT_CREATOR],
            TaskCategory.COMMUNICATION: [SubagentType.EMAIL_CAMPAIGN, SubagentType.GENERAL],
            TaskCategory.SALES: [SubagentType.PROPOSAL_GENERATOR, SubagentType.LEAD_QUALIFIER],
            TaskCategory.CUSTOMER_SUCCESS: [SubagentType.CUSTOMER_SUCCESS, SubagentType.GENERAL],
            TaskCategory.ANALYTICS: [SubagentType.ANALYTICS_TRACKER, SubagentType.GENERAL]
        }
        
        candidate_agents = category_agents.get(task_category, [SubagentType.GENERAL])
        
        # Calculate confidence scores based on historical performance
        best_agent = candidate_agents[0]
        best_score = 0.5  # Base confidence
        
        for agent in candidate_agents:
            # Check historical performance
            pattern_key = f"{task_category.value}_{agent.value}"
            success_count = self.task_patterns.get(pattern_key, 0)
            
            success_key = f"{agent.value}_success"
            failure_key = f"{agent.value}_failure"
            
            total_success = self.performance_data.get(success_key, 0)
            total_failure = self.performance_data.get(failure_key, 0)
            total_attempts = total_success + total_failure
            
            if total_attempts > 0:
                success_rate = total_success / total_attempts
                # Weight by pattern-specific success and overall success rate
                confidence = (success_rate * 0.7) + (min(success_count / 10, 1.0) * 0.3)
                
                if confidence > best_score:
                    best_agent = agent
                    best_score = confidence
        
        return best_agent, best_score
    
    def suggest_workflow_sequence(self, initial_agent: SubagentType, task_description: str) -> List[SubagentType]:
        """Suggest a sequence of subagents based on learned workflow patterns"""
        sequence = [initial_agent]
        current_agent = initial_agent
        
        # Look for common follow-up patterns
        for _ in range(3):  # Max 4 agents in sequence
            best_next_agent = None
            best_score = 0
            
            for next_agent in SubagentType:
                workflow_key = f"{current_agent.value}->{next_agent.value}"
                frequency = self.workflow_sequences.get(workflow_key, 0)
                
                # Don't repeat agents in the sequence
                if next_agent not in sequence and frequency > best_score:
                    best_next_agent = next_agent
                    best_score = frequency
            
            if best_next_agent and best_score >= 2:  # Only suggest if seen 2+ times
                sequence.append(best_next_agent)
                current_agent = best_next_agent
            else:
                break
        
        return sequence
    
    def detect_business_workflow(self, task_description: str) -> Optional[BusinessWorkflow]:
        """Detect if task matches a predefined business workflow"""
        task_lower = task_description.lower()
        
        for workflow in self.business_workflows:
            for pattern in workflow.trigger_patterns:
                if pattern.lower() in task_lower:
                    return workflow
        
        return None
    
    def _initialize_business_workflows(self) -> List[BusinessWorkflow]:
        """Initialize predefined business workflows"""
        workflows = []
        
        # Software Development Lifecycle
        workflows.append(BusinessWorkflow(
            name="full_development_cycle",
            description="Complete software development from code to security review",
            trigger_patterns=["implement new feature", "build feature", "develop feature", "create new functionality"],
            steps=[
                WorkflowStep(SubagentType.DEVIN, "Implement the feature: {task}", [], {"code_generated": True}),
                WorkflowStep(SubagentType.CORKI, "Generate comprehensive tests for the implemented feature", ["devin"], {"test_coverage": ">80%"}),
                WorkflowStep(SubagentType.VEIGAR, "Security review of the implemented feature", ["corki"], {"security_issues": 0})
            ],
            success_metrics={"code_quality": "high", "test_coverage": ">80%", "security_score": "pass"}
        ))
        
        # UI Development Workflow
        workflows.append(BusinessWorkflow(
            name="ui_development_cycle",
            description="UI component development and integration",
            trigger_patterns=["create UI component", "build interface", "design component", "frontend component"],
            steps=[
                WorkflowStep(SubagentType.V0, "Create the UI component: {task}", [], {"component_created": True}),
                WorkflowStep(SubagentType.DEVIN, "Integrate UI component with backend systems", ["v0"], {"integration_complete": True}),
                WorkflowStep(SubagentType.CORKI, "Generate tests for UI component", ["devin"], {"ui_tests_created": True})
            ],
            success_metrics={"ui_quality": "responsive", "integration": "complete", "test_coverage": ">70%"}
        ))
        
        # Product Launch Campaign
        workflows.append(BusinessWorkflow(
            name="product_launch_campaign",
            description="Complete product launch from content creation to analytics",
            trigger_patterns=["launch product", "product announcement", "feature launch", "release announcement"],
            steps=[
                WorkflowStep(SubagentType.CONTENT_CREATOR, "Create launch announcement content: {task}", [], {"content_created": True}),
                WorkflowStep(SubagentType.SOCIAL_MEDIA, "Create social media campaign for launch", ["content"], {"social_campaign": True}),
                WorkflowStep(SubagentType.EMAIL_CAMPAIGN, "Create email announcement for users", ["content"], {"email_campaign": True}),
                WorkflowStep(SubagentType.ANALYTICS_TRACKER, "Set up tracking for launch metrics", ["social", "email"], {"tracking_setup": True})
            ],
            success_metrics={"content_quality": "high", "reach": ">1000", "engagement": ">5%"}
        ))
        
        # Content Marketing Workflow
        workflows.append(BusinessWorkflow(
            name="content_marketing_workflow",
            description="Content creation and distribution workflow",
            trigger_patterns=["create blog post", "write article", "content marketing", "create content"],
            steps=[
                WorkflowStep(SubagentType.CONTENT_CREATOR, "Create content: {task}", [], {"content_drafted": True}),
                WorkflowStep(SubagentType.SEO_OPTIMIZER, "Optimize content for SEO", ["content"], {"seo_optimized": True}),
                WorkflowStep(SubagentType.SOCIAL_MEDIA, "Create social media promotion", ["seo"], {"social_promo": True}),
                WorkflowStep(SubagentType.ANALYTICS_TRACKER, "Set up content performance tracking", ["social"], {"tracking_active": True})
            ],
            success_metrics={"seo_score": ">80", "social_shares": ">10", "organic_traffic": "increased"}
        ))
        
        # Customer Acquisition Workflow
        workflows.append(BusinessWorkflow(
            name="customer_acquisition_workflow", 
            description="Complete customer acquisition from lead generation to onboarding",
            trigger_patterns=["acquire customers", "lead generation", "customer acquisition", "find new customers"],
            steps=[
                WorkflowStep(SubagentType.CONTENT_CREATOR, "Create lead magnet content", [], {"lead_magnet": True}),
                WorkflowStep(SubagentType.SEO_OPTIMIZER, "Optimize for lead generation keywords", ["content"], {"seo_leads": True}),
                WorkflowStep(SubagentType.LEAD_QUALIFIER, "Set up lead qualification process", ["seo"], {"qualification_active": True}),
                WorkflowStep(SubagentType.EMAIL_CAMPAIGN, "Create nurture email sequence", ["lead_qualifier"], {"nurture_sequence": True}),
                WorkflowStep(SubagentType.CUSTOMER_SUCCESS, "Set up onboarding workflow", ["email"], {"onboarding_ready": True})
            ],
            success_metrics={"leads_generated": ">50", "qualification_rate": ">20%", "conversion_rate": ">5%"}
        ))
        
        return workflows
    
    def generate_workflow_recommendation(self, task_description: str) -> Dict[str, Any]:
        """Generate comprehensive workflow recommendation"""
        # 1. Suggest best initial agent
        best_agent, confidence = self.suggest_best_agent(task_description)
        
        # 2. Check for predefined business workflows
        business_workflow = self.detect_business_workflow(task_description)
        
        # 3. Generate sequence suggestion
        sequence = self.suggest_workflow_sequence(best_agent, task_description)
        
        # 4. Calculate workflow metrics
        task_category = self.categorize_task(task_description)
        
        recommendation = {
            "primary_recommendation": {
                "agent": best_agent.value,
                "confidence": confidence,
                "reasoning": f"Best agent for {task_category.value} tasks based on historical performance"
            },
            "workflow_sequence": [agent.value for agent in sequence],
            "business_workflow": {
                "detected": business_workflow is not None,
                "workflow_name": business_workflow.name if business_workflow else None,
                "description": business_workflow.description if business_workflow else None,
                "steps": len(business_workflow.steps) if business_workflow else 0
            },
            "task_analysis": {
                "category": task_category.value,
                "complexity": "high" if len(sequence) > 2 else "medium" if len(sequence) > 1 else "low",
                "estimated_duration": len(sequence) * 30  # 30 min per agent
            },
            "success_factors": self._generate_success_factors(task_category, best_agent),
            "timestamp": datetime.now().isoformat()
        }
        
        return recommendation
    
    def _generate_success_factors(self, category: TaskCategory, agent: SubagentType) -> List[str]:
        """Generate success factors for the task"""
        base_factors = [
            "Clear and specific task description",
            "Adequate context provided",
            "Success criteria defined"
        ]
        
        category_factors = {
            TaskCategory.DEVELOPMENT: [
                "Requirements well defined",
                "Technical specifications clear",
                "Testing approach planned"
            ],
            TaskCategory.UI_DEVELOPMENT: [
                "Design mockups available",
                "User experience considered",
                "Responsive design requirements specified"
            ],
            TaskCategory.CONTENT: [
                "Target audience defined",
                "Content goals specified",
                "Brand voice guidelines available"
            ],
            TaskCategory.MARKETING: [
                "Campaign objectives clear",
                "Target metrics defined",
                "Budget constraints specified"
            ]
        }
        
        return base_factors + category_factors.get(category, [])

def main():
    """Main entry point for workflow recommendations"""
    if len(sys.argv) > 1:
        task_description = sys.argv[1]
    else:
        # Read from stdin
        try:
            input_data = json.load(sys.stdin)
            task_description = input_data.get('task', input_data.get('description', ''))
        except:
            print("Error: No task description provided", file=sys.stderr)
            sys.exit(1)
    
    manager = SubagentWorkflowManager()
    recommendation = manager.generate_workflow_recommendation(task_description)
    
    print(json.dumps(recommendation, indent=2))

if __name__ == "__main__":
    main()