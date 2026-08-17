import './face.css';

/** Every state the on-device model can be in. */
export type FaceState =
  // conversational — core white
  | 'idle'
  | 'greeting'
  | 'listening'
  | 'thinking'
  | 'speaking'
  | 'confused'
  | 'curious'
  | 'happy'
  // system / utility — blue, hardware or transport work
  | 'loading'
  | 'scanning'
  | 'transfer'
  | 'sync'
  // failure — red, and only here
  | 'error';

export const FACE_STATES: ReadonlyArray<{state: FaceState; caption: string}> = [
  {state: 'idle', caption: 'You can try asking me'},
  {state: 'greeting', caption: 'Nice to meet you!'},
  {state: 'listening', caption: "I'm listening"},
  {state: 'thinking', caption: 'Working that out…'},
  {state: 'speaking', caption: 'Here is what I found'},
  {state: 'confused', caption: 'Please say that again'},
  {state: 'curious', caption: 'Tell me more'},
  {state: 'happy', caption: 'Glad that helped'},
  {state: 'loading', caption: 'Loading weights'},
  {state: 'scanning', caption: 'Scanning repository'},
  {state: 'transfer', caption: 'Transferring'},
  {state: 'sync', caption: 'Syncing index'},
  {state: 'error', caption: 'Seems to be malfunctioning…'},
];

/* Chamfered brackets: corners cut at 45°, never rounded. */
const LEFT_BRACKET = 'M12 2 L5.5 2 L2 5.5 L2 30.5 L5.5 34 L12 34';
const RIGHT_BRACKET = 'M2 2 L8.5 2 L12 5.5 L12 30.5 L8.5 34 L2 34';

type Props = {
  state?: FaceState;
  /** Rendered height in px. Everything else scales from this. */
  size?: number;
  className?: string;
};

export function LocalLLMFace({state = 'idle', size = 34, className}: Props) {
  return (
    <span
      className={className ? `lf ${className}` : 'lf'}
      data-state={state}
      style={{['--lf-h' as string]: `${size}px`}}
      role="img"
      aria-label={`Model status: ${state}`}
    >
      <svg className="lf-brk lf-brk-l" viewBox="0 0 14 36" fill="none" aria-hidden="true">
        <path
          d={LEFT_BRACKET}
          stroke="currentColor"
          strokeWidth="2.6"
          strokeLinecap="square"
          strokeLinejoin="miter"
        />
      </svg>

      <span className="lf-eyes">
        <span className="lf-dot lf-dot-a" />
        <span className="lf-dot lf-dot-b" />
      </span>

      <svg className="lf-brk lf-brk-r" viewBox="0 0 14 36" fill="none" aria-hidden="true">
        <path
          d={RIGHT_BRACKET}
          stroke="currentColor"
          strokeWidth="2.6"
          strokeLinecap="square"
          strokeLinejoin="miter"
        />
      </svg>

      <span className="lf-sonar" aria-hidden="true" />
      <span className="lf-bar" aria-hidden="true" />
    </span>
  );
}

export default LocalLLMFace;
