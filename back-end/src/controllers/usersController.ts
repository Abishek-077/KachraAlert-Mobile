import type { Response, NextFunction } from "express";
import { User, type UserDocument } from "../models/User.js";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/errors.js";
import { toPublicUrl } from "../utils/publicUrl.js";
import type { AuthRequest } from "../middleware/auth.js";

function mapUser(req: AuthRequest, user: UserDocument) {
  return {
    id: user._id.toString(),
    accountType: user.accountType,
    name: user.name,
    email: user.email,
    phone: user.phone,
    society: user.society,
    building: user.building,
    apartment: user.apartment,
    profilePhotoUrl: toPublicUrl(req, user.profilePhotoUrl)
  };
}

export async function getMe(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await User.findById(req.user!.id);
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }
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
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }
    return sendSuccess(res, "Profile updated", mapUser(req, user));
  } catch (err) {
    return next(err);
  }
}

export async function updateProfilePhoto(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    if (!req.file) {
      throw new AppError("Photo file is required", 400, "PHOTO_REQUIRED");
    }
    const profilePhotoUrl = `/uploads/profiles/${req.file.filename}`;
    const user = await User.findByIdAndUpdate(
      req.user!.id,
      { profilePhotoUrl },
      { new: true }
    );
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }
    return sendSuccess(res, "Profile photo updated", mapUser(req, user));
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
    if (!user) {
      throw new AppError("User not found", 404, "NOT_FOUND");
    }
    return sendSuccess(res, "User loaded", mapUser(req, user));
  } catch (err) {
    return next(err);
  }
}
