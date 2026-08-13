import json
import os
import random
from collections import defaultdict

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    original_path = os.path.join(base_dir, 'data', 'original', 'fitness_intents.json')
    processed_dir = os.path.join(base_dir, 'data', 'processed')

    os.makedirs(processed_dir, exist_ok=True)

    with open(original_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Group items by intent for stratified splitting
    grouped = defaultdict(list)
    for item in data:
        grouped[item['intent']].append(item)

    train_set, val_set, test_set = [], [], []

    random.seed(42)
    for intent, items in grouped.items():
        random.shuffle(items)
        n = len(items)
        if n >= 3:
            train_count = int(n * 0.7)
            val_count = max(1, int(n * 0.15))
            train_set.extend(items[:train_count])
            val_set.extend(items[train_count:train_count + val_count])
            test_set.extend(items[train_count + val_count:])
        else:
            train_set.extend(items[:-1])
            test_set.extend(items[-1:])

    with open(os.path.join(processed_dir, 'train.json'), 'w', encoding='utf-8') as f:
        json.dump(train_set, f, indent=2)

    with open(os.path.join(processed_dir, 'val.json'), 'w', encoding='utf-8') as f:
        json.dump(val_set, f, indent=2)

    with open(os.path.join(processed_dir, 'test.json'), 'w', encoding='utf-8') as f:
        json.dump(test_set, f, indent=2)

    print(f"Stratified dataset preparation complete: Total={len(data)}, Train={len(train_set)}, Val={len(val_set)}, Test={len(test_set)}")

if __name__ == '__main__':
    main()
