#!/usr/bin/env python3
"""
Business Subagent Template Framework
Standardized framework for creating business-focused subagents
"""

import json
import sys
import os
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime
from dataclasses import dataclass, asdict
from abc import ABC, abstractmethod
from enum import Enum

class BusinessDomain(Enum):
    """Business domains for subagent classification"""
    MARKETING = "marketing"
    SALES = "sales"
    CUSTOMER_SUCCESS = "customer_success"
    CONTENT = "content"
    ANALYTICS = "analytics"
    OPERATIONS = "operations"

class OutputFormat(Enum):
    """Standard output formats for business subagents"""
    TEXT = "text"
    MARKDOWN = "markdown"
    HTML = "html"
    JSON = "json"
    EMAIL = "email"
    SOCIAL_POST = "social_post"
    PRESENTATION = "presentation"
    REPORT = "report"

@dataclass
class BusinessContext:
    """Business context for subagent operations"""
    company_name: str = "Schemantics"
    industry: str = "Software Development Tools"
    target_audience: str = "Software Developers"
    brand_voice: str = "Technical, Helpful, Innovative"
    primary_languages: List[str] = None
    key_metrics: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.primary_languages is None:
            self.primary_languages = ["Julia", "Rust", "TypeScript", "Elixir"]
        if self.key_metrics is None:
            self.key_metrics = {
                "user_acquisition": "monthly_signups",
                "engagement": "daily_active_users",
                "retention": "monthly_retention_rate",
                "revenue": "monthly_recurring_revenue"
            }

@dataclass
class SubagentTask:
    """Standardized task structure for business subagents"""
    task_id: str
    description: str
    domain: BusinessDomain
    priority: str  # "low", "medium", "high", "critical"
    deadline: Optional[str] = None
    context: Dict[str, Any] = None
    requirements: Dict[str, Any] = None
    success_criteria: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.context is None:
            self.context = {}
        if self.requirements is None:
            self.requirements = {}
        if self.success_criteria is None:
            self.success_criteria = {}

@dataclass
class SubagentOutput:
    """Standardized output structure for business subagents"""
    task_id: str
    status: str  # "completed", "failed", "partial"
    content: str
    format: OutputFormat
    metadata: Dict[str, Any]
    metrics: Dict[str, Any]
    follow_up_suggestions: List[str]
    timestamp: str
    
    def __post_init__(self):
        if not self.timestamp:
            self.timestamp = datetime.now().isoformat()

class BusinessSubagentBase(ABC):
    """Abstract base class for business subagents"""
    
    def __init__(self, name: str, domain: BusinessDomain, description: str):
        self.name = name
        self.domain = domain
        self.description = description
        self.business_context = BusinessContext()
        self.capabilities = self._define_capabilities()
        self.templates = self._load_templates()
        
        # Create subagent directory
        self.subagent_dir = Path.home() / ".claude" / "hooks" / "business" / "subagents" / name
        self.subagent_dir.mkdir(parents=True, exist_ok=True)
    
    @abstractmethod
    def _define_capabilities(self) -> List[str]:
        """Define what this subagent can do"""
        pass
    
    @abstractmethod
    def execute_task(self, task: SubagentTask) -> SubagentOutput:
        """Execute a business task"""
        pass
    
    def _load_templates(self) -> Dict[str, str]:
        """Load content templates for this subagent"""
        templates_file = self.subagent_dir / "templates.json"
        if templates_file.exists():
            with open(templates_file, 'r') as f:
                return json.load(f)
        return self._get_default_templates()
    
    @abstractmethod
    def _get_default_templates(self) -> Dict[str, str]:
        """Get default templates for this subagent type"""
        pass
    
    def save_templates(self, templates: Dict[str, str]):
        """Save templates to file"""
        templates_file = self.subagent_dir / "templates.json"
        with open(templates_file, 'w') as f:
            json.dump(templates, f, indent=2)
    
    def log_execution(self, task: SubagentTask, output: SubagentOutput):
        """Log task execution for learning"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "subagent": self.name,
            "task_id": task.task_id,
            "domain": self.domain.value,
            "status": output.status,
            "execution_time": self._calculate_execution_time(task, output),
            "success": output.status == "completed"
        }
        
        log_file = self.subagent_dir / "execution_log.jsonl"
        with open(log_file, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')
    
    def _calculate_execution_time(self, task: SubagentTask, output: SubagentOutput) -> int:
        """Calculate execution time in milliseconds"""
        # This would be implemented with actual timing in real execution
        return 5000  # Placeholder: 5 seconds
    
    def get_performance_metrics(self) -> Dict[str, Any]:
        """Get performance metrics for this subagent"""
        log_file = self.subagent_dir / "execution_log.jsonl"
        if not log_file.exists():
            return {"executions": 0, "success_rate": 0.0}
        
        executions = []
        with open(log_file, 'r') as f:
            for line in f:
                executions.append(json.loads(line))
        
        total = len(executions)
        successful = len([e for e in executions if e["success"]])
        success_rate = successful / total if total > 0 else 0.0
        
        avg_time = sum(e["execution_time"] for e in executions) / total if total > 0 else 0
        
        return {
            "executions": total,
            "success_rate": success_rate,
            "avg_execution_time_ms": avg_time,
            "last_execution": executions[-1]["timestamp"] if executions else None
        }
    
    def generate_schema_aligned_prompt(self, task: SubagentTask) -> str:
        """Generate schema-aligned prompt for LLM execution"""
        prompt = f"""[BUSINESS SUBAGENT: {self.name.upper()}]
