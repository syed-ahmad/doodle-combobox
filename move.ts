// Mvoe ts
// features/clipboard/core/types.ts
export type ClipboardSanitizer = (value: unknown) => unknown;

export type ColumnSanitizerMap = Record<string, ClipboardSanitizer[]>;

export type ColumnSanitizerOverrides = Partial<ColumnSanitizerMap>;
