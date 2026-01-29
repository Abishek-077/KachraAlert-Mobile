import type { Response, NextFunction, Request } from "express";
import { User, type UserDocument } from "../models/User.js";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/errors.js";
import type { AuthRequest } from "../middleware/auth.js";
import { buildProfileImageUrl, profileUploadsDir, writeProfileImage } from "../utils/userProfileImage.js";
import fs from "fs";
import path from "path";

function mapUser(req: AuthRequest, user: UserDocument) {
  const profileImageUrl = user.profileImage?.filename ? buildProfileImageUrl(user._id.toString()) : null;

  return {
    id: user._id.toString(),
    accountType: user.accountType,
    name: user.name,
    email: user.email,
    phone: user.phone,
    society: user.society,
    building: user.building,
    apartment: user.apartment,

    // New
    profileImageUrl,
    // Legacy alias
    profilePhotoUrl: profileImageUrl
  };
}

export async function getMe(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await User.findById(req.user!.id);
    if (!user) throw new AppError("User not found", 404, "NOT_FOUND");

    return sendSuccess(res, "Profile loaded", mapUser(req, user));
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

    if (!user) throw new AppError("User not found", 404, "NOT_FOUND");

    return sendSuccess(res, "Profile updated", mapUser(req, user));
  } catch (err) {
    return next(err);
  }
}

export async function uploadProfileImage(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await User.findById(req.user!.id);
    if (!user) throw new AppError("User not found", 404, "NOT_FOUND");

    const imagePayload = req.body.image;
    if (!imagePayload) throw new AppError("Profile image is required", 400, "BAD_REQUEST");

    if (user.profileImage?.filename) {
      const existingPath = path.join(profileUploadsDir, user.profileImage.filename);
      if (fs.existsSync(existingPath)) fs.unlinkSync(existingPath);
    }

    user.profileImage = writeProfileImage(imagePayload);
    await user.save();

    return sendSuccess(res, "Profile image updated", mapUser(req, user));
  } catch (err) {
    return next(err);
  }
}

export async function getProfileImage(req: Request, res: Response, next: NextFunction) {
  try {
    const targetId = req.params.id;

    const user = await User.findById(targetId);
    if (!user) throw new AppError("User not found", 404, "NOT_FOUND");

    if (!user.profileImage?.filename) {
      throw new AppError("Profile image not found", 404, "NOT_FOUND");
    }

    const filePath = path.join(profileUploadsDir, user.profileImage.filename);
    if (!fs.existsSync(filePath)) {
      throw new AppError("Profile image missing", 404, "NOT_FOUND");
    }

    res.setHeader("Content-Type", user.profileImage.mimeType);
    res.setHeader("Content-Disposition", `inline; filename="${user.profileImage.originalName}"`);
    return res.sendFile(filePath);
  } catch (err) {
    return next(err);
  }
}

export async function listUsers(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const users = await User.find().sort({ createdAt: -1 });
    return sendSuccess(res, "Users loaded", users.map((user) => mapUser(req, user)));
  } catch (err) {
    return next(err);
  }
}

export async function getUser(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await User.findById(req.params.id);
    if (!user) throw new AppError("User not found", 404, "NOT_FOUND");

    return sendSuccess(res, "User loaded", mapUser(req, user));
  } catch (err) {
    return next(err);
  }
}
