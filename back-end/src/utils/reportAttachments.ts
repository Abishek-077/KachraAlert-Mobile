import fs from "fs";
import path from "path";
import { randomUUID } from "crypto";
import { fileURLToPath } from "url";

const currentFilePath = fileURLToPath(import.meta.url);
const currentDir = path.dirname(currentFilePath);
const backendRootDir = path.resolve(currentDir, "..", "..");

export const reportUploadsDir = path.resolve(backendRootDir, "uploads", "reports");
export const legacyReportUploadsDir = path.resolve(process.cwd(), "uploads", "reports");

fs.mkdirSync(reportUploadsDir, { recursive: true });

type IncomingAttachment = {
  name: string;
  mimeType: string;
  dataBase64: string;
};

export function writeReportAttachment(attachment: IncomingAttachment) {
  const ext = path.extname(attachment.name);
  const filename = `${Date.now()}-${randomUUID()}${ext}`;
  const buffer = Buffer.from(attachment.dataBase64, "base64");
  const filePath = path.join(reportUploadsDir, filename);
  fs.writeFileSync(filePath, buffer);
  return {
    filename,
    originalName: attachment.name,
    mimeType: attachment.mimeType,
    size: buffer.length,
    uploadedAt: new Date()
  };
}
