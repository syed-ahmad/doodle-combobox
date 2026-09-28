// features/clipboard/config/defaultClipboardColumnSanitizers.ts
import type { ColumnSanitizerMap } from '../core/types';
import {
  flattenLineBreaks,
  collapseWhitespace,
  trimValue,
} from '../sanitizers';

export const defaultClipboardColumnSanitizers: ColumnSanitizerMap = {
  description: [flattenLineBreaks, collapseWhitespace, trimValue],
  notes: [flattenLineBreaks, collapseWhitespace, trimValue],
  comments: [flattenLineBreaks, collapseWhitespace, trimValue],
};
