import { useState, useCallback, useRef } from 'react';
import { MODES } from '../constants/modes';

// In dev, Vite proxies /api → localhost:11434. In production, hit Ollama directly.
const OLLAMA_URL = import.meta.env.DEV ? '/api/chat' : 'http://localhost:11434/api/chat';
const MODEL = 'glm4:9b';

export default function useOllama() {
  const [messages, setMessages] = useState([]);
  const [streaming, setStreaming] = useState(false);
  const [error, setError] = useState(null);
  const abortRef = useRef(null);

  const send = useCallback(async (text, modeId = 'balanced') => {
    const mode = MODES.find((m) => m.id === modeId) || MODES[1];
    setError(null);
    setStreaming(true);

    const userMsg = { role: 'user', content: text };
    const history = [...messages, userMsg];
    setMessages(history);

    const apiMessages = [];
    if (mode.systemPrompt) {
      apiMessages.push({ role: 'system', content: mode.systemPrompt });
    }
    apiMessages.push(...history);

    const assistantMsg = { role: 'assistant', content: '' };

    try {
      abortRef.current = new AbortController();

      const res = await fetch(OLLAMA_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: MODEL,
          messages: apiMessages,
          stream: true,
          options: { temperature: mode.temperature },
        }),
        signal: abortRef.current.signal,
      });

      if (!res.ok) {
        throw new Error(`Ollama responded with ${res.status}`);
      }

      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (!line.trim()) continue;
          try {
            const chunk = JSON.parse(line);
            if (chunk.message?.content) {
              assistantMsg.content += chunk.message.content;
              setMessages([...history, { ...assistantMsg }]);
            }
          } catch {
            // skip malformed line
          }
        }
      }

      // Process any remaining buffer
      if (buffer.trim()) {
        try {
          const chunk = JSON.parse(buffer);
          if (chunk.message?.content) {
            assistantMsg.content += chunk.message.content;
          }
        } catch {
          // skip
        }
      }

      setMessages([...history, { ...assistantMsg }]);
    } catch (err) {
      if (err.name === 'AbortError') return;
      setError(err.message);
      // Still add a placeholder so the UI stays consistent
      setMessages([...history, { role: 'assistant', content: '[Error: could not reach Ollama]' }]);
    } finally {
      setStreaming(false);
      abortRef.current = null;
    }
  }, [messages]);

  const abort = useCallback(() => {
    abortRef.current?.abort();
  }, []);

  const clear = useCallback(() => {
    setMessages([]);
    setError(null);
  }, []);

  return { messages, streaming, error, send, abort, clear };
}
