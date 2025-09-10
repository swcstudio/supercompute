#!/bin/bash

# Test script for quantum command transformation
# Tests various command types to ensure they all output in Module 08 format

HOOK_SCRIPT="/home/ubuntu/.claude/hooks/quantum_command_hook.sh"

echo "Testing Quantum Command Transformation"
echo "======================================"

echo ""
echo "1. Testing alignment command with Q parameter:"
echo "Command: /alignment Q=\"help me\""
$HOOK_SCRIPT "/alignment Q=\"help me\""

echo ""
echo "2. Testing simple alignment command:"
echo "Command: /alignment Q=test"
$HOOK_SCRIPT "/alignment Q=test"

echo ""
echo "3. Testing other slash commands:"
echo "Command: /aio research quantum computing"
$HOOK_SCRIPT "/aio research quantum computing"

echo ""
echo "4. Testing natural language:"
echo "Command: help me with quantum fields"
$HOOK_SCRIPT "help me with quantum fields"

echo ""
echo "5. Testing XML input:"
echo "Command: <test-xml>example</test-xml>"
$HOOK_SCRIPT "<test-xml>example</test-xml>"

echo ""
echo "Testing complete. All outputs should reference:"
echo "@/home/ubuntu/src/repos/supercompute/00_foundations/08_quantum_fields.md"