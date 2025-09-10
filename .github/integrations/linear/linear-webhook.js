/**
 * Linear Integration for Claude Code
 * Handles Linear webhooks and enables AI-powered task management
 */

const { Anthropic } = require('@anthropic-ai/sdk');
const { LinearClient } = require('@linear/sdk');
const { Octokit } = require('@octokit/rest');

class LinearAIIntegration {
  constructor(config) {
    this.anthropic = new Anthropic({
      apiKey: config.anthropicApiKey,
    });
    
    this.linear = new LinearClient({
      apiKey: config.linearApiKey,
    });
    
    this.github = new Octokit({
      auth: config.githubToken,
    });
    
    this.config = config;
  }

  /**
   * Handle incoming Linear webhook
   */
  async handleWebhook(event) {
    console.log(`Received Linear webhook: ${event.type}`);
    
    switch (event.type) {
      case 'Issue':
        return this.handleIssueEvent(event);
      case 'Comment':
        return this.handleCommentEvent(event);
      case 'Project':
        return this.handleProjectEvent(event);
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }
  }

  /**
   * Handle Linear issue events
   */
  async handleIssueEvent(event) {
    const { action, data } = event;
    const issue = data;
    
    // Check for AI-related labels
    const hasAILabel = issue.labels?.some(label => 
      label.name.toLowerCase().includes('ai') || 
      label.name.toLowerCase().includes('claude')
    );
    
    if (!hasAILabel) return;
    
    switch (action) {
      case 'create':
        await this.handleNewIssue(issue);
        break;
      case 'update':
        await this.handleIssueUpdate(issue);
        break;
    }
  }

  /**
   * Handle new Linear issue with AI
   */
  async handleNewIssue(issue) {
    // Check if issue needs decomposition
    if (issue.estimate && issue.estimate > 8) {
      await this.decomposeIssue(issue);
    }
    
    // Check if issue needs implementation
    if (issue.labels?.some(l => l.name === 'ai-implement')) {
      await this.createGitHubIssueAndImplement(issue);
    }
    
    // Generate technical spec if requested
    if (issue.labels?.some(l => l.name === 'needs-spec')) {
      await this.generateTechnicalSpec(issue);
    }
  }

  /**
   * Decompose large Linear issue into subtasks
   */
  async decomposeIssue(issue) {
    const prompt = `
    You are Claude Code, an expert at breaking down software engineering tasks.
    
    Decompose this Linear issue into subtasks:
    
    Title: ${issue.title}
    Description: ${issue.description || 'No description'}
    Estimate: ${issue.estimate} points
    Labels: ${issue.labels?.map(l => l.name).join(', ')}
    
    Break this down into 3-8 subtasks that are each 1-3 points.
    For each subtask provide:
    1. Title
    2. Description
    3. Estimate (1-3 points)
    4. Dependencies on other subtasks
    5. Acceptance criteria
    
    Format as JSON array.
    `;
    
    const response = await this.anthropic.messages.create({
      model: 'claude-3-opus-20240229',
      max_tokens: 4000,
      messages: [{ role: 'user', content: prompt }],
    });
    
    const subtasks = JSON.parse(response.content[0].text);
    
    // Create subtasks in Linear
    for (const subtask of subtasks) {
      await this.linear.issueCreate({
        teamId: issue.teamId,
        title: subtask.title,
        description: subtask.description,
        estimate: subtask.estimate,
        parentId: issue.id,
        labelIds: issue.labelIds, // Inherit parent labels
      });
    }
    
    // Update parent issue
    await this.linear.issueUpdate(issue.id, {
      description: issue.description + '\n\n---\n\n## AI Decomposition\n\nThis issue has been automatically decomposed into subtasks by Claude Code.',
    });
    
    // Add comment
    await this.linear.commentCreate({
      issueId: issue.id,
      body: `🤖 I've decomposed this issue into ${subtasks.length} subtasks. Each subtask is estimated at 1-3 points for better manageability.`,
    });
  }

