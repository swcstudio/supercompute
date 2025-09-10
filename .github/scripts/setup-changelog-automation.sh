#!/bin/bash

# Setup script for changelog automation

echo "🤖 Setting up Autonomous Changelog Generation"
echo "============================================"

# Check if required secrets are set
check_secret() {
    if gh secret list | grep -q "^$1"; then
        echo "✅ $1 is already configured"
    else
        echo "❌ $1 is not configured"
        echo "   Please add this secret to your repository:"
        echo "   gh secret set $1"
        MISSING_SECRETS=true
    fi
}

echo ""
echo "Checking required secrets..."
check_secret "ANTHROPIC_API_KEY"

if [ "$MISSING_SECRETS" = true ]; then
    echo ""
    echo "⚠️  Some secrets are missing. Please configure them before using changelog automation."
    echo ""
    echo "To add the Anthropic API key:"
    echo "1. Get your API key from https://console.anthropic.com/"
    echo "2. Run: gh secret set ANTHROPIC_API_KEY"
    echo "3. Paste your API key and press Enter"
else
    echo ""
    echo "✅ All required secrets are configured!"
fi

echo ""
echo "Configuring repository settings..."

# Enable auto-merge for changelog PRs (optional)
echo ""
read -p "Enable auto-merge for changelog PRs? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    gh variable set AUTO_MERGE_CHANGELOG --body "true"
    echo "✅ Auto-merge enabled for changelog PRs"
else
    gh variable set AUTO_MERGE_CHANGELOG --body "false"
    echo "✅ Auto-merge disabled for changelog PRs (manual review required)"
fi

echo ""
echo "Testing the setup..."

# Create a test workflow run
echo "Would you like to test the changelog generation now? (y/n) "
read -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Triggering a test run..."
    gh workflow run changelog-on-demand.yml \
        -f target_version="test-$(date +%s)" \
        -f release_type="patch" \
        -f dry_run="true"
    
    echo ""
    echo "✅ Test workflow triggered!"
    echo "   Check the Actions tab to see the results."
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "How to use the changelog automation:"
echo "1. Automatic generation on push to main:"
echo "   - The changelog will be automatically updated when you push to main"
echo "   - A PR will be created with the proposed changes"
echo ""
echo "2. Manual generation:"
echo "   gh workflow run changelog-on-demand.yml -f target_version=\"1.2.0\" -f release_type=\"minor\""
echo ""
echo "3. Dry run (preview only):"
echo "   gh workflow run changelog-on-demand.yml -f target_version=\"1.2.0\" -f release_type=\"minor\" -f dry_run=\"true\""
echo ""
echo "Happy changelog automation! 🚀"