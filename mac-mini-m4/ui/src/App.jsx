import { useState, useRef, useEffect } from 'react';
import MatrixBackground from './components/MatrixBackground';
import RobotFace from './components/RobotFace/RobotFace';
import ChatBar from './components/ChatBar/ChatBar';
import useOllama from './hooks/useOllama';
import { DEFAULT_MODE } from './constants/modes';
import './tokens.css';
import './App.css';

export default function App() {
  const { messages, streaming, error, send } = useOllama();
  const [faceState, setFaceState] = useState('idle');
  const [voiceActive, setVoiceActive] = useState(false);
  const [mode, setMode] = useState(DEFAULT_MODE);
  const chatEndRef = useRef(null);

  // Drive face state from Ollama status
  useEffect(() => {
    if (error) {
      setFaceState('error');
      const timer = setTimeout(() => setFaceState('idle'), 2000);
      return () => clearTimeout(timer);
    }
    if (streaming) {
      setFaceState('thinking');
    } else if (messages.length === 0) {
      setFaceState('greeting');
      const timer = setTimeout(() => setFaceState('idle'), 3000);
      return () => clearTimeout(timer);
    } else {
      setFaceState('idle');
    }
  }, [streaming, error, messages.length]);

  // Auto-scroll messages
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = (text) => {
    send(text, mode);
  };

  const handleVoiceToggle = () => {
    setVoiceActive((v) => !v);
    setFaceState((s) => (s === 'listening' ? 'idle' : 'listening'));
  };

  return (
    <div className="app">
      <MatrixBackground />

      <main className="app-main">
        <RobotFace state={faceState} />

        {messages.length > 0 && (
          <div className="messages">
            {messages.map((msg, i) => (
              <div key={i} className={`message message-${msg.role}`}>
                <div className="message-bubble">
                  {msg.content || (streaming && msg.role === 'assistant' ? '\u2588' : '')}
                </div>
              </div>
            ))}
            <div ref={chatEndRef} />
          </div>
        )}

        <ChatBar
          onSend={handleSend}
          onVoiceToggle={handleVoiceToggle}
          voiceActive={voiceActive}
          currentMode={mode}
          onModeChange={setMode}
          disabled={streaming}
        />
      </main>
    </div>
  );
}
