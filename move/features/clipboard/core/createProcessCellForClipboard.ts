// features/clipboard/core/createProcessCellForClipboard.ts
import { applySanitizers } from './applySanitizers';
import type { ColumnSanitizerMap } from './types';

type ProcessCellForClipboardParams = {
  value: unknown;
  column: {
    getColId: () => string;
  };
};

export const createProcessCellForClipboard = (
  columnSanitizerMap: ColumnSanitizerMap
) => {
  return (params: ProcessCellForClipboardParams): unknown => {
    const colId = params.column.getColId();
    const sanitizers = columnSanitizerMap[colId];

    if (!sanitizers?.length) {
      return params.value;
    }

    return applySanitizers(params.value, sanitizers);
  };
};
