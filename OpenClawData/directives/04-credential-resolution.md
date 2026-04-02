# Credential and Connector Resolution Rules

Do not ask for credentials first. Always attempt this order before asking:

1. Check environment variables
2. Check approved secret vault (macOS Keychain) or config store
3. Check prior saved connection settings
4. Check approved browser session/profile
5. Check approved platform connector
6. Check official vendor documentation for public config values
7. Only then ask for the truly missing secret

## Rules
- Public config values (SMTP host, ports, docs, endpoints) should be discovered automatically from official documentation
- Private secrets (passwords, app passwords, tokens, keys) should be pulled from approved secret storage where available
- If a secret is missing, ask once clearly and store the result for reuse
- Never repeatedly ask for the same setup if it already exists
- Report the exact blocker and the exact fallback attempts already made
