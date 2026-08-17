import { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { MODES } from '../../constants/modes';

export default function ModeSelector({ currentMode, onModeChange }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);
  const current = MODES.find((m) => m.id === currentMode) || MODES[1];

  useEffect(() => {
    const handleClick = (e) => {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  return (
    <div className="mode-selector" ref={ref}>
      <button
        className="chat-btn mode-btn"
        type="button"
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        aria-haspopup="listbox"
      >
        <span className="mode-icon">{current.icon}</span>
        <span className="mode-label">{current.label}</span>
        <svg
          width="12"
          height="12"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          style={{
            transform: open ? 'rotate(180deg)' : 'rotate(0deg)',
            transition: 'transform 0.2s',
          }}
        >
          <polyline points="6 9 12 15 18 9" />
        </svg>
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            className="mode-dropdown"
            role="listbox"
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 8 }}
            transition={{ duration: 0.15 }}
          >
            {MODES.map((mode) => (
              <button
                key={mode.id}
                role="option"
                type="button"
                aria-selected={mode.id === currentMode}
                className={`mode-option ${mode.id === currentMode ? 'active' : ''}`}
                onClick={() => {
                  onModeChange(mode.id);
                  setOpen(false);
                }}
              >
                <span>{mode.icon}</span>
                <span>{mode.label}</span>
              </button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
