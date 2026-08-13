import json
import os
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, precision_recall_fscore_support

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    processed_dir = os.path.join(base_dir, 'data', 'processed')
    server_nlp_dir = os.path.join(base_dir, 'server', 'nlp')

    os.makedirs(server_nlp_dir, exist_ok=True)

    with open(os.path.join(processed_dir, 'train.json'), 'r', encoding='utf-8') as f:
        train_data = json.load(f)

    with open(os.path.join(processed_dir, 'val.json'), 'r', encoding='utf-8') as f:
        val_data = json.load(f)

    with open(os.path.join(processed_dir, 'test.json'), 'r', encoding='utf-8') as f:
        test_data = json.load(f)

    # Combine train + val for model fitting
    combined_train = train_data + val_data

    X_train = [item['text'] for item in combined_train]
    y_train = [item['intent'] for item in combined_train]

    X_test = [item['text'] for item in test_data]
    y_test = [item['intent'] for item in test_data]

    # Initialize TF-IDF Vectorizer
    vectorizer = TfidfVectorizer(ngram_range=(1, 2), lowercase=True, max_features=500)
    X_train_vec = vectorizer.fit_transform(X_train)
    X_test_vec = vectorizer.transform(X_test)

    # Train Logistic Regression Model
    clf = LogisticRegression(C=1.0, max_iter=200, random_state=42)
    clf.fit(X_train_vec, y_train)

    y_pred = clf.predict(X_test_vec)

    # Evaluation Metrics
    acc = float(accuracy_score(y_test, y_pred))
    precision, recall, f1, _ = precision_recall_fscore_support(y_test, y_pred, average='weighted', zero_division=0)
    precision = float(precision)
    recall = float(recall)
    f1 = float(f1)

    labels = sorted(list(set(y_train + y_test)))
    cm = confusion_matrix(y_test, y_pred, labels=labels).tolist()

    print("\n--- LOCAL INTENT CLASSIFIER EVALUATION REPORT ---")
    print(f"Accuracy : {acc:.4f}")
    print(f"Precision: {precision:.4f}")
    print(f"Recall   : {recall:.4f}")
    print(f"F1 Score : {f1:.4f}\n")
    print("Classification Report:")
    print(classification_report(y_test, y_pred, zero_division=0))
    print("Confusion Matrix:")
    print(cm)

    # Convert vocabulary keys and integer indices to standard Python dict
    vocab = {k: int(v) for k, v in vectorizer.vocabulary_.items()}
    idf = [float(x) for x in vectorizer.idf_]
    classes = [str(c) for c in clf.classes_]
    coef = [[float(val) for val in row] for row in clf.coef_]
    intercept = [float(x) for x in clf.intercept_]

    exported_model = {
        "vocabulary": vocab,
        "idf": idf,
        "classes": classes,
        "coef": coef,
        "intercept": intercept,
        "metrics": {
            "accuracy": acc,
            "precision": precision,
            "recall": recall,
            "f1_score": f1,
            "test_sample_count": len(test_data),
            "confusion_matrix": cm
        }
    }

    model_export_path = os.path.join(server_nlp_dir, 'intent_model.json')
    with open(model_export_path, 'w', encoding='utf-8') as f:
        json.dump(exported_model, f, indent=2)

    print(f"\nModel exported successfully to {model_export_path}")

if __name__ == '__main__':
    main()
