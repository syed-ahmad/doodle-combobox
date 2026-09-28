// features/clipboard/hooks/useClipboardProcessor.ts
import { useMemo } from 'react';
import { defaultClipboardColumnSanitizers } from '../config/defaultClipboardColumnSanitizers';
import { buildColumnSanitizerMap } from '../core/buildColumnSanitizerMap';
import { createProcessCellForClipboard } from '../core/createProcessCellForClipboard';
import type {
  ColumnSanitizerMap,
  ColumnSanitizerOverrides,
} from '../core/types';

type UseClipboardProcessorOptions = {
  defaults?: ColumnSanitizerMap;
  overrides?: ColumnSanitizerOverrides;
};

export const useClipboardProcessor = (
  options: UseClipboardProcessorOptions = {}
) => {
  const {
    defaults = defaultClipboardColumnSanitizers,
    overrides,
  } = options;

  const columnSanitizerMap = useMemo(
    () => buildColumnSanitizerMap(defaults, overrides),
    [defaults, overrides]
  );

  const processCellForClipboard = useMemo(
    () => createProcessCellForClipboard(columnSanitizerMap),
    [columnSanitizerMap]
  );

  return { processCellForClipboard };
};
