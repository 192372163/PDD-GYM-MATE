/**
 * GymMate AI Context Manager
 * Maintains sliding-window conversation history per user session.
 */

class ContextManager {
  constructor(maxHistory = 10) {
    this.maxHistory = maxHistory;
    // In-memory store: sessionId -> Array<{ role: string, content: string, timestamp: number }>
    this.sessions = new Map();
  }

  /**
   * Retrieves conversation history for a given sessionId
   * @param {string} sessionId 
   * @returns {Array<{role: string, content: string}>}
   */
  getHistory(sessionId) {
    if (!sessionId || !this.sessions.has(sessionId)) {
      return [];
    }
    return this.sessions.get(sessionId).map(msg => ({
      role: msg.role,
      content: msg.content
    }));
  }

  /**
   * Adds a message to the session history and trims to maxHistory
   * @param {string} sessionId 
   * @param {string} role ('user' | 'assistant')
   * @param {string} content 
   */
  addMessage(sessionId, role, content) {
    if (!sessionId) return;
    if (!this.sessions.has(sessionId)) {
      this.sessions.set(sessionId, []);
    }

    const history = this.sessions.get(sessionId);
    history.push({
      role,
      content,
      timestamp: Date.now()
    });

    if (history.length > this.maxHistory) {
      history.splice(0, history.length - this.maxHistory);
    }
  }

  /**
   * Clears session history
   * @param {string} sessionId 
   */
  clearSession(sessionId) {
    if (sessionId && this.sessions.has(sessionId)) {
      this.sessions.delete(sessionId);
    }
  }
}

module.exports = new ContextManager();
