// features/clipboard/core/buildColumnSanitizerMap.ts
import type {
  ColumnSanitizerMap,
  ColumnSanitizerOverrides,
} from './types';

export const buildColumnSanitizerMap = (
  defaults: ColumnSanitizerMap,
  overrides?: ColumnSanitizerOverrides
): ColumnSanitizerMap => ({
  ...defaults,
  ...overrides,
});
