import {useEffect, useRef, useState} from 'react';
import {Icon} from '@astryxdesign/core';
import {LocalLLMFace, type FaceState} from './LocalLLMFace';
import './fab.css';

type Action = {
  label: string;
  icon: 'menu' | 'search' | 'wrench' | 'arrowsUpDown' | 'microphone';
  onSelect: () => void;
};

type Props = {
  state: FaceState;
  actions: ReadonlyArray<Action>;
};

export function FaceFab({state, actions}: Props) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);

  // Click-away and Escape both close the dial.
  useEffect(() => {
    if (!open) return;

    const onPointerDown = (e: PointerEvent) => {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
    };
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false);
    };

    document.addEventListener('pointerdown', onPointerDown);
    document.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('pointerdown', onPointerDown);
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [open]);

  return (
    <div className="fab-root" ref={rootRef}>
      {open && (
        <div className="fab-menu" role="menu">
          {actions.map((action, i) => (
            <button
              key={action.label}
              type="button"
              role="menuitem"
              className="fab-item"
              style={{animationDelay: `${i * 40}ms`}}
              onClick={() => {
                action.onSelect();
                setOpen(false);
              }}
            >
              <span className="fab-item-label">{action.label}</span>
              <span className="fab-item-icon">
                <Icon icon={action.icon} size="sm" />
              </span>
            </button>
          ))}
        </div>
      )}

      <button
        type="button"
        className="fab-button"
        aria-expanded={open}
        aria-haspopup="menu"
        aria-label={open ? 'Close model actions' : 'Open model actions'}
        onClick={() => setOpen((v) => !v)}
      >
        <LocalLLMFace state={open ? 'curious' : state} size={30} />
      </button>
    </div>
  );
}

export default FaceFab;
