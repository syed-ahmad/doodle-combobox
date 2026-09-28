// features/clipboard/sanitizers/flattenLineBreaks.ts
export const flattenLineBreaks = (value: unknown): string =>
  String(value ?? '').replace(/\r?\n|\r/g, ' ');

// features/clipboard/sanitizers/collapseWhitespace.ts
export const collapseWhitespace = (value: unknown): string =>
  String(value ?? '').replace(/\s+/g, ' ');

// features/clipboard/sanitizers/trimValue.ts
export const trimValue = (value: unknown): string =>
  String(value ?? '').trim();
