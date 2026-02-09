import fs from "fs";
import path from "path";
import { randomUUID } from "crypto";
import { fileURLToPath } from "url";

const currentFilePath = fileURLToPath(import.meta.url);
const currentDir = path.dirname(currentFilePath);
const backendRootDir = path.resolve(currentDir, "..", "..");

export const profileUploadsDir = path.resolve(backendRootDir, "uploads", "profiles");
export const legacyProfileUploadsDir = path.resolve(process.cwd(), "uploads", "profiles");

fs.mkdirSync(profileUploadsDir, { recursive: true });

type IncomingProfileImage = {
  name: string;
  mimeType: string;
  dataBase64: string;
};

type IncomingProfileImageFile = {
  originalname: string;
  mimetype: string;
  buffer: Buffer;
};

export function writeProfileImage(image: IncomingProfileImage) {
  const ext = path.extname(image.name);
  const filename = `${Date.now()}-${randomUUID()}${ext}`;
  const buffer = Buffer.from(image.dataBase64, "base64");
  const filePath = path.join(profileUploadsDir, filename);
  fs.writeFileSync(filePath, buffer);
  return {
    filename,
    originalName: image.name,
    mimeType: image.mimeType,
    size: buffer.length,
    uploadedAt: new Date()
  };
}

export function writeProfileImageFile(image: IncomingProfileImageFile) {
  const ext = path.extname(image.originalname);
  const filename = `${Date.now()}-${randomUUID()}${ext}`;
  const filePath = path.join(profileUploadsDir, filename);
  fs.writeFileSync(filePath, image.buffer);
  return {
    filename,
    originalName: image.originalname,
    mimeType: image.mimetype,
    size: image.buffer.length,
    uploadedAt: new Date()
  };
}

export function buildProfileImageUrl(userId: string) {
  return `/api/v1/users/${userId}/profile-image`;
}
