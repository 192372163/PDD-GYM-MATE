const fs = require('fs');
const path = require('path');

class NLPEngine {
  constructor() {
    this.modelData = null;
    this.loadModel();
  }

  /**
   * Loads exported TF-IDF + Logistic Regression model weights
   */
  loadModel() {
    try {
      const modelPath = path.join(__dirname, 'intent_model.json');
      if (fs.existsSync(modelPath)) {
        const raw = fs.readFileSync(modelPath, 'utf8');
        this.modelData = JSON.parse(raw);
        console.log('[NLPEngine] Successfully loaded local intent classification model.');
      } else {
        console.warn('[NLPEngine] Warning: intent_model.json not found. Rule-based NLP fallback active.');
      }
    } catch (e) {
      console.error('[NLPEngine] Error loading local intent model:', e.message);
    }
  }

  /**
   * Tokenizes text and cleans punctuation
   * @param {string} text 
   * @returns {Array<string>}
   */
  tokenize(text) {
    if (!text) return [];
    return text.toLowerCase()
      .replace(/[^\w\s]/gi, ' ')
      .split(/\s+/)
      .filter(t => t.length > 0);
  }

  /**
   * Extracts unigrams and bigrams from tokens
   * @param {Array<string>} tokens 
   */
  getNgrams(tokens) {
    const ngrams = [...tokens];
    for (let i = 0; i < tokens.length - 1; i++) {
      ngrams.push(`${tokens[i]} ${tokens[i+1]}`);
    }
    return ngrams;
  }

  /**
   * Predicts intent and confidence score using exported TF-IDF + Logistic Regression weights
   * @param {string} text 
   */
  predictIntent(text) {
    const lower = text.toLowerCase();
    const tokens = this.tokenize(text);
    const ngrams = this.getNgrams(tokens);

    if (this.modelData && this.modelData.vocabulary && this.modelData.coef) {
      const vocab = this.modelData.vocabulary;
      const idf = this.modelData.idf;
      const classes = this.modelData.classes;
      const coef = this.modelData.coef;
      const intercept = this.modelData.intercept;

      // Count term frequencies
      const tfMap = new Map();
      for (const ng of ngrams) {
        if (vocab.hasOwnProperty(ng)) {
          const idx = vocab[ng];
          tfMap.set(idx, (tfMap.get(idx) || 0) + 1);
        }
      }

      // Compute vector dot products
      const scores = new Array(classes.length).fill(0);
      for (let c = 0; c < classes.length; c++) {
        scores[c] = intercept[c] || 0;
        tfMap.forEach((tf, idx) => {
          const tfidf = (1 + Math.log(tf)) * (idf[idx] || 1);
          scores[c] += tfidf * (coef[c][idx] || 0);
        });
      }

      // Softmax probabilities
      const maxScore = Math.max(...scores);
      const exps = scores.map(s => Math.exp(s - maxScore));
      const sumExps = exps.reduce((a, b) => a + b, 0);
      const probs = exps.map(e => e / sumExps);

      let maxIdx = 0;
      for (let i = 1; i < probs.length; i++) {
        if (probs[i] > probs[maxIdx]) maxIdx = i;
      }

      const predictedClass = classes[maxIdx];
      const confidence = parseFloat(probs[maxIdx].toFixed(4));

      if (confidence >= 0.25) {
        return { intent: predictedClass, confidence };
      }
    }

    // Rule-based fallback heuristics
    if (/workout|exercise|routine|gym|chest|leg|back|shoulder|arm|bicep|tricep|hiit|cardio|abs|squat/i.test(lower)) {
      return { intent: 'workout_request', confidence: 0.85 };
    }
    if (/diet|food|eat|nutrition|meal|calorie|protein|fat|macro|keto|carb/i.test(lower)) {
      return { intent: 'diet_plan_request', confidence: 0.85 };
    }
    if (/water|hydrate|hydration|drink|liter/i.test(lower)) {
      return { intent: 'water_intake_inquiry', confidence: 0.90 };
    }
    if (/bmi|tdee|weight loss|gain weight|target weight|progress|ideal weight/i.test(lower)) {
      return { intent: 'progress_tracking', confidence: 0.80 };
    }
    if (/sore|pain|recovery|rest|stiff|sleep|injury/i.test(lower)) {
      return { intent: 'recovery_advice', confidence: 0.85 };
    }
    if (/motivation|demotivated|lazy|struggling|inspire/i.test(lower)) {
      return { intent: 'motivation', confidence: 0.90 };
    }
    if (/hi|hello|hey|good morning|greetings/i.test(lower)) {
      return { intent: 'greeting', confidence: 0.95 };
    }
    if (/thank|thanks|helpful|great|good|bad|not working/i.test(lower)) {
      return { intent: 'feedback', confidence: 0.75 };
    }

    return { intent: 'other', confidence: 0.50 };
  }

