#!/bin/bash
# Test script to verify Anthropic API key works (no dependencies)

echo "🔍 Testing Anthropic API Connection"
echo "===================================="
echo ""

# Check if API key is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "❌ Error: ANTHROPIC_API_KEY environment variable not set"
  echo ""
  echo "Set it with: export ANTHROPIC_API_KEY='your-key-here'"
  exit 1
fi

echo "✅ API Key found (${#ANTHROPIC_API_KEY} characters)"
echo ""

# Test API call
echo "📡 Testing API call..."
echo ""

RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 100,
    "messages": [{
      "role": "user",
      "content": "Say hello in one sentence"
    }]
  }')

echo "Response received. Checking for errors..."
echo ""

# Check for error (simple grep, no jq needed)
if echo "$RESPONSE" | grep -q '"error"'; then
  echo "❌ API Error detected:"
  echo ""
  echo "$RESPONSE"
  echo ""
  exit 1
fi

# Check for content (simple grep, no jq needed)
if echo "$RESPONSE" | grep -q '"text"'; then
  echo "✅ API call successful!"
  echo ""
  echo "Full response:"
  echo "$RESPONSE"
  echo ""
  echo "🎉 Your API key is working correctly!"
  echo ""
  echo "If you see text in the response above, you're all set!"
else
  echo "❌ Unexpected response format:"
  echo ""
  echo "$RESPONSE"
  echo ""
  exit 1
fi