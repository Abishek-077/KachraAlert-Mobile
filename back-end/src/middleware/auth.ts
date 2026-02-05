import type { Request, Response, NextFunction } from "express";
import { verifyAccessToken } from "../utils/jwt.js";
import { AppError } from "../utils/errors.js";
import { User } from "../models/User.js";

type AuthRequest = Request & { user?: { id: string; email: string; accountType: string } };

export async function requireAuth(req: AuthRequest, _res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    return next(new AppError("Missing access token", 401, "UNAUTHORIZED"));
  }

  const token = authHeader.slice("Bearer ".length);
  try {
    const payload = verifyAccessToken(token);
    req.user = { id: payload.sub, email: payload.email, accountType: payload.accountType };
    const user = await User.findById(payload.sub).select("isBanned").lean();
    if (!user) {
      return next(new AppError("User not found", 404, "USER_NOT_FOUND"));
    }
    if (user.isBanned) {
      return next(new AppError("Account is suspended", 403, "ACCOUNT_BANNED"));
    }
    return next();
  } catch {
    return next(new AppError("Invalid or expired access token", 401, "UNAUTHORIZED"));
  }
}

export function requireAdmin(req: AuthRequest, _res: Response, next: NextFunction) {
  if (req.user?.accountType !== "admin_driver" && req.user?.accountType !== "admin") {
    return next(new AppError("Admin access required", 403, "FORBIDDEN"));
  }
  return next();
}

export type { AuthRequest };
