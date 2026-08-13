const express = require('express');
const groqClient = require('./groqClient');
const nlpEngine = require('./nlp/nlpEngine');
const knowledgeRetriever = require('./nlp/knowledgeRetriever');
const contextManager = require('./nlp/contextManager');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// CORS headers for local development and Flutter integration
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
    return res.status(200).json({});
  }
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'GymMate AI Backend Server' });
});

// NLP Status and Diagnostics Endpoint
app.get('/api/nlp/status', (req, res) => {
  const modelLoaded = !!nlpEngine.modelData;
  const metrics = nlpEngine.modelData?.metrics || null;
  res.json({
    status: 'active',
    model_loaded: modelLoaded,
    classification_engine: modelLoaded ? 'TF-IDF + Logistic Regression' : 'Rule-Based Fallback',
    metrics: metrics
  });
});

// Server-side Groq Chat with NLP + Context + RAG Pipeline
app.post('/api/groq/chat', async (req, res) => {
  try {
    const { messages, userProfile, sessionId, model, temperature } = req.body;

    let userMessage = '';
    if (messages && Array.isArray(messages) && messages.length > 0) {
      userMessage = messages[messages.length - 1].content || '';
    }

    if (!userMessage.trim()) {
      return res.status(400).json({ error: 'Invalid request: "userMessage" or non-empty "messages" array is required.' });
    }

    const sid = sessionId || userProfile?.uid || 'default_session';

    // 1. Run NLP Processing Pipeline
    const nlpAnalysis = nlpEngine.process(userMessage);

    // 2. Retrieve Project Knowledge (RAG)
    const knowledgeSnippets = knowledgeRetriever.retrieveKnowledge(nlpAnalysis, userProfile);

    // 3. Retrieve & Update Conversation Context History
    const history = contextManager.getHistory(sid);

    // 4. Construct System Prompt
    const systemPrompt = groqClient.buildSystemPrompt(nlpAnalysis, userProfile, knowledgeSnippets);

    // 5. Construct Payload Messages for Groq API
    const finalMessages = [
      { role: 'system', content: systemPrompt },
      ...history,
      { role: 'user', content: userMessage }
    ];

    // 6. Invoke Groq LLM
    const completionText = await groqClient.generateChatCompletion(finalMessages, { model, temperature });

    // 7. Update Session History
    contextManager.addMessage(sid, 'user', userMessage);
    contextManager.addMessage(sid, 'assistant', completionText);

    // 8. Return Response to Client
    return res.json({
      content: completionText,
      nlp: nlpAnalysis,
      knowledge: knowledgeSnippets,
      session_id: sid
    });

  } catch (error) {
    console.error('[Server Error] Groq chat pipeline execution failed:', error.message);
    return res.status(500).json({ 
      error: error.message || 'Internal server error processing AI chatbot pipeline.' 
    });
  }
});

app.listen(PORT, () => {
  console.log(`[GymMate AI Server] Server running on port ${PORT}`);
});
