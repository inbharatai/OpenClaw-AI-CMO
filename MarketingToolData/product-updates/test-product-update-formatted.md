━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

```markdown
title: "OpenClaw v2.1 Released"
date: "2023-10-25"
type: "product-update"
product: "OpenClaw"
version: "v2.1"
tags: ["release", "update", "features", "performance", "bug fixes"]
source_file: "MarketingToolData/product-updates/openclaw-v2.1.md"
status: "formatted"

# OpenClaw v2.1 Released

## Summary
OpenClaw v2.1 introduces smart skill chaining, memory persistence across sessions, and 40% faster Ollama inference. This release also resolves the skill-runner timeout issue affecting long-running tasks.

## Changes
- **Smart skill chaining**: Skills can now call other skills in sequence, enabling more complex workflows
- **Memory persistence across sessions**: Conversations and context carry forward between sessions
- **40% faster Ollama inference**: Performance improved via batched request optimization
- **Fixed skill-runner timeout**: Resolves issues with long-running task execution

## User Impact
All users will benefit from improved efficiency and reliability, particularly those utilizing long-running tasks or skill chaining workflows.

## Technical Notes
The Ollama inference speed improvement comes from batched request processing, which reduces overhead in distributed computing scenarios. The timeout fix involves optimized resource allocation for extended operations.

## Related
[View release notes](#) | [Learn about skill chaining](#)
```
