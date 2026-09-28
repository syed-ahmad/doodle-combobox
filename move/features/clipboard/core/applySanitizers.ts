// features/clipboard/core/applySanitizers.ts
import type { ClipboardSanitizer } from './types';

export const applySanitizers = (
  value: unknown,
  sanitizers: ClipboardSanitizer[] = []
): unknown =>
  sanitizers.reduce((current, sanitizer) => sanitizer(current), value);
