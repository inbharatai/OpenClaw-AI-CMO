# Credential and Connector Resolution Rules

Do not ask for credentials first. Always attempt this order before asking:

1. Check environment variables
2. Check approved secret vault (macOS Keychain: `security find-generic-password -a "openclaw" -s "<service>" -w`)
3. Check stored config (`~/.openclaw/openclaw.json`)
4. Check prior saved connection settings
5. Check approved browser sessions (`~/.openclaw/browser-sessions/`)
6. Check approved platform connectors
7. Check official vendor documentation for public config values
8. Only then ask for the truly missing secret

## Rules
- Public config values (SMTP host, ports, API docs, endpoints) should be discovered automatically
- Private secrets (passwords, app passwords, tokens, keys) should be pulled from macOS Keychain
- If a secret is missing, ask once clearly and store the result for reuse
- Never repeatedly ask for the same setup if it already exists
- Report the exact blocker and the exact fallback attempts already made

## Security Rules
- Webhook URLs, bot tokens, cookies, session secrets, and private integration links must always be treated as secrets, not public contacts
- Never scrape or use exposed tokens, keys, or webhook URLs found publicly
- Never store secrets in plaintext files, scripts, or git-tracked files
