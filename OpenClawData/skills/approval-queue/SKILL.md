# Approval‑Queue Skill

This skill provides a very simple JSON‑based approval queue for the CMO pipeline.

## How it works
- The queue is stored in `OpenClawData/queues/approval_queue.json`.
- Each entry is an object with:
  ```json
  {
    "id": "<product‑id>",
    "status": "pending" | "approved" | "rejected",
    "timestamp": "<ISO‑8601>"
  }
  ```
- The skill accepts a single argument (`add`, `approve`, or `reject`) followed by the product ID.

## Usage example (via `skill‑runner` or `openclaw skill`)
```
openclaw skill run approval‑queue add sample-001
openclaw skill run approval‑queue approve sample-001
openclaw skill run approval‑queue reject sample-002
```

The script will create the queue file if it does not exist, add entries, and update statuses accordingly, returning a short status message.
