export default function NeonIcon({ color, children, size = 24 }) {
  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: color,
        filter: `drop-shadow(0 0 6px ${color})`,
        opacity: 0.9,
        transition: 'all 0.2s ease',
        width: size,
        height: size,
      }}
      className="neon-icon"
    >
      {children}
    </span>
  );
}
