import multer from 'multer';
import path from 'path';
import { randomUUID } from 'crypto';
import { readFile, unlink } from 'fs/promises';
import type { NextFunction, Request, RequestHandler, Response } from 'express';
import { env } from '../config/env.js';
import { BadRequestError } from '../shared/errors/AppError.js';

const ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
const EXTENSIONS: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, env.UPLOAD_DIR),
  filename: (_req, file, cb) => cb(null, `${randomUUID()}${EXTENSIONS[file.mimetype] ?? path.extname(file.originalname).toLowerCase()}`),
});

const upload = multer({
  storage,
  limits: { fileSize: env.MAX_UPLOAD_MB * 1024 * 1024, files: 1 },
  fileFilter: (_req, file, cb) => {
    if (ALLOWED_MIME_TYPES.has(file.mimetype)) {
      cb(null, true);
      return;
    }
    cb(new BadRequestError('Only JPEG, PNG and WebP images are allowed') as unknown as Error);
  },
});

function hasExpectedSignature(bytes: Buffer, mimeType: string): boolean {
  if (mimeType === 'image/jpeg') {
    return bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
  }
  if (mimeType === 'image/png') {
    return bytes.length >= 8 && bytes.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]));
  }
  if (mimeType === 'image/webp') {
    return bytes.length >= 12 && bytes.subarray(0, 4).toString('ascii') === 'RIFF' && bytes.subarray(8, 12).toString('ascii') === 'WEBP';
  }
  return false;
}

/** Multer plus a post-write magic-byte check; claimed MIME/extension is not trusted. */
export const uploadSingle = (field: string): RequestHandler => {
  const multerHandler = upload.single(field);
  return (req: Request, res: Response, next: NextFunction) => {
    multerHandler(req, res, (error) => {
      if (error) return next(error);
      if (!req.file) return next();

      void readFile(req.file.path)
        .then(async (bytes) => {
          if (!hasExpectedSignature(bytes, req.file!.mimetype)) {
            await unlink(req.file!.path).catch(() => undefined);
            throw new BadRequestError('Uploaded file content is not a valid JPEG, PNG or WebP image');
          }
          next();
        })
        .catch(next);
    });
  };
};
