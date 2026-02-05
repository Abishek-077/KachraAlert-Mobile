import multer from "multer";
import { AppError } from "../utils/errors.js";

const storage = multer.memoryStorage();

export const profileImageUpload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, callback) => {
    if (!file.mimetype.startsWith("image/")) {
      return callback(new AppError("Only image uploads are allowed", 400, "INVALID_FILE"));
    }
    return callback(null, true);
  }
});
