import fs from "fs";
import path from "path";
import { randomUUID } from "crypto";

export const profileUploadsDir = path.resolve(process.cwd(), "uploads", "profiles");

fs.mkdirSync(profileUploadsDir, { recursive: true });

type IncomingProfileImage = {
  name: string;
  mimeType: string;
  dataBase64: string;
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

export function buildProfileImageUrl(userId: string) {
  return `/api/v1/users/${userId}/profile-image`;
}
