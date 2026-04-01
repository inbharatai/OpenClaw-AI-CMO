# Native Social Pipeline

Generates original social content from InBharat's product truth and content buckets.

## How It Works
1. Reads product-truth files from strategy/product-truth/
2. Selects content bucket from strategy/content-buckets.md
3. Applies platform rules from strategy/platform-rules/
4. Routes through content-agent.sh with appropriate skill
5. Generates content package
6. Routes to approval-engine.sh
7. Approved content goes to distribution-engine.sh

## Content Types Generated
- Instagram Reel packages (hook + script + caption + image brief)
- YouTube Shorts packages (hook + script + title + description)
- LinkedIn posts (hook + body + hashtags)
- X posts/threads (tweet text + optional image brief)
- Discord announcements (formatted message + embed data)
