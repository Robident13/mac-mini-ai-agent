import { motion } from 'framer-motion';

export default function FaceBrackets({ type, squeeze, state }) {
  const ismirrored = type === 'mirrored';

  const bracketStyle = {
    fontSize: '96px',
    fontWeight: 300,
    fontFamily: 'var(--font-mono)',
    color: 'var(--text-primary)',
    lineHeight: 1,
    userSelect: 'none',
  };

  const breathe = {
    scale: [1, 1.03, 1],
    transition: { duration: 3, ease: 'easeInOut', repeat: Infinity },
  };

  const thinking = {
    x: squeeze ? [-2, 2, -2] : 0,
    transition: { duration: 2, ease: 'easeInOut', repeat: Infinity },
  };

  const errorShake = {
    x: [0, -8, 8, -8, 8, 0],
    opacity: [1, 0.3, 1, 0.3, 1],
    transition: { duration: 0.4 },
  };

  const greetExpand = {
    scale: [1, 1.15, 1],
    transition: { duration: 0.6, ease: 'easeOut' },
  };

  const portalPulse = {
    scale: [1, 1.06, 1],
    transition: { duration: 2, ease: 'easeInOut', repeat: Infinity },
  };

  const getAnimation = () => {
    switch (state) {
      case 'idle': return breathe;
      case 'thinking': return thinking;
      case 'error': return errorShake;
      case 'greeting': return greetExpand;
      case 'voice_portal':
      case 'transferring': return portalPulse;
      case 'listening': return {
        scale: [1, 1.05, 1],
        transition: { duration: 1.5, ease: 'easeInOut', repeat: Infinity },
      };
      default: return breathe;
    }
  };

  const leftBracket = ismirrored ? ')' : '(';
  const rightBracket = ismirrored ? '(' : ')';

  const squeezeAmount = squeeze ? 8 : 0;

  return (
    <motion.div
      animate={getAnimation()}
      style={{ display: 'flex', alignItems: 'center', gap: 0 }}
    >
      <motion.span
        animate={{ x: squeezeAmount }}
        transition={{ duration: 1.5, ease: 'easeInOut' }}
        style={bracketStyle}
      >
        {leftBracket}
      </motion.span>
      <div style={{ width: '120px', display: 'flex', justifyContent: 'center' }}>
        {/* Eyes/content injected via children in RobotFace */}
      </div>
      <motion.span
        animate={{ x: -squeezeAmount }}
        transition={{ duration: 1.5, ease: 'easeInOut' }}
        style={bracketStyle}
      >
        {rightBracket}
      </motion.span>
    </motion.div>
  );
}
