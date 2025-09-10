#!/bin/bash

# Setup script for AI GitHub Workflows labels
# Usage: ./setup-labels.sh [repo-name]

REPO=${1:-$(gh repo view --json name -q .name)}

echo "🏷️  Creating AI workflow labels for $REPO..."

# AI Workflow Labels
gh label create "ai-implement" \
  --color "7057FF" \
  --description "Trigger AI implementation" \
  --repo "$REPO" 2>/dev/null || echo "Label 'ai-implement' already exists"

gh label create "ai-decompose" \
  --color "0E8A16" \
  --description "Trigger AI decomposition" \
  --repo "$REPO" 2>/dev/null || echo "Label 'ai-decompose' already exists"

gh label create "ai-generated" \
  --color "1D76DB" \
  --description "Created by AI" \
  --repo "$REPO" 2>/dev/null || echo "Label 'ai-generated' already exists"

gh label create "ai-approved" \
  --color "0E8A16" \
  --description "Approved by AI review" \
  --repo "$REPO" 2>/dev/null || echo "Label 'ai-approved' already exists"

gh label create "ai-changes-requested" \
  --color "D93F0B" \
  --description "Changes requested by AI" \
  --repo "$REPO" 2>/dev/null || echo "Label 'ai-changes-requested' already exists"

gh label create "ai-reviewed" \
  --color "FBCA04" \
  --description "Reviewed by AI" \
  --repo "$REPO" 2>/dev/null || echo "Label 'ai-reviewed' already exists"

gh label create "skip-ai-review" \
  --color "E4E669" \
  --description "Skip AI review" \
  --repo "$REPO" 2>/dev/null || echo "Label 'skip-ai-review' already exists"

gh label create "ai-task" \
  --color "5319E7" \
  --description "AI task implementation" \
  --repo "$REPO" 2>/dev/null || echo "Label 'ai-task' already exists"

gh label create "ai-sequence" \
  --color "B60205" \
  --description "Part of AI task sequence" \
  --repo "$REPO" 2>/dev/null || echo "Label 'ai-sequence' already exists"

gh label create "epic" \
  --color "3E4B9E" \
  --description "Large feature requiring decomposition" \
  --repo "$REPO" 2>/dev/null || echo "Label 'epic' already exists"

gh label create "has-subtasks" \
  --color "FBCA04" \
  --description "Issue has been decomposed into subtasks" \
  --repo "$REPO" 2>/dev/null || echo "Label 'has-subtasks' already exists"

gh label create "subtask" \
  --color "D4C5F9" \
  --description "Subtask of a larger issue" \
  --repo "$REPO" 2>/dev/null || echo "Label 'subtask' already exists"

# Size Labels
gh label create "size/xs" \
  --color "009900" \
  --description "Extra small task (< 1 hour)" \
  --repo "$REPO" 2>/dev/null || echo "Label 'size/xs' already exists"

gh label create "size/s" \
  --color "77BB00" \
  --description "Small task (1-3 hours)" \
  --repo "$REPO" 2>/dev/null || echo "Label 'size/s' already exists"

gh label create "size/m" \
  --color "EEBB00" \
  --description "Medium task (3-8 hours)" \
  --repo "$REPO" 2>/dev/null || echo "Label 'size/m' already exists"

gh label create "size/l" \
  --color "EE9900" \
  --description "Large task (1-3 days)" \
  --repo "$REPO" 2>/dev/null || echo "Label 'size/l' already exists"

gh label create "size/xl" \
  --color "EE5500" \
  --description "Extra large task (3+ days)" \
  --repo "$REPO" 2>/dev/null || echo "Label 'size/xl' already exists"

echo "✅ All AI workflow labels created successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Add ANTHROPIC_API_KEY to your repository secrets"
echo "2. Start using AI workflows:"
echo "   - Add 'ai-implement' label to issues for AI implementation"
echo "   - Add 'ai-decompose' label to epics for breakdown"
echo "   - PRs will be automatically reviewed by AI"