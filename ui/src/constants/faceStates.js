export const FACE_STATES = {
  idle: {
    label: '',
    brackets: { type: 'normal', squeeze: 0 },
    dots: { visible: true, count: 2 },
  },
  greeting: {
    label: 'Nice to meet you!',
    brackets: { type: 'normal', squeeze: 0 },
    dots: { visible: true, count: 2 },
  },
  listening: {
    label: 'I am listening\u2026',
    brackets: { type: 'normal', squeeze: 0 },
    dots: { visible: true, count: 2 },
  },
  thinking: {
    label: '',
    brackets: { type: 'normal', squeeze: 1 },
    dots: { visible: true, count: 2, shrink: true },
  },
  error: {
    label: 'Error!',
    brackets: { type: 'normal', squeeze: 0 },
    dots: { visible: true, count: 2 },
  },
  malfunction: {
    label: 'Seems to be malfunctioning\u2026',
    brackets: { type: 'normal', squeeze: 0 },
    dots: { visible: true, count: 2 },
  },
  repeat: {
    label: 'Please say that again.',
    brackets: { type: 'normal', squeeze: 0 },
    dots: { visible: true, count: 2 },
  },
  prompt: {
    label: 'You can try asking me',
    brackets: { type: 'normal', squeeze: 0 },
    dots: { visible: true, count: 2 },
  },
  upgrading: {
    label: 'I am upgrading\u2026',
    brackets: { type: 'normal', squeeze: 0 },
    dots: { visible: true, count: 2 },
  },
  bluetooth: {
    label: 'Trying to connect to Bluetooth\u2026',
    brackets: { type: 'normal', squeeze: 0 },
    dots: { visible: true, count: 2 },
  },
  loading: {
    label: 'Loading\u2026',
    brackets: { type: 'normal', squeeze: 0 },
    dots: { visible: true, count: 1 },
  },
  voice_portal: {
    label: 'Voice Portal',
    brackets: { type: 'mirrored', squeeze: 0 },
    dots: { visible: false, count: 0 },
  },
  pairing: {
    label: 'Enter The Pairing Code',
    brackets: { type: 'normal', squeeze: 0 },
    dots: { visible: false, count: 0, bars: true },
  },
  searching: {
    label: 'Search For Hardware\u2026',
    brackets: { type: 'none', squeeze: 0 },
    dots: { visible: false, count: 0, radar: true },
  },
  transferring: {
    label: 'Transferring\u2026',
    brackets: { type: 'mirrored', squeeze: 0 },
    dots: { visible: false, count: 0 },
  },
};
