import { motion, AnimatePresence } from 'framer-motion';
import { FACE_STATES } from '../../constants/faceStates';
import FaceEyes from './FaceEyes';
import StateLabel from './StateLabel';
import './RobotFace.css';

function PairingBars() {
  return (
    <div className="pairing-bars">
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <motion.div
          key={i}
          className="pairing-bar"
          animate={{ scaleY: [0.4, 1, 0.4] }}
          transition={{
            duration: 0.8,
            delay: i * 0.1,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
      ))}
    </div>
  );
}

function RadarRings() {
  return (
    <div className="radar-container">
      {[0, 1, 2].map((i) => (
        <motion.div
          key={i}
          className="radar-ring"
          animate={{ scale: [0.3, 1.5], opacity: [0.8, 0] }}
          transition={{
            duration: 1.5,
            delay: i * 0.5,
            repeat: Infinity,
            ease: 'easeOut',
          }}
        />
      ))}
      <div className="radar-center" />
    </div>
  );
}

export default function RobotFace({ state = 'idle' }) {
  const config = FACE_STATES[state] || FACE_STATES.idle;
  const { brackets, dots, label } = config;

  const isRadar = dots.radar;
  const isPairing = dots.bars;
  const isMirrored = brackets.type === 'mirrored';
  const isNone = brackets.type === 'none';

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

  const getContainerAnim = () => {
    switch (state) {
      case 'thinking': return {
        x: [-3, 3, -3],
        transition: { duration: 2, ease: 'easeInOut', repeat: Infinity },
      };
      case 'error': return {
        x: [0, -8, 8, -8, 8, 0],
        transition: { duration: 0.4 },
      };
      case 'greeting': return {
        scale: [1, 1.12, 1],
        transition: { duration: 0.6, ease: 'easeOut' },
      };
      case 'listening': return {
        scale: [1, 1.04, 1],
        transition: { duration: 1.5, ease: 'easeInOut', repeat: Infinity },
      };
      case 'voice_portal':
      case 'transferring': return {
        scale: [1, 1.06, 1],
        transition: { duration: 2, ease: 'easeInOut', repeat: Infinity },
      };
      default: return breathe;
    }
  };

  const leftBracket = isMirrored ? ')' : '(';
  const rightBracket = isMirrored ? '(' : ')';
  const squeezeX = brackets.squeeze ? 10 : 0;

  const errorFlash = state === 'error' ? {
    opacity: [1, 0.3, 1, 0.3, 1],
    transition: { duration: 0.4 },
  } : {};

  return (
    <div className="robot-face-wrapper">
      <AnimatePresence mode="wait">
        <motion.div
          key={state}
          className="robot-face"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.15 }}
        >
          {isRadar ? (
            <RadarRings />
          ) : (
            <motion.div
              className="face-content"
              animate={getContainerAnim()}
            >
              {!isNone && (
                <motion.span
                  style={bracketStyle}
                  animate={{ x: squeezeX, ...errorFlash }}
                >
                  {leftBracket}
                </motion.span>
              )}

              <div className="face-inner">
                {isPairing ? (
                  <PairingBars />
                ) : dots.visible ? (
                  <FaceEyes
                    count={dots.count}
                    shrink={dots.shrink}
                    state={state}
                  />
                ) : null}
              </div>

              {!isNone && (
                <motion.span
                  style={bracketStyle}
                  animate={{ x: -squeezeX, ...errorFlash }}
                >
                  {rightBracket}
                </motion.span>
              )}
            </motion.div>
          )}
        </motion.div>
      </AnimatePresence>
      <StateLabel label={label} />
    </div>
  );
}
