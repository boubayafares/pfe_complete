import { it, expect } from 'vitest';
import { existsSync, readFileSync, mkdtempSync, rmSync, createWriteStream } from 'fs';
import { tmpdir } from 'os';
import path from 'path';
import PDFDocument from 'pdfkit';

it('pdfkit is importable and can create documents', () => {
  const dir = mkdtempSync(path.join(tmpdir(), 'pdfkittest-'));
  const file = path.join(dir, 'sample.pdf');
  const doc = new PDFDocument();
  const stream = createWriteStream(file);
  doc.pipe(stream);
  doc.text('Hello FootTech');
  doc.end();
  return new Promise<void>((resolve) => {
    stream.on('finish', () => {
      try {
        expect(existsSync(file)).toBe(true);
        const bytes = readFileSync(file);
        expect(bytes.length).toBeGreaterThan(0);
        expect(bytes.subarray(0, 4).toString()).toBe('%PDF');
      } finally {
        rmSync(dir, { recursive: true, force: true });
      }
      resolve();
    });
  });
});