  /**
   * Extracts entities from text
   * @param {string} text 
   */
  extractEntities(text) {
    const lower = text.toLowerCase();
    const entities = {};

    // Body Part
    const bodyParts = ['chest', 'leg', 'legs', 'back', 'shoulder', 'shoulders', 'arm', 'arms', 'bicep', 'biceps', 'tricep', 'triceps', 'abs', 'core'];
    for (const part of bodyParts) {
      if (lower.includes(part)) {
        entities.bodyPart = part.replace(/s$/, ''); // normalize plural
        break;
      }
    }

    // Weight metric
    const weightMatch = lower.match(/\b(\d+(?:\.\d+)?)\s*(kg|lbs|pounds|kilograms)\b/);
    if (weightMatch) {
      entities.weight = `${weightMatch[1]} ${weightMatch[2]}`;
    }

    // Height metric
    const heightMatch = lower.match(/\b(\d+(?:\.\d+)?)\s*(cm|feet|ft|inches)\b/);
    if (heightMatch) {
      entities.height = `${heightMatch[1]} ${heightMatch[2]}`;
    }

    // Target Date
    if (lower.includes('tomorrow')) entities.date = 'tomorrow';
    else if (lower.includes('today')) entities.date = 'today';
    else if (lower.includes('next week')) entities.date = 'next week';

    // Caloric / Macro target
    const calMatch = lower.match(/\b(\d+)\s*(calories|kcal)\b/);
    if (calMatch) {
      entities.calories = parseInt(calMatch[1]);
    }

    // Fitness Goal
    if (lower.includes('weight loss') || lower.includes('fat loss') || lower.includes('lose weight')) {
      entities.fitnessGoal = 'weight loss';
    } else if (lower.includes('muscle gain') || lower.includes('bulk') || lower.includes('build muscle')) {
      entities.fitnessGoal = 'muscle gain';
    }

    return entities;
  }

  /**
   * Sentiment Analysis (Positive, Negative, Neutral)
   * @param {string} text 
   */
  analyzeSentiment(text) {
    const lower = text.toLowerCase();
    const posWords = ['great', 'awesome', 'good', 'happy', 'love', 'thanks', 'thank', 'helpful', 'excited', 'crush', 'ready'];
    const negWords = ['bad', 'sad', 'frustrated', 'sore', 'pain', 'demotivated', 'hard', 'tired', 'slow', 'struggling', 'stuck', 'hate'];

    let score = 0;
    for (const w of posWords) {
      if (lower.includes(w)) score += 1;
    }
    for (const w of negWords) {
      if (lower.includes(w)) score -= 1;
    }

    if (score > 0) return 'positive';
    if (score < 0) return 'negative';
    return 'neutral';
  }

  /**
   * Full NLP Pipeline execution
   * @param {string} message 
   */
  process(message) {
    const tokens = this.tokenize(message);
    const intentResult = this.predictIntent(message);
    const entities = this.extractEntities(message);
    const sentiment = this.analyzeSentiment(message);

    return {
      user_message: message,
      tokens,
      intent: intentResult.intent,
      confidence: intentResult.confidence,
      sentiment,
      entities,
      context_required: true
    };
  }
}

module.exports = new NLPEngine();
