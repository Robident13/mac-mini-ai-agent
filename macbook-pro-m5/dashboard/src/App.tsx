import {useState} from 'react';
import {
  AppShell,
  SideNav,
  SideNavHeading,
  SideNavItem,
  LayoutContent,
  Card,
  Stack,
  Text,
  StatusDot,
  ProgressBar,
  Divider,
  Icon,
} from '@astryxdesign/core';
import {LocalLLMFace, FACE_STATES, type FaceState} from './LocalLLMFace';
import {FaceFab} from './FaceFab';
import {
  useLiveStatus,
  formatGB,
  formatCountdown,
  TOTAL_RAM,
  type ServiceState,
} from './useLiveStatus';
import './face.css';

const NAV = {
  Overview: 'info',
  Models: 'viewColumns',
  Logs: 'search',
  Settings: 'wrench',
} as const;

type NavItem = keyof typeof NAV;

const GRID: React.CSSProperties = {
  display: 'grid',
  gridTemplateColumns: 'repeat(auto-fit, minmax(290px, 1fr))',
  gap: 16,
  width: '100%',
};

const FACE_GRID: React.CSSProperties = {
  display: 'grid',
  gridTemplateColumns: 'repeat(auto-fill, minmax(150px, 1fr))',
  gap: 12,
  width: '100%',
};

function serviceVariant(s: ServiceState) {
  return s === 'up' ? 'success' : s === 'down' ? 'error' : 'neutral';
}

function serviceLabel(s: ServiceState) {
  return s === 'up' ? 'Running' : s === 'down' ? 'Unreachable' : 'Checking…';
}

