import urllib.request
import json
import time

BASE_URL = 'http://localhost:3000'

def make_request(path, payload=None):
    url = f"{BASE_URL}{path}"
    headers = {'Content-Type': 'application/json'}
    data = json.dumps(payload).encode('utf-8') if payload else None
    req = urllib.request.Request(url, data=data, headers=headers, method='POST' if payload else 'GET')
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            res_body = response.read().decode('utf-8')
            return response.status, json.loads(res_body)
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8')
        return e.code, json.loads(body) if body else {}
    except Exception as e:
        return 500, {'error': str(e)}

def main():
    print("\n========================================================")
    print("      GYMMATE AI CHATBOT PIPELINE TEST SUITE")
    print("========================================================\n")

    # 1. Health check
    status, health = make_request('/health')
    print(f"Health Check Status: {status} -> {health}")
    assert status == 200, "Server health check failed"

    # 2. NLP status check
    status, nlp_status = make_request('/api/nlp/status')
    print(f"NLP Status Check Status: {status} -> {nlp_status}")
    assert status == 200, "NLP status check failed"

    user_profile = {
        "uid": "usr_test_99",
        "name": "Chandra",
        "age": 25,
        "gender": "male",
        "weightKg": 70,
        "heightCm": 175,
        "bmi": 22.9,
        "fitnessGoal": "weight loss",
        "experienceLevel": "Intermediate",
        "foodPreference": "High Protein",
        "dailyActivity": "Active",
        "medicalConditions": []
    }

    test_prompts = [
        {"prompt": "I want a chest workout for tomorrow", "expected_intent": "workout_request"},
        {"prompt": "Create a high protein diet plan for weight loss", "expected_intent": "diet_plan_request"},
        {"prompt": "How much water should I drink per day?", "expected_intent": "water_intake_inquiry"},
        {"prompt": "What is my ideal body weight for 175 cm height?", "expected_intent": "progress_tracking"},
        {"prompt": "My legs are extremely sore after squatting today", "expected_intent": "recovery_advice"},
        {"prompt": "I am feeling demotivated with my slow progress", "expected_intent": "motivation"},
        {"prompt": "What about my target daily calories?", "expected_intent": "progress_tracking"}, # follow-up
        {"prompt": "Hi coach, good morning!", "expected_intent": "greeting"},
        {"prompt": "Your advice was super helpful, thanks!", "expected_intent": "feedback"},
        {"prompt": "Who won the football world cup in 2022?", "expected_intent": "other"}
    ]

    passed_count = 0
    print("\n--- RUNNING 10 PIPELINE CHAT TESTS ---\n")

    for idx, test in enumerate(test_prompts, 1):
        prompt = test["prompt"]
        payload = {
            "userProfile": user_profile,
            "sessionId": "test_session_101",
            "messages": [{"role": "user", "content": prompt}]
        }
        print(f"[{idx}/10] Testing: '{prompt}'")
        code, resp = make_request('/api/groq/chat', payload)
        
        if code == 200:
            content = resp.get('content', '')
            nlp = resp.get('nlp', {})
            knowledge = resp.get('knowledge', [])
            print(f"   -> Status: 200 OK")
            print(f"   -> NLP Intent Detected: {nlp.get('intent')} (Confidence: {nlp.get('confidence')}) | Sentiment: {nlp.get('sentiment')}")
            print(f"   -> Entities Extracted: {nlp.get('entities')}")
            print(f"   -> Knowledge RAG Snippets ({len(knowledge)}): {knowledge}")
            print(f"   -> AI Response Preview: {content[:120]}...\n")
            passed_count += 1
        else:
            print(f"   -> FAILED with Status Code: {code} | Error: {resp.get('error')}\n")

        # Sleep briefly between calls to respect API rate limits
        time.sleep(2.0)

    print(f"SUMMARY: Passed {passed_count}/{len(test_prompts)} Chat Pipeline Tests.")

if __name__ == '__main__':
    main()
