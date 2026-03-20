export const MODES = [
  {
    id: 'quick',
    label: 'Quick answer',
    icon: '\u26A1',
    temperature: 0.3,
    systemPrompt: 'Be concise. Answer in 1-2 sentences when possible.',
  },
  {
    id: 'balanced',
    label: 'Balanced',
    icon: '\u2696\uFE0F',
    temperature: 0.7,
    systemPrompt: '',
  },
  {
    id: 'deepthink',
    label: 'DeepThink',
    icon: '\uD83D\uDCA1',
    temperature: 0.9,
    systemPrompt: 'Think step by step. Consider multiple angles before answering. Be thorough.',
  },
  {
    id: 'research',
    label: 'Research',
    icon: '\uD83D\uDD2C',
    temperature: 0.5,
    systemPrompt: 'Provide detailed, well-structured answers with evidence and reasoning.',
  },
];

export const DEFAULT_MODE = 'balanced';
