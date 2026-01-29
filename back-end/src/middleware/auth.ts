import type { Request, Response, NextFunction } from "express";
import { verifyAccessToken } from "../utils/jwt.js";
import { AppError } from "../utils/errors.js";

type AuthRequest = Request & { user?: { id: string; email: string; accountType: string } };

export function requireAuth(req: AuthRequest, _res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    return next(new AppError("Missing access token", 401, "UNAUTHORIZED"));
  }

  const token = authHeader.slice("Bearer ".length);
  try {
    const payload = verifyAccessToken(token);
    req.user = { id: payload.sub, email: payload.email, accountType: payload.accountType };
    return next();
  } catch {
    return next(new AppError("Invalid or expired access token", 401, "UNAUTHORIZED"));
  }
}

export function requireAdmin(req: AuthRequest, _res: Response, next: NextFunction) {
  if (req.user?.accountType !== "admin_driver") {
    return next(new AppError("Admin access required", 403, "FORBIDDEN"));
  }
  return next();
}

export type { AuthRequest };