  /**
   * Generate technical specification
   */
  async generateTechnicalSpec(issue) {
    const prompt = `
    You are Claude Code, an expert software architect.
    
    Generate a detailed technical specification for:
    
    Title: ${issue.title}
    Description: ${issue.description || 'No description'}
    Project: ${issue.project?.name || 'Unknown'}
    
    Include:
    1. Technical Overview
    2. Architecture Design
    3. Implementation Plan
    4. API Specifications
    5. Database Schema (if applicable)
    6. Security Considerations
    7. Performance Requirements
    8. Testing Strategy
    9. Deployment Plan
    10. Success Metrics
    
    Format in Markdown with diagrams where appropriate.
    `;
    
    const response = await this.anthropic.messages.create({
      model: 'claude-3-opus-20240229',
      max_tokens: 6000,
      messages: [{ role: 'user', content: prompt }],
    });
    
    const spec = response.content[0].text;
    
    // Create a document in Linear
    await this.linear.documentCreate({
      title: `Technical Spec: ${issue.title}`,
      content: spec,
      projectId: issue.projectId,
    });
    
    // Update issue with link to spec
    await this.linear.commentCreate({
      issueId: issue.id,
      body: `📋 I've created a technical specification for this issue. Check the project documents for "${issue.title} - Technical Spec".`,
    });
    
    // Remove the needs-spec label
    const labels = issue.labels.filter(l => l.name !== 'needs-spec');
    await this.linear.issueUpdate(issue.id, {
      labelIds: labels.map(l => l.id),
    });
  }

  /**
   * Create GitHub issue and trigger implementation
   */
  async createGitHubIssueAndImplement(linearIssue) {
    // Create corresponding GitHub issue
    const githubIssue = await this.github.issues.create({
      owner: this.config.githubOwner,
      repo: this.config.githubRepo,
      title: linearIssue.title,
      body: `## Linear Issue
      
**Linear ID**: ${linearIssue.identifier}
**Linear URL**: ${linearIssue.url}

## Description

${linearIssue.description || 'No description provided'}

## Acceptance Criteria

${this.extractAcceptanceCriteria(linearIssue.description)}

---

*This issue was synced from Linear by Claude Code*`,
      labels: ['ai-implement', 'from-linear'],
    });
    
    // Trigger AI implementation workflow
    await this.github.actions.createWorkflowDispatch({
      owner: this.config.githubOwner,
      repo: this.config.githubRepo,
      workflow_id: 'ai-pr-creator.yml',
      ref: 'main',
      inputs: {
        task_description: linearIssue.title + '\n\n' + linearIssue.description,
        branch_name: `linear-${linearIssue.identifier}`,
        priority: this.mapLinearPriority(linearIssue.priority),
      },
    });
    
    // Update Linear issue
    await this.linear.commentCreate({
      issueId: linearIssue.id,
      body: `🚀 I've created GitHub issue #${githubIssue.data.number} and started AI implementation. I'll update you when the PR is ready.`,
    });
  }

  /**
   * Handle comment events for AI commands
   */
  async handleCommentEvent(event) {
    const { action, data } = event;
    const comment = data;
    
    if (action !== 'create') return;
    
    // Check for AI commands in comments
    const aiCommands = {
      '/ai-implement': this.handleImplementCommand.bind(this),
      '/ai-review': this.handleReviewCommand.bind(this),
      '/ai-test': this.handleTestCommand.bind(this),
      '/ai-docs': this.handleDocsCommand.bind(this),
      '/ai-estimate': this.handleEstimateCommand.bind(this),
      '/ai-similar': this.handleSimilarCommand.bind(this),
    };
    
    for (const [command, handler] of Object.entries(aiCommands)) {
      if (comment.body.toLowerCase().startsWith(command)) {
        await handler(comment);
        break;
      }
    }
  }

  /**
   * Handle /ai-implement command
   */
  async handleImplementCommand(comment) {
    const issue = await this.linear.issue(comment.issueId);
    await this.createGitHubIssueAndImplement(issue);
  }

