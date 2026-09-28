// components/DataGrid/DataGrid.tsx
import { AgGridReact } from 'ag-grid-react';
import type {
  ColDef,
  ProcessCellForExportParams,
} from 'ag-grid-community';

type DataGridProps<TData> = {
  rowData: TData[];
  columnDefs: ColDef<TData>[];
  processCellForClipboard: (params: ProcessCellForExportParams<TData>) => unknown;
};

export function DataGrid<TData>({
  rowData,
  columnDefs,
  processCellForClipboard,
}: DataGridProps<TData>) {
  return (
    <AgGridReact<TData>
      rowData={rowData}
      columnDefs={columnDefs}
      processCellForClipboard={processCellForClipboard}
      rowSelection={{
        mode: 'multiRow',
        copySelectedRows: true,
      }}
    />
  );
}

// Example usage
// const { processCellForClipboard } = useClipboardProcessor({
//   overrides: {
//     description: [flattenLineBreaks, trimValue],
//     auditComment: [flattenLineBreaks, collapseWhitespace, trimValue],
//   },
// });