export default function App() {
  const [nav, setNav] = useState<NavItem>('Overview');
  const [previewState, setPreviewState] = useState<FaceState | null>(null);
  const live = useLiveStatus();

  // The gallery can override the face for a look; otherwise it tracks reality.
  const faceState = previewState ?? live.face;
  const navKeys = Object.keys(NAV) as NavItem[];

  const modelBytes = live.model?.sizeVram ?? 0;
  const modelPct = Math.round((modelBytes / TOTAL_RAM) * 100);

  return (
    <AppShell
      sideNav={
        <SideNav
          header={
            <SideNavHeading
              heading="Local Agent"
              subheading="On-device model"
              icon={<Icon icon="viewColumns" size="md" />}
            />
          }
          collapsible={{defaultIsCollapsed: false, hasButton: true}}
          resizable={{defaultWidth: 248, minWidth: 200, maxWidth: 400}}
        >
          <Stack gap={1} paddingBlock={4} direction="vertical">
            <Stack paddingInline={4} paddingBlock={2}>
              <Text type="supporting" color="secondary">
                Navigate
              </Text>
            </Stack>
            {navKeys.map((label) => (
              <SideNavItem
                key={label}
                label={label}
                icon={NAV[label]}
                isSelected={nav === label}
                onClick={() => setNav(label)}
              />
            ))}
          </Stack>
        </SideNav>
      }
    >
      <LayoutContent padding={8} label="Dashboard">
        <Stack gap={8} direction="vertical">
          {/* ── header ─────────────────────────────────────── */}
          <Stack direction="horizontal" vAlign="center" justify="between" gap={6}>
            <Stack direction="vertical" gap={2}>
              <Text type="display-3">Local Agent Dashboard</Text>
              <Text type="supporting" color="secondary">
                {live.model
                  ? `${live.model.name} · ${live.model.parameterSize} · ${live.model.quantization}`
                  : 'No model resident — click the face to load it'}
              </Text>
            </Stack>
            <Stack direction="horizontal" gap={3} vAlign="center">
              <LocalLLMFace state={faceState} size={30} />
              <Stack direction="vertical" gap={0.5}>
                <Text type="supporting">
                  {previewState ? 'Previewing state' : 'Live'}
                </Text>
                <Text type="supporting" color="secondary">
                  {live.lastUpdated
                    ? `updated ${live.lastUpdated.toLocaleTimeString()}`
                    : 'connecting…'}
                </Text>
              </Stack>
            </Stack>
          </Stack>

          <Divider />

          {/* ── live cards ─────────────────────────────────── */}
          <div style={GRID}>
            <Card padding={6}>
              <Stack direction="vertical" gap={5}>
                <Text type="label">Model</Text>
                <Stack direction="vertical" gap={4}>
                  <Row
                    label="Resident"
                    value={live.model ? 'Loaded' : 'Not loaded'}
                    variant={live.model ? 'success' : 'neutral'}
                  />
                  <Row
                    label="Context window"
                    value={
                      live.model?.contextLength
                        ? live.model.contextLength.toLocaleString()
                        : '—'
                    }
                    variant="neutral"
                  />
                  <Row
                    label="Architecture"
                    value={live.model?.family ?? '—'}
                    variant="neutral"
                  />
                  <Row
                    label="Unloads in"
                    value={
                      live.unloadsIn !== null
                        ? formatCountdown(live.unloadsIn)
                        : '—'
                    }
                    variant={
                      live.unloadsIn !== null && live.unloadsIn < 60
                        ? 'warning'
                        : 'neutral'
                    }
                  />
                </Stack>
              </Stack>
            </Card>

            <Card padding={6}>
              <Stack direction="vertical" gap={5}>
                <Text type="label">Services</Text>
                <Stack direction="vertical" gap={4}>
                  <Row
                    label="Ollama"
                    value={
                      live.ollamaVersion
                        ? `v${live.ollamaVersion}`
                        : serviceLabel(live.ollama)
                    }
                    variant={serviceVariant(live.ollama)}
                  />
                  <Row
                    label="SearXNG"
                    value={serviceLabel(live.searxng)}
                    variant={serviceVariant(live.searxng)}
                  />
                  <Row label="Dashboard" value="Running" variant="success" />
                </Stack>
              </Stack>
            </Card>

            <Card padding={6}>
              <Stack direction="vertical" gap={5}>
                <Stack direction="horizontal" justify="between" vAlign="center">
                  <Text type="label">Unified memory</Text>
                  <Text type="supporting" color="secondary">
                    32 GB total
                  </Text>
                </Stack>
                <Stack direction="vertical" gap={4}>
                  <Stack direction="vertical" gap={2}>
                    <Stack direction="horizontal" justify="between" vAlign="center">
                      <Text type="supporting">Model weights</Text>
                      <Text type="supporting" color="secondary">
                        {live.model ? formatGB(modelBytes) : '0 GB'}
                      </Text>
                    </Stack>
                    <ProgressBar
                      label="Model memory"
                      isLabelHidden
                      value={modelPct}
                      variant={modelPct > 60 ? 'warning' : 'accent'}
                    />
                  </Stack>
                  <Text type="supporting" color="secondary">
                    {live.model
                      ? `${formatGB(TOTAL_RAM - modelBytes)} left for everything else`
                      : 'Full 32 GB available'}
                  </Text>
                </Stack>
              </Stack>
            </Card>
          </div>

          {/* ── face system ────────────────────────────────── */}
          <Stack direction="vertical" gap={4}>
            <Stack direction="horizontal" gap={3} vAlign="center" justify="between">
              <Stack direction="horizontal" gap={3} vAlign="center">
                <Text type="label">Face system</Text>
                <Text type="supporting" color="secondary">
                  {previewState
                    ? 'previewing — pick again to return to live'
                    : 'tracking live state'}
                </Text>
              </Stack>
              {previewState && (
                <button
                  type="button"
                  onClick={() => setPreviewState(null)}
                  style={{
                    all: 'unset',
                    cursor: 'pointer',
                    padding: '4px 10px',
                    borderRadius: 6,
                    border: '1px solid rgba(255,255,255,.18)',
                    fontSize: 12,
                  }}
                >
                  Back to live
                </button>
              )}
            </Stack>

            <div style={FACE_GRID}>
              {FACE_STATES.map(({state, caption}) => {
                const isActive = state === faceState;
                return (
                  <Card
                    key={state}
                    padding={5}
                    variant={isActive ? 'muted' : 'default'}
                    elevation={isActive ? 'low' : 'none'}
                  >
                    <button
                      type="button"
                      onClick={() =>
                        setPreviewState((cur) => (cur === state ? null : state))
                      }
                      aria-pressed={isActive}
                      style={{
                        all: 'unset',
                        cursor: 'pointer',
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        gap: 14,
                        width: '100%',
                      }}
                    >
                      <LocalLLMFace state={state} size={34} />
                      <Text
                        type="supporting"
                        color={isActive ? 'primary' : 'secondary'}
                      >
                        {caption}
                      </Text>
                    </button>
                  </Card>
                );
              })}
            </div>
          </Stack>
        </Stack>
      </LayoutContent>

      <FaceFab
        state={faceState}
        actions={[
          {
            label: 'Load model',
            icon: 'menu',
            onSelect: () => {
              void fetch('/svc/ollama/api/generate', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({
                  model: 'qwen3.6-moe-64k',
                  prompt: '',
                  keep_alive: '5m',
                }),
              });
              setPreviewState(null);
            },
          },
          {
            label: 'Unload model',
            icon: 'wrench',
            onSelect: () => {
              void fetch('/svc/ollama/api/generate', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({
                  model: 'qwen3.6-moe-64k',
                  keep_alive: 0,
                }),
              });
              setPreviewState(null);
            },
          },
          {
            label: 'Open SearXNG',
            icon: 'search',
            onSelect: () => window.open('http://127.0.0.1:8899', '_blank'),
          },
        ]}
      />
    </AppShell>
  );
}

function Row({
  label,
  value,
  variant,
}: {
  label: string;
  value: string;
  variant: 'success' | 'warning' | 'error' | 'accent' | 'neutral';
}) {
  return (
    <Stack direction="horizontal" gap={3} vAlign="center" justify="between">
      <Stack direction="horizontal" gap={3} vAlign="center">
        <StatusDot variant={variant} label={label} />
        <Text type="body">{label}</Text>
      </Stack>
      <Text type="supporting" color="secondary">
        {value}
      </Text>
    </Stack>
  );
}
