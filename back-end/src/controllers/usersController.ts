import type { Response, NextFunction } from "express";
import { User } from "../models/User.js";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/errors.js";
import type { AuthRequest } from "../middleware/auth.js";
import {
  legacyProfileUploadsDir,
  profileUploadsDir,
  writeProfileImage,
  writeProfileImageFile
} from "../utils/userProfileImage.js";
import { mapUser } from "../utils/userMapper.js";
import fs from "fs";
import path from "path";
import bcrypt from "bcryptjs";

type MulterAuthRequest = AuthRequest & { file?: Express.Multer.File };

export async function getMe(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await User.findById(req.user!.id);
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }
    return sendSuccess(res, "Profile loaded", mapUser(user));
  } catch (err) {
    return next(err);
  }
}

export async function updateMe(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await User.findByIdAndUpdate(
      req.user!.id,
      {
        ...(req.body.name ? { name: req.body.name } : {}),
        ...(req.body.phone ? { phone: req.body.phone } : {}),
        ...(req.body.society ? { society: req.body.society } : {}),
        ...(req.body.building ? { building: req.body.building } : {}),
        ...(req.body.apartment ? { apartment: req.body.apartment } : {})
      },
      { new: true }
    );
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }
    return sendSuccess(res, "Profile updated", mapUser(user));
  } catch (err) {
    return next(err);
  }
}

export async function uploadProfileImage(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await User.findById(req.user!.id);
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }
    const imagePayload = req.body.image;
    if (!imagePayload) {
      throw new AppError("Profile image is required", 400, "BAD_REQUEST");
    }
    if (user.profileImage?.filename) {
      const existingPath = path.join(profileUploadsDir, user.profileImage.filename);
      if (fs.existsSync(existingPath)) {
        fs.unlinkSync(existingPath);
      }
    }
    user.profileImage = writeProfileImage(imagePayload);
    await user.save();
    return sendSuccess(res, "Profile image updated", mapUser(user));
  } catch (err) {
    return next(err);
  }
}

export async function getProfileImage(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const targetId = req.params.id;
    const user = await User.findById(targetId);
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }
    if (!user.profileImage?.filename) {
      throw new AppError("Profile image not found", 404, "NOT_FOUND");
    }
    let filePath = path.join(profileUploadsDir, user.profileImage.filename);
    if (!fs.existsSync(filePath)) {
      const legacyPath = path.join(legacyProfileUploadsDir, user.profileImage.filename);
      if (fs.existsSync(legacyPath)) {
        filePath = legacyPath;
      }
    }
    if (!fs.existsSync(filePath)) {
      throw new AppError("Profile image missing", 404, "NOT_FOUND");
    }
    res.setHeader("Content-Type", user.profileImage.mimeType ?? "application/octet-stream");
    res.setHeader(
      "Content-Disposition",
      `inline; filename="${user.profileImage.originalName ?? "profile-image"}"`
    );
    return res.sendFile(filePath);
  } catch (err) {
    return next(err);
  }
}

export async function listUsers(_req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const users = await User.find().sort({ createdAt: -1 });
    return sendSuccess(res, "Users loaded", users.map(mapUser));
  } catch (err) {
    return next(err);
  }
}

export async function getUser(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }
    return sendSuccess(res, "User loaded", mapUser(user));
  } catch (err) {
    return next(err);
  }
}

export async function createUser(req: MulterAuthRequest, res: Response, next: NextFunction) {
  try {
    const existing = await User.findOne({ email: req.body.email });
    if (existing) {
      throw new AppError("Account already exists", 409, "ACCOUNT_EXISTS");
    }

    const passwordHash = await bcrypt.hash(req.body.password, 12);
    const profileImage = req.file ? writeProfileImageFile(req.file) : undefined;

    const user = await User.create({
      accountType: req.body.accountType,
      name: req.body.name,
      email: req.body.email,
      phone: req.body.phone,
      passwordHash,
      society: req.body.society,
      building: req.body.building,
      apartment: req.body.apartment,
      profileImage,
      termsAcceptedAt: new Date()
    });

    return sendSuccess(res, "User created", mapUser(user));
  } catch (err) {
    return next(err);
  }
}

export async function updateUser(req: MulterAuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }

    if (req.body.email && req.body.email !== user.email) {
      const existing = await User.findOne({ email: req.body.email });
      if (existing && existing._id.toString() !== user._id.toString()) {
        throw new AppError("Account already exists", 409, "ACCOUNT_EXISTS");
      }
    }

    user.accountType = req.body.accountType ?? user.accountType;
    user.name = req.body.name ?? user.name;
    user.email = req.body.email ?? user.email;
    user.phone = req.body.phone ?? user.phone;
    user.society = req.body.society ?? user.society;
    user.building = req.body.building ?? user.building;
    user.apartment = req.body.apartment ?? user.apartment;
    if (typeof req.body.isBanned === "boolean") {
      user.isBanned = req.body.isBanned;
    }
    if (typeof req.body.lateFeePercent === "number") {
      user.lateFeePercent = req.body.lateFeePercent;
    }

    if (req.body.password) {
      user.passwordHash = await bcrypt.hash(req.body.password, 12);
    }

    if (req.file) {
      if (user.profileImage?.filename) {
        const existingPath = path.join(profileUploadsDir, user.profileImage.filename);
        if (fs.existsSync(existingPath)) {
          fs.unlinkSync(existingPath);
        }
      }
      user.profileImage = writeProfileImageFile(req.file);
    }

    await user.save();
    return sendSuccess(res, "User updated", mapUser(user));
  } catch (err) {
    return next(err);
  }
}

export async function updateUserStatus(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }

    if (typeof req.body.isBanned === "boolean") {
      user.isBanned = req.body.isBanned;
    }
    if (typeof req.body.lateFeePercent === "number") {
      user.lateFeePercent = req.body.lateFeePercent;
    }

    await user.save();
    return sendSuccess(res, "User status updated", mapUser(user));
  } catch (err) {
    return next(err);
  }
}

export async function updateUserFromAuth(req: MulterAuthRequest, res: Response, next: NextFunction) {
  try {
    const targetId = req.params.id;
    if (req.user!.accountType !== "admin_driver" && req.user!.id !== targetId) {
      throw new AppError("Not authorized", 403, "FORBIDDEN");
    }
    const user = await User.findById(targetId);
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }

    user.name = req.body.name ?? user.name;
    user.phone = req.body.phone ?? user.phone;
    user.society = req.body.society ?? user.society;
    user.building = req.body.building ?? user.building;
    user.apartment = req.body.apartment ?? user.apartment;

    if (req.file) {
      if (user.profileImage?.filename) {
        const existingPath = path.join(profileUploadsDir, user.profileImage.filename);
        if (fs.existsSync(existingPath)) {
          fs.unlinkSync(existingPath);
        }
      }
      user.profileImage = writeProfileImageFile(req.file);
    }

    await user.save();
    return sendSuccess(res, "User updated", mapUser(user));
  } catch (err) {
    return next(err);
  }
}

export async function deleteUser(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }
    if (user.profileImage?.filename) {
      const existingPath = path.join(profileUploadsDir, user.profileImage.filename);
      if (fs.existsSync(existingPath)) {
        fs.unlinkSync(existingPath);
      }
    }
    await user.deleteOne();
    return sendSuccess(res, "User deleted");
  } catch (err) {
    return next(err);
  }
}
