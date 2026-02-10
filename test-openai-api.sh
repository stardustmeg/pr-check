#!/bin/bash
# Minimal test to debug OpenAI API JSON response for PR review
# Uses Node.js for JSON handling (no jq/python dependency)
#
# Usage: OPENAI_API_KEY=sk-... bash test-openai-api.sh [model]
# Example: OPENAI_API_KEY=sk-... bash test-openai-api.sh gpt-4.1

set -euo pipefail

MODEL="${1:-gpt-4.1}"

if ! command -v node > /dev/null 2>&1; then
  echo "Error: node not found"
  exit 1
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "Error: OPENAI_API_KEY not set"
  echo "Usage: OPENAI_API_KEY=sk-... bash test-openai-api.sh [model]"
  exit 1
fi

echo "=== OpenAI JSON Response Test ==="
echo "Model: $MODEL"
echo ""

# --- Build the request body using Node (safe JSON escaping) ---
REQUEST_BODY=$(node -e "
const system = \`You are an expert code reviewer. You will receive a pull request diff
where each added/changed line is annotated as [filepath:line_number].

Return your review as a **single JSON object** with this exact schema:

{
  \"summary\": \"<markdown-formatted overall review>\",
  \"inline_comments\": [
    {
      \"path\": \"relative/file/path.ext\",
      \"line\": 0,
      \"body\": \"Your specific, actionable comment\"
    }
  ]
}

Rules:
- path and line MUST exactly match values from the [filepath:line] annotations.
- Only comment on added/changed lines (those with [filepath:line] annotations).
- Keep inline comments specific, actionable, and concise.
- Focus on: bugs, security issues, performance problems, correctness, and maintainability.
- Do NOT add praise-only inline comments - only comment where there is something actionable.
- If nothing warrants an inline comment, return an empty inline_comments array.
- summary should cover: overview of changes, strengths, issues, suggestions, security, and testing.
- Return ONLY the raw JSON object. No markdown fences. No surrounding text.\`;

const user = \`PR Title: Test hardcoded password
PR Description: Adding app entry point

Annotated Diff:
=== src/app.ts ===
[src/app.ts:1] +import { run } from \"./utils\";
[src/app.ts:2] +
[src/app.ts:3] +const password = \"admin123\";
[src/app.ts:4] +console.log(password);
[src/app.ts:5] +run();\`;

console.log(JSON.stringify({
  model: '${MODEL}',
  max_completion_tokens: 1024,
  temperature: 0.2,
  response_format: { type: 'json_object' },
  messages: [
    { role: 'system', content: system },
    { role: 'user', content: user }
  ]
}));
" 2>&1)

REQUEST_BODY_NO_FMT=$(node -e "
const body = JSON.parse(process.argv[1]);
delete body.response_format;
console.log(JSON.stringify(body));
" "$REQUEST_BODY" 2>&1)

# --- Helper: parse and display response ---
parse_response() {
  node -e "
    const raw = require('fs').readFileSync(0, 'utf8');
    let resp;
    try { resp = JSON.parse(raw); } catch(e) {
      console.log('Failed to parse API response');
      console.log(raw.slice(0, 500));
      process.exit(1);
    }
    if (resp.error) {
      console.log('API ERROR:', resp.error.message || JSON.stringify(resp.error));
      process.exit(0);
    }
    const content = resp.choices?.[0]?.message?.content || 'EMPTY';
    console.log('--- Raw content from API ---');
    console.log(content);
    console.log('---');
    console.log();
    try {
      const review = JSON.parse(content);
      console.log('Valid JSON: YES');
      console.log('Has summary:', 'summary' in review);
      console.log('Has inline_comments:', 'inline_comments' in review);
      if (review.inline_comments) {
        console.log('Inline comment count:', review.inline_comments.length);
        review.inline_comments.forEach(c =>
          console.log('  ->', c.path + ':' + c.line, '-', (c.body || '').slice(0, 80))
        );
      }
      console.log();
      console.log('Formatted JSON:');
      console.log(JSON.stringify(review, null, 2));
    } catch(e) {
      console.log('Valid JSON: NO');
      console.log('Model returned non-JSON despite instructions');
    }
  "
}

# --- Test 1: WITH response_format ---
echo ">>> Test 1: WITH response_format: json_object"
echo ""

curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$REQUEST_BODY" | parse_response

echo ""
echo ">>> Test 2: WITHOUT response_format"
echo ""

curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$REQUEST_BODY_NO_FMT" | parse_response

echo ""
echo "=== Done ==="
