import { motion } from 'framer-motion';

export default function SendButton({ onClick, disabled }) {
  return (
    <motion.button
      className="send-btn"
      type="submit"
      onClick={onClick}
      disabled={disabled}
      aria-label="Send message"
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
    >
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <line x1="22" y1="2" x2="11" y2="13" />
        <polygon points="22 2 15 22 11 13 2 9 22 2" />
      </svg>
    </motion.button>
  );
}