Domain: {self.domain.value}
Task: {task.description}

Business Context:
- Company: {self.business_context.company_name}
- Industry: {self.business_context.industry}
- Target Audience: {self.business_context.target_audience}
- Brand Voice: {self.business_context.brand_voice}
- Primary Languages: {', '.join(self.business_context.primary_languages)}

Task Requirements:
{json.dumps(task.requirements, indent=2)}

Success Criteria:
{json.dumps(task.success_criteria, indent=2)}

Templates Available:
{list(self.templates.keys())}

Please execute this business task following the schema-aligned approach with:
1. Clear, actionable output
2. Metrics for measuring success
3. Follow-up recommendations
4. Schema compliance for integration with other subagents"""
        
        return prompt

class ContentCreatorSubagent(BusinessSubagentBase):
    """Content creation subagent for blogs, docs, announcements"""
    
    def __init__(self):
        super().__init__(
            name="content-creator",
            domain=BusinessDomain.CONTENT,
            description="Creates high-quality content for blogs, documentation, and announcements"
        )
    
    def _define_capabilities(self) -> List[str]:
        return [
            "Blog post creation",
            "Technical documentation",
            "Product announcements",
            "Feature descriptions",
            "Tutorial content",
            "API documentation",
            "Release notes",
            "Marketing copy"
        ]
    
    def _get_default_templates(self) -> Dict[str, str]:
        return {
            "blog_post": """# {title}

## Introduction
{introduction}

## Main Content
{main_content}

## Technical Details
{technical_details}

## Conclusion
{conclusion}

---
*Written for {company_name} - Empowering developers with schema-aligned programming tools*""",
            
            "feature_announcement": """# Introducing {feature_name}

We're excited to announce {feature_name}, a new addition to {company_name} that {value_proposition}.

## What's New
{features_list}

## Benefits for Developers
- **{benefit_1}**: {benefit_1_description}
- **{benefit_2}**: {benefit_2_description} 
- **{benefit_3}**: {benefit_3_description}

## Getting Started
{getting_started_instructions}

## Technical Implementation
For our primary languages ({primary_languages}), {feature_name} provides:
{technical_implementation}

Try it today and let us know what you think!""",
            
            "documentation": """# {title}

## Overview
{overview}

## Prerequisites
{prerequisites}

## Setup
{setup_instructions}

## Usage
{usage_examples}

## API Reference
{api_reference}

## Examples
{code_examples}

## Troubleshooting
{troubleshooting}""",
            
            "release_notes": """# Release Notes - Version {version}

Released: {release_date}

## New Features
{new_features}

## Improvements
{improvements}

## Bug Fixes
{bug_fixes}

## Breaking Changes
{breaking_changes}

## Migration Guide
{migration_guide}"""
        }
    
    def execute_task(self, task: SubagentTask) -> SubagentOutput:
        """Execute content creation task"""
        # This would integrate with LLM for actual content generation
        # For now, return a template-based response
        
        content_type = task.requirements.get("type", "blog_post")
        template = self.templates.get(content_type, self.templates["blog_post"])
        
        # Generate schema-aligned prompt
        prompt = self.generate_schema_aligned_prompt(task)
        
        # Placeholder for actual LLM integration
        content = template.format(
            title=task.requirements.get("title", "Generated Content"),
            company_name=self.business_context.company_name,
            primary_languages=", ".join(self.business_context.primary_languages),
            **task.requirements
        )
        
        output = SubagentOutput(
            task_id=task.task_id,
            status="completed",
            content=content,
            format=OutputFormat.MARKDOWN,
            metadata={
                "content_type": content_type,
                "word_count": len(content.split()),
                "template_used": content_type
            },
            metrics={
                "readability_score": 85,  # Placeholder
                "seo_score": 78,  # Placeholder
                "engagement_potential": "high"
            },
            follow_up_suggestions=[
                "Consider SEO optimization with seo-optimizer-agent",
                "Create social media promotion with social-media-agent",
                "Set up analytics tracking with analytics-tracker-agent"
            ],
            timestamp=datetime.now().isoformat()
        )
        
        self.log_execution(task, output)
        return output

class SocialMediaSubagent(BusinessSubagentBase):
    """Social media content and campaign management subagent"""
    
    def __init__(self):
        super().__init__(
            name="social-media",
            domain=BusinessDomain.MARKETING,
            description="Creates and manages social media content and campaigns"
        )
    
    def _define_capabilities(self) -> List[str]:
        return [
            "Twitter thread creation",
            "LinkedIn post generation",
            "Social media campaign planning",
            "Community engagement strategies",
            "Hashtag research",
            "Content calendar planning",
            "Cross-platform content adaptation"
        ]
    
    def _get_default_templates(self) -> Dict[str, str]:
        return {
            "twitter_thread": """🧵 {hook_tweet}

