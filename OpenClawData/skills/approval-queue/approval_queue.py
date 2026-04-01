#!/usr/bin/env python3
import sys, json, os
from datetime import datetime

QUEUE_PATH = os.path.join(os.path.dirname(__file__), '..', '..', 'queues', 'approval_queue.json')

def load_queue():
    if not os.path.exists(QUEUE_PATH):
        return []
    with open(QUEUE_PATH, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_queue(q):
    os.makedirs(os.path.dirname(QUEUE_PATH), exist_ok=True)
    with open(QUEUE_PATH, 'w', encoding='utf-8') as f:
        json.dump(q, f, indent=2)

def find_entry(q, prod_id):
    for e in q:
        if e['id'] == prod_id:
            return e
    return None

def main():
    if len(sys.argv) < 3:
        print('Usage: approval_queue.py <add|approve|reject> <product_id>')
        sys.exit(1)
    action, prod_id = sys.argv[1], sys.argv[2]
    queue = load_queue()
    entry = find_entry(queue, prod_id)
    if action == 'add':
        if entry:
            print(f'Entry {prod_id} already exists with status {entry["status"]}')
        else:
            queue.append({
                'id': prod_id,
                'status': 'pending',
                'timestamp': datetime.utcnow().isoformat() + 'Z'
            })
            save_queue(queue)
            print(f'Added {prod_id} as pending')
    elif action in ('approve', 'reject'):
        if not entry:
            print(f'No entry found for {prod_id}')
            sys.exit(1)
        entry['status'] = 'approved' if action == 'approve' else 'rejected'
        entry['timestamp'] = datetime.utcnow().isoformat() + 'Z'
        save_queue(queue)
        print(f'{action.title()}d {prod_id}')
    else:
        print('Unknown action')
        sys.exit(1)

if __name__ == '__main__':
    main()