  /**
   * Handle /ai-estimate command
   */
  async handleEstimateCommand(comment) {
    const issue = await this.linear.issue(comment.issueId);
    
    const prompt = `
    Estimate the effort for this software task:
    
    Title: ${issue.title}
    Description: ${issue.description}
    
    Consider:
    1. Technical complexity
    2. Dependencies
    3. Testing requirements
    4. Documentation needs
    5. Review time
    
    Provide:
    - Estimate in story points (1, 2, 3, 5, 8, 13)
    - Breakdown of effort
    - Risk factors
    - Assumptions
    `;
    
    const response = await this.anthropic.messages.create({
      model: 'claude-3-opus-20240229',
      max_tokens: 2000,
      messages: [{ role: 'user', content: prompt }],
    });
    
    const estimation = response.content[0].text;
    
    // Extract story points
    const pointsMatch = estimation.match(/(\d+)\s*(?:story\s*)?points?/i);
    const points = pointsMatch ? parseInt(pointsMatch[1]) : null;
    
    // Update issue estimate
    if (points) {
      await this.linear.issueUpdate(issue.id, {
        estimate: points,
      });
    }
    
    // Add estimation details as comment
    await this.linear.commentCreate({
      issueId: issue.id,
      body: `📊 **AI Estimation**\n\n${estimation}`,
    });
  }

  /**
   * Handle /ai-similar command
   */
  async handleSimilarCommand(comment) {
    const issue = await this.linear.issue(comment.issueId);
    
    // Search for similar issues
    const similarIssues = await this.linear.issues({
      filter: {
        searchableContent: {
          contains: issue.title.split(' ').slice(0, 3).join(' '),
        },
        state: {
          type: { eq: 'completed' },
        },
      },
      first: 5,
    });
    
    if (similarIssues.nodes.length === 0) {
      await this.linear.commentCreate({
        issueId: issue.id,
        body: `🔍 No similar completed issues found.`,
      });
      return;
    }
    
    // Analyze similar issues for insights
    const prompt = `
    Analyze these similar completed issues and provide insights for the current issue:
    
    Current Issue: ${issue.title}
    
    Similar Issues:
    ${similarIssues.nodes.map(i => `- ${i.title}: ${i.estimate || 'No estimate'} points, completed in ${this.calculateDuration(i)}`).join('\n')}
    
    Provide:
    1. Common patterns
    2. Typical effort required
    3. Common challenges
    4. Lessons learned
    5. Recommendations
    `;
    
    const response = await this.anthropic.messages.create({
      model: 'claude-3-opus-20240229',
      max_tokens: 2000,
      messages: [{ role: 'user', content: prompt }],
    });
    
    await this.linear.commentCreate({
      issueId: issue.id,
      body: `🔍 **Similar Issues Analysis**\n\n${response.content[0].text}`,
    });
  }

  /**
   * Utility functions
   */
  extractAcceptanceCriteria(description) {
    // Extract AC from description or generate if not present
    if (!description) return '- [ ] Implementation complete\n- [ ] Tests added\n- [ ] Documentation updated';
    
    const acMatch = description.match(/acceptance criteria:?\s*([\s\S]*?)(?:\n\n|$)/i);
    if (acMatch) return acMatch[1];
    
    return '- [ ] Implementation complete\n- [ ] Tests added\n- [ ] Documentation updated';
  }

  mapLinearPriority(linearPriority) {
    const priorityMap = {
      0: 'low',
      1: 'medium',
      2: 'high',
      3: 'high',
      4: 'high',
    };
    return priorityMap[linearPriority] || 'medium';
  }

  calculateDuration(issue) {
    if (!issue.completedAt || !issue.startedAt) return 'Unknown duration';
    
    const start = new Date(issue.startedAt);
    const end = new Date(issue.completedAt);
    const days = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
    
    return `${days} days`;
  }
}

module.exports = LinearAIIntegration;