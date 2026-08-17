import {useEffect, useState} from 'react';
import type {FaceState} from './LocalLLMFace';

/** Total unified memory on this machine, in bytes (M5, 32 GB). */
export const TOTAL_RAM = 32 * 1024 ** 3;

export type LoadedModel = {
  name: string;
  sizeVram: number;
  contextLength: number;
  parameterSize: string;
  quantization: string;
  family: string;
  expiresAt: string;
};

export type ServiceState = 'up' | 'down' | 'unknown';

export type LiveStatus = {
  ollama: ServiceState;
  ollamaVersion: string | null;
  searxng: ServiceState;
  model: LoadedModel | null;
  /** Seconds until Ollama unloads the model, or null when nothing is loaded. */
  unloadsIn: number | null;
  lastUpdated: Date | null;
  face: FaceState;
};

const INITIAL: LiveStatus = {
  ollama: 'unknown',
  ollamaVersion: null,
  searxng: 'unknown',
  model: null,
  unloadsIn: null,
  lastUpdated: null,
  face: 'idle',
};

async function getJSON(url: string, timeoutMs = 2500): Promise<unknown | null> {
  const abort = new AbortController();
  const timer = setTimeout(() => abort.abort(), timeoutMs);
  try {
    const res = await fetch(url, {signal: abort.signal});
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

/** Polls the local services and reports what is actually running. */
export function useLiveStatus(intervalMs = 2000): LiveStatus {
  const [status, setStatus] = useState<LiveStatus>(INITIAL);

  useEffect(() => {
    let cancelled = false;

    const tick = async () => {
      const [ps, version, searx] = await Promise.all([
        getJSON('/svc/ollama/api/ps'),
        getJSON('/svc/ollama/api/version'),
        getJSON('/svc/searxng/config'),
      ]);
      if (cancelled) return;

      const ollamaUp = ps !== null;
      const entry = (ps as {models?: unknown[]} | null)?.models?.[0] as
        | Record<string, never>
        | undefined;

      let model: LoadedModel | null = null;
      let unloadsIn: number | null = null;

      if (entry) {
        const details = (entry['details'] ?? {}) as Record<string, string>;
        model = {
          name: String(entry['name'] ?? 'unknown'),
          sizeVram: Number(entry['size_vram'] ?? entry['size'] ?? 0),
          contextLength: Number(entry['context_length'] ?? 0),
          parameterSize: details['parameter_size'] ?? '—',
          quantization: details['quantization_level'] ?? '—',
          family: details['family'] ?? '—',
          expiresAt: String(entry['expires_at'] ?? ''),
        };
        const expiry = Date.parse(model.expiresAt);
        if (!Number.isNaN(expiry)) {
          unloadsIn = Math.max(0, Math.round((expiry - Date.now()) / 1000));
        }
      }

      // The browser cannot see llama-server's CPU, so it cannot distinguish
      // "generating" from "ready" — only what is observably true.
      const face: FaceState = !ollamaUp ? 'error' : model ? 'listening' : 'idle';

      setStatus({
        ollama: ollamaUp ? 'up' : 'down',
        ollamaVersion:
          (version as {version?: string} | null)?.version ?? null,
        searxng: searx !== null ? 'up' : 'down',
        model,
        unloadsIn,
        lastUpdated: new Date(),
        face,
      });
    };

    void tick();
    const id = setInterval(tick, intervalMs);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, [intervalMs]);

  return status;
}

export function formatGB(bytes: number): string {
  return `${(bytes / 1024 ** 3).toFixed(1)} GB`;
}

export function formatCountdown(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return m > 0 ? `${m}m ${s}s` : `${s}s`;
}
