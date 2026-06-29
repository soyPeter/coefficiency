function formatDate(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

export function fmtCsv(n: number, decimals = 2): string {
  return n.toFixed(decimals).replace('.', ',');
}

function toCsv(rows: Record<string, unknown>[], columns: string[]): string {
  const delim = ';';
  const header = columns.join(delim);
  const data = rows.map(r =>
    columns.map(c => {
      const v = r[c];
      if (v == null) return '';
      const s = String(v);
      return s.includes(delim) || s.includes('"') || s.includes('\n') ? `"${s.replace(/"/g, '""')}"` : s;
    }).join(delim)
  );
  return header + '\n' + data.join('\n');
}

function download(filename: string, csv: string) {
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export function downloadCsv(filename: string, rows: Record<string, unknown>[], columns: string[]) {
  const csv = toCsv(rows, columns);
  download(filename, csv);
}

export function downloadMultiSectionCsv(filename: string, sections: { title: string; rows: Record<string, unknown>[]; columns: string[] }[]) {
  const parts: string[] = [];
  const delim = ';';
  for (const s of sections) {
    if (s.rows.length === 0) continue;
    parts.push(`"${s.title}"`);
    parts.push(s.columns.join(delim));
    for (const row of s.rows) {
      parts.push(s.columns.map(c => {
        const v = row[c];
        if (v == null) return '';
        const sv = String(v);
        return sv.includes(delim) || sv.includes('"') || sv.includes('\n') ? `"${sv.replace(/"/g, '""')}"` : sv;
      }).join(delim));
    }
    parts.push('');
  }
  download(filename, parts.join('\n'));
}