1/{total_tweets} {first_point}

2/{total_tweets} {second_point}

3/{total_tweets} {third_point}

{total_tweets}/{total_tweets} {conclusion}

#SchemeProgramming #{primary_language} #DevTools""",
            
            "linkedin_post": """🚀 {announcement}

{main_content}

Key benefits:
✅ {benefit_1}
✅ {benefit_2} 
✅ {benefit_3}

Perfect for developers working with {primary_languages}.

What are your thoughts? Share in the comments! 👇

#{company_name} #DeveloperTools #Programming""",
            
            "product_launch_campaign": """Campaign: {campaign_name}

Platforms: Twitter, LinkedIn, Reddit (r/programming)
Duration: {duration}
Objective: {objective}

Content Strategy:
- Teaser posts (Week 1)
- Feature highlights (Week 2)  
- Launch announcement (Week 3)
- User testimonials (Week 4)

Hashtags: #{primary_hashtag} #{secondary_hashtag} #DevTools""",
            
            "community_engagement": """Community Engagement Strategy:

Target Communities:
- Reddit: r/programming, r/{primary_language}
- Discord: Developer servers
- GitHub: Open source projects
- Stack Overflow: Technical Q&A

Engagement Plan:
{engagement_plan}

Content Types:
{content_types}"""
        }
    
    def execute_task(self, task: SubagentTask) -> SubagentOutput:
        """Execute social media task"""
        content_type = task.requirements.get("type", "linkedin_post")
        platform = task.requirements.get("platform", "linkedin")
        template = self.templates.get(content_type, self.templates["linkedin_post"])
        
        # Generate schema-aligned prompt
        prompt = self.generate_schema_aligned_prompt(task)
        
        # Placeholder for actual content generation
        content = template.format(
            company_name=self.business_context.company_name,
            primary_languages=", ".join(self.business_context.primary_languages),
            primary_language=self.business_context.primary_languages[0],
            **task.requirements
        )
        
        output = SubagentOutput(
            task_id=task.task_id,
            status="completed",
            content=content,
            format=OutputFormat.SOCIAL_POST,
            metadata={
                "platform": platform,
                "content_type": content_type,
                "character_count": len(content),
                "hashtag_count": content.count('#')
            },
            metrics={
                "estimated_reach": 500,  # Placeholder
                "engagement_potential": "medium",
                "viral_score": 65  # Placeholder
            },
            follow_up_suggestions=[
                "Schedule optimal posting time with scheduling tool",
                "Track engagement with analytics-tracker-agent",
                "Create follow-up content based on engagement"
            ],
            timestamp=datetime.now().isoformat()
        )
        
        self.log_execution(task, output)
        return output

def create_subagent_registry() -> Dict[str, BusinessSubagentBase]:
    """Create registry of available business subagents"""
    return {
        "content-creator": ContentCreatorSubagent(),
        "social-media": SocialMediaSubagent(),
        # Additional subagents will be added here
    }

def main():
    """Main entry point for business subagent execution"""
    if len(sys.argv) < 2:
        print("Usage: business_subagent_template.py <subagent_name> [task_json]", file=sys.stderr)
        sys.exit(1)
    
    subagent_name = sys.argv[1]
    registry = create_subagent_registry()
    
    if subagent_name not in registry:
        print(f"Error: Subagent '{subagent_name}' not found", file=sys.stderr)
        print(f"Available subagents: {', '.join(registry.keys())}", file=sys.stderr)
        sys.exit(1)
    
    subagent = registry[subagent_name]
    
    # Get task from command line or stdin
    if len(sys.argv) > 2:
        task_data = json.loads(sys.argv[2])
    else:
        try:
            task_data = json.load(sys.stdin)
        except:
            print("Error: No task data provided", file=sys.stderr)
            sys.exit(1)
    
    # Create task object
    task = SubagentTask(
        task_id=task_data.get("task_id", f"task_{int(datetime.now().timestamp())}"),
        description=task_data.get("description", ""),
        domain=BusinessDomain(task_data.get("domain", subagent.domain.value)),
        priority=task_data.get("priority", "medium"),
        deadline=task_data.get("deadline"),
        context=task_data.get("context", {}),
        requirements=task_data.get("requirements", {}),
        success_criteria=task_data.get("success_criteria", {})
    )
    
    # Execute task
    output = subagent.execute_task(task)
    
    # Return result
    print(json.dumps(asdict(output), indent=2))

if __name__ == "__main__":
    main()