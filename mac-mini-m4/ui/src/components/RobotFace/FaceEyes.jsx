import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';

export default function FaceEyes({ count, shrink, state }) {
  const [blinking, setBlinking] = useState(false);

  useEffect(() => {
    if (state !== 'idle' && state !== 'greeting' && state !== 'prompt') return;
    const scheduleBlink = () => {
      const delay = 4000 + Math.random() * 3000;
      const timer = setTimeout(() => {
        setBlinking(true);
        setTimeout(() => setBlinking(false), 150);
        scheduleBlink();
      }, delay);
      return timer;
    };
    const timer = scheduleBlink();
    return () => clearTimeout(timer);
  }, [state]);

  const dotSize = shrink ? 8 : 14;
  const dotOpacity = shrink ? 0.5 : 1;

  const listeningAnim = {
    y: [0, -4, 0, 4, 0],
    transition: { duration: 1.5, ease: 'easeInOut', repeat: Infinity },
  };

  const thinkingAnim = {
    scale: [1, 0.6, 1],
    opacity: [1, 0.5, 1],
    transition: { duration: 2, ease: 'easeInOut', repeat: Infinity },
  };

  const getEyeAnimation = (index) => {
    if (blinking) return { scaleY: 0.1, transition: { duration: 0.08 } };
    if (state === 'listening') return {
      ...listeningAnim,
      transition: {
        ...listeningAnim.transition,
        delay: index * 0.2,
      },
    };
    if (state === 'thinking') return thinkingAnim;
    if (state === 'error') return {
      opacity: index === 1 ? [1, 0, 1] : 1,
      transition: { duration: 0.3, delay: 0.1 },
    };
    return {};
  };

  if (count === 0) return null;

  const dots = Array.from({ length: count }, (_, i) => i);

  return (
    <div style={{
      display: 'flex',
      gap: count === 1 ? '0' : '32px',
      alignItems: 'center',
      justifyContent: 'center',
      position: 'absolute',
      left: '50%',
      top: '50%',
      transform: 'translate(-50%, -50%)',
    }}>
      {dots.map((_, i) => (
        <motion.div
          key={i}
          animate={getEyeAnimation(i)}
          style={{
            width: `${dotSize}px`,
            height: `${dotSize}px`,
            borderRadius: '50%',
            backgroundColor: 'var(--text-primary)',
            opacity: dotOpacity,
          }}
        />
      ))}
    </div>
  );
}
