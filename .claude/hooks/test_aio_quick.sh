#!/bin/bash
# Quick test for AIO with model selection

echo "Testing AIO with different models..."
echo

# Test Sonnet
echo "1. Testing Sonnet (simple task):"
echo '{"event": "user_prompt_submit", "prompt": "/aio Q=\"write a hello world function\" model=\"Sonnet\""}' | \
    $HOME/.claude/hooks/context_activation_hook.sh --user-prompt 2>&1 | \
    jq -r '.routing.model // "none"'

# Test Opus
echo "2. Testing Opus (balanced task):"
echo '{"event": "user_prompt_submit", "prompt": "/aio Q=\"optimize this code\" model=\"Opus\""}' | \
    $HOME/.claude/hooks/context_activation_hook.sh --user-prompt 2>&1 | \
    jq -r '.routing.model // "none"'

# Test opusplan
echo "3. Testing opusplan (complex task):"
echo '{"event": "user_prompt_submit", "prompt": "/aio Q=\"design secure architecture\" model=\"opusplan\""}' | \
    $HOME/.claude/hooks/context_activation_hook.sh --user-prompt 2>&1 | \
    jq -r '.routing.model // "none"'

echo
echo "If you see model names above, the system is working!"
