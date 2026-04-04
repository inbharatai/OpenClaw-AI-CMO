---
name: credential-safety-policy
description: Scan content for credentials, API keys, personal data, and sensitive information before publishing. Use as a safety gate in the approval pipeline. Triggers on any content safety scan or data leak prevention check.
---

> **HONEST CLASSIFICATION:** This is a **prompt template**, not an executable plugin.
> OpenClaw injects this as context to guide LLM behavior. It does NOT enforce rules at runtime.
> Real enforcement requires the shell scripts in `OpenClawData/scripts/`.
# Credential Safety Policy

Scan content for sensitive data that must never be published.

## Default Model

`qwen2.5-coder:7b` — pattern matching for sensitive data.

## Input

Content text to scan.

## Output Format

```json
{
  "safe": <true|false>,
  "data_safety_score": <0-100>,
  "findings": [
    {
      "type": "<credential|email|phone|api_key|password|personal_data|financial>",
      "snippet": "<masked excerpt showing where the issue is>",
      "severity": "<critical|high|medium|low>"
    }
  ],
  "action": "<pass|block>",
  "reason": "<explanation>"
}
```

## What to Scan For

### CRITICAL (always block)
- API keys, tokens, secrets (patterns: `sk-`, `pk_`, `ghp_`, `xoxb-`, `Bearer `, long hex/base64 strings)
- Passwords or passphrases
- Private SSH keys
- Database connection strings
- AWS/GCP/Azure credentials

### HIGH (block)
- Personal email addresses (not public/business contact emails)
- Phone numbers
- Social security numbers, passport numbers, ID numbers
- Credit card numbers
- Home addresses

### MEDIUM (flag for review)
- Named individuals with identifiable context
- Internal project codenames or unreleased product names
- Internal meeting notes or private conversations
- Salary or compensation information

### LOW (pass with note)
- Public business email addresses (info@, support@, hello@)
- Public-facing company names and addresses
- Publicly available information

## Rules

1. ANY critical or high finding → block immediately
2. Medium findings → flag and escalate to review queue
3. Low findings → pass with a note in the log
4. When masking in snippets, show enough context to locate the issue but redact the actual sensitive data
5. Err on the side of caution — false positives are better than leaked credentials
