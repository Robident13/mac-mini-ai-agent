import { useMemo } from 'react';

const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\u03BC\u03C0\u03C3\u03B2\u03B1\u03B4\u03B8\u03BB';

export default function MatrixBackground() {
  const particles = useMemo(() => {
    return Array.from({ length: 80 }, (_, i) => ({
      char: CHARS[Math.floor(Math.random() * CHARS.length)],
      left: Math.random() * 100,
      top: Math.random() * 100,
      size: 10 + Math.random() * 4,
      delay: Math.random() * 12,
      duration: 8 + Math.random() * 7,
    }));
  }, []);

  return (
    <div
      aria-hidden="true"
      style={{
        position: 'fixed',
        inset: 0,
        overflow: 'hidden',
        pointerEvents: 'none',
        zIndex: 0,
      }}
    >
      {particles.map((p, i) => (
        <span
          key={i}
          className="matrix-char"
          style={{
            position: 'absolute',
            left: `${p.left}%`,
            top: `${p.top}%`,
            fontSize: `${p.size}px`,
            fontFamily: 'var(--font-mono)',
            color: '#fff',
            opacity: 0,
            animationDelay: `${p.delay}s`,
            animationDuration: `${p.duration}s`,
          }}
        >
          {p.char}
        </span>
      ))}
    </div>
  );
}
