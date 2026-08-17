import { forwardRef } from 'react';

const TextInput = forwardRef(function TextInput({ value, onChange, onSubmit }, ref) {
  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      onSubmit();
    }
  };

  return (
    <textarea
      ref={ref}
      className="chat-input"
      rows={1}
      placeholder="Ask anything..."
      value={value}
      onChange={(e) => onChange(e.target.value)}
      onKeyDown={handleKeyDown}
      aria-label="Message input"
    />
  );
});

export default TextInput;
