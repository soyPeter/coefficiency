import { useState, useCallback } from 'react';
import { Upload, FileText, CheckCircle2, XCircle, Trash2 } from 'lucide-react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useFileUpload } from '@/hooks/use-file-upload';
import { uploadFile } from '@/api';
import type { ImportResult } from '@/types';

export default function FileImportPage() {
  const intl = useIntl();
  const [result, setResult] = useState<ImportResult | null>(null);
  const [uploading, setUploading] = useState(false);

  const handleFilesAdded = useCallback((files: { file: File; id: string }[]) => {
    if (files.length === 0) return;
    setUploading(true);
    setResult(null);
    const file = files[0].file as File;
    uploadFile(file)
      .then((res) => setResult(res))
      .catch((err) => setResult({ success: false, count: 0, message: err.message || intl.formatMessage({ id: 'import.uploadError' }) }))
      .finally(() => setUploading(false));
  }, [intl]);

  const [state, actions] = useFileUpload({
    accept: '.csv',
    multiple: false,
    onFilesAdded: handleFilesAdded,
  });

  const { isDragging, files, errors } = state;
  const { handleDragEnter, handleDragLeave, handleDragOver, handleDrop, openFileDialog, getInputProps, removeFile } = actions;

  return (
    <div className="p-5">
      <h1 className="text-2xl font-bold mb-6"><FormattedMessage id="import.title" /></h1>
      <p className="text-sm text-muted-foreground mb-8"><FormattedMessage id="import.subtitle" /></p>

      <Card>
        <CardContent className="p-6">
          <div
            className={`relative border-2 border-dashed rounded-lg p-12 text-center transition-colors ${
              isDragging ? 'border-primary bg-primary/5' : 'border-muted-foreground/25 hover:border-muted-foreground/50'
            }`}
            onDragEnter={handleDragEnter}
            onDragLeave={handleDragLeave}
            onDragOver={handleDragOver}
            onDrop={handleDrop}
          >
            <input {...getInputProps()} className="hidden" />
            <div className="flex flex-col items-center gap-3">
              <div className="p-3 rounded-full bg-muted">
                <Upload className="size-6 text-muted-foreground" />
              </div>
              <div>
                <p className="font-medium"><FormattedMessage id="import.dropzone" /></p>
                <p className="text-sm text-muted-foreground mt-1"><FormattedMessage id="import.dropzoneHint" /></p>
              </div>
              <Button variant="secondary" onClick={openFileDialog} disabled={uploading}>
                <FileText className="size-4" /> <FormattedMessage id="import.browse" />
              </Button>
              <p className="text-xs text-muted-foreground"><FormattedMessage id="import.csvOnly" /></p>
            </div>
          </div>

          {errors.length > 0 && (
            <div className="mt-4 p-3 bg-destructive/10 text-destructive rounded-md text-sm">
              {errors.map((e, i) => <p key={i}>{e}</p>)}
            </div>
          )}

          {files.length > 0 && (
            <div className="mt-4 space-y-2">
              {files.map((f) => (
                <div key={f.id} className="flex items-center justify-between p-3 bg-muted/50 rounded-md">
                  <div className="flex items-center gap-2">
                    <FileText className="size-4 text-muted-foreground" />
                    <span className="text-sm">{f.file.name}</span>
                    <span className="text-xs text-muted-foreground">
                      ({(f.file.size / 1024).toFixed(1)} KB)
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    {uploading && <span className="text-xs text-muted-foreground"><FormattedMessage id="import.uploading" /></span>}
                    <Button variant="ghost" size="sm" onClick={() => removeFile(f.id)} disabled={uploading}>
                      <Trash2 className="size-3.5" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}

          {result && (
            <div className={`mt-4 p-4 rounded-md flex items-start gap-3 ${result.success ? 'bg-emerald-500/10 text-emerald-700' : 'bg-destructive/10 text-destructive'}`}>
              {result.success ? <CheckCircle2 className="size-5 mt-0.5" /> : <XCircle className="size-5 mt-0.5" />}
              <div>
                <p className="font-medium">{result.success ? <FormattedMessage id="import.success" /> : <FormattedMessage id="import.failed" />}</p>
                <p className="text-sm mt-1">{result.message}</p>
                {result.count > 0 && <p className="text-sm mt-1"><FormattedMessage id="import.imported" values={{ count: result.count }} /></p>}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <Card className="mt-6">
        <CardHeader>
          <CardTitle className="text-base"><FormattedMessage id="import.format" /></CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground mb-3"><FormattedMessage id="import.formatHelp" /></p>
          <div className="bg-muted/50 p-3 rounded-md font-mono text-xs whitespace-pre-wrap">
            <FormattedMessage id="import.formatExample" />
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
