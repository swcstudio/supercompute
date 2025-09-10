#!/bin/bash

# AI GitHub Workflows Installer
# Usage: curl -sSL https://raw.githubusercontent.com/yourusername/ai-github-workflows/main/.github/install.sh | bash

set -e

echo "🤖 Installing AI-Powered GitHub Workflows..."

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Create .github directories
mkdir -p .github/workflows
mkdir -p .claude

# Download workflows
WORKFLOWS=(
    "ai-pr-creator.yml"
    "ai-pr-reviewer.yml"
    "ai-sequential-tasks.yml"
    "ai-issue-decomposer.yml"
    "ai-test-generator.yml"
)

BASE_URL="https://raw.githubusercontent.com/yourusername/ai-github-workflows/main/.github/workflows"

for workflow in "${WORKFLOWS[@]}"; do
    echo "📥 Downloading $workflow..."
    curl -sSL "$BASE_URL/$workflow" -o ".github/workflows/$workflow"
done

# Download documentation
echo "📚 Downloading documentation..."
curl -sSL "https://raw.githubusercontent.com/yourusername/ai-github-workflows/main/.claude/017-github-ai-workflows.md" \
    -o ".claude/017-github-ai-workflows.md"

# Download setup script
echo "🏷️  Downloading label setup script..."
curl -sSL "https://raw.githubusercontent.com/yourusername/ai-github-workflows/main/.github/setup-labels.sh" \
    -o ".github/setup-labels.sh"
chmod +x .github/setup-labels.sh

# Prompt for label setup
read -p "Would you like to create the required labels now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./.github/setup-labels.sh
fi

echo ""
echo "✅ AI Workflows installed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Add ANTHROPIC_API_KEY to your repository secrets:"
echo "   gh secret set ANTHROPIC_API_KEY"
echo ""
echo "2. If you didn't create labels, run:"
echo "   ./.github/setup-labels.sh"
echo ""
echo "3. Start using AI workflows:"
echo "   - Label issues with 'ai-implement' for AI implementation"
echo "   - Label issues with 'ai-decompose' for epic breakdown"
echo "   - PRs will be automatically reviewed by AI"
echo ""
echo "📖 Full documentation: .claude/017-github-ai-workflows.md"