import multer from 'multer';
import path from 'path';
import { randomUUID } from 'crypto';
import { env } from '../config/env.js';
import { BadRequestError } from '../shared/errors/AppError.js';

const ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
const EXTENSIONS: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};
// Some Web/mobile clients (e.g. Dio/Firebase) send the part without a
// content-type, which multer reports as application/octet-stream. Tolerate it
// when the original filename has a valid image extension.
const ALLOWED_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp']);

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, env.UPLOAD_DIR),
  filename: (_req, file, cb) => cb(null, `${randomUUID()}${EXTENSIONS[file.mimetype] ?? path.extname(file.originalname).toLowerCase()}`),
});

const upload = multer({
  storage,
  limits: { fileSize: env.MAX_UPLOAD_MB * 1024 * 1024, files: 1 },
  fileFilter: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const isImageMime = ALLOWED_MIME_TYPES.has(file.mimetype);
    const isImageByExtension = file.mimetype === 'application/octet-stream' && ALLOWED_EXTENSIONS.has(ext);
    if (isImageMime || isImageByExtension) {
      cb(null, true);
      return;
    }
    cb(new BadRequestError('Only JPEG, PNG and WebP images are allowed') as unknown as Error);
  },
});

export const uploadSingle = (field: string) => upload.single(field);
