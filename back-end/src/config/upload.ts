import fs from "fs";
import path from "path";
import multer from "multer";
import { v4 as uuidv4 } from "uuid";
import { AppError } from "../utils/errors.js";

const uploadRoot = path.join(process.cwd(), "uploads");
const profileDir = path.join(uploadRoot, "profiles");
const reportDir = path.join(uploadRoot, "reports");

function ensureDir(dir: string) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

ensureDir(profileDir);
ensureDir(reportDir);

function makeStorage(targetDir: string) {
  return multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, targetDir),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase();
      cb(null, `${uuidv4()}${ext}`);
    }
  });
}

function allowMimeTypes(allowed: string[]) {
  return (_req: Express.Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    const ok = allowed.some((rule) =>
      rule.endsWith("/") ? file.mimetype.startsWith(rule) : file.mimetype === rule
    );
    if (ok) {
      cb(null, true);
    } else {
      cb(new AppError("Unsupported file type", 400, "UNSUPPORTED_MEDIA"));
    }
  };
}

export const uploadProfilePhoto = multer({
  storage: makeStorage(profileDir),
  fileFilter: allowMimeTypes(["image/"]),
  limits: { fileSize: 8 * 1024 * 1024 }
});

export const uploadReportAttachment = multer({
  storage: makeStorage(reportDir),
  fileFilter: allowMimeTypes(["image/", "application/pdf"]),
  limits: { fileSize: 12 * 1024 * 1024 }
});
