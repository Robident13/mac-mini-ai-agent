import { useState, useRef } from 'react';
import AttachButton from './AttachButton';
import ModeSelector from './ModeSelector';
import TextInput from './TextInput';
import VoiceButton from './VoiceButton';
import SendButton from './SendButton';
import './ChatBar.css';

export default function ChatBar({
  onSend,
  onVoiceToggle,
  voiceActive,
  currentMode,
  onModeChange,
  disabled,
}) {
  const [input, setInput] = useState('');
  const inputRef = useRef(null);

  const handleSend = () => {
    const text = input.trim();
    if (!text || disabled) return;
    onSend(text);
    setInput('');
    inputRef.current?.focus();
  };

  return (
    <div className="chatbar-wrapper">
      <div className="chatbar-glow" aria-hidden="true" />
      <div className="chatbar">
        <div className="chatbar-top">
          <AttachButton />
          <ModeSelector currentMode={currentMode} onModeChange={onModeChange} />
          <VoiceButton active={voiceActive} onToggle={onVoiceToggle} />
          <SendButton onClick={handleSend} disabled={disabled || !input.trim()} />
        </div>
        <TextInput
          ref={inputRef}
          value={input}
          onChange={setInput}
          onSubmit={handleSend}
        />
      </div>
    </div>
  );
}
