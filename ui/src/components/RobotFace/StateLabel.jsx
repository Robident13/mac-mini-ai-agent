import { motion, AnimatePresence } from 'framer-motion';

export default function StateLabel({ label }) {
  return (
    <div style={{ height: '24px', marginTop: '16px', textAlign: 'center' }}>
      <AnimatePresence mode="wait">
        {label && (
          <motion.p
            key={label}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.2, delay: 0.15 }}
            style={{
              fontFamily: 'var(--font-mono)',
              fontSize: '13px',
              letterSpacing: '0.05em',
              color: 'var(--text-secondary)',
              margin: 0,
            }}
          >
            {label}
          </motion.p>
        )}
      </AnimatePresence>
    </div>
  );
}
