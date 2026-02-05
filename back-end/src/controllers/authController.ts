import type { Request, Response, NextFunction } from "express";
import { sendSuccess } from "../utils/response.js";
import { env } from "../config/env.js";
import * as authService from "../services/authService.js";
import type { AuthRequest } from "../middleware/auth.js";
import { buildProfileImageUrl } from "../utils/userProfileImage.js";
import { normalizeAccountType } from "../utils/accountType.js";

function setRefreshCookie(res: Response, token: string, remember: boolean) {
  const days = remember ? env.refreshTokenRememberDays : env.refreshTokenDays;
  const maxAge = days * 24 * 60 * 60 * 1000;
  res.cookie("refreshToken", token, {
    httpOnly: true,
    secure: env.cookieSecure,
    sameSite: "lax",
    maxAge,
    domain: env.cookieDomain,
    path: "/api/v1/auth"
  });
}

function clearRefreshCookie(res: Response) {
  res.clearCookie("refreshToken", {
    httpOnly: true,
    secure: env.cookieSecure,
    sameSite: "lax",
    domain: env.cookieDomain,
    path: "/api/v1/auth"
  });
}

function getMeta(req: Request) {
  return { ip: req.ip, userAgent: req.get("user-agent") ?? undefined };
}

export async function register(req: Request, res: Response, next: NextFunction) {
  try {
    const { accessToken, refreshToken, user } = await authService.register(req.body, getMeta(req));
    setRefreshCookie(res, refreshToken, false);
    return sendSuccess(res, "Registration successful", { accessToken, user });
  } catch (err) {
    return next(err);
  }
}

export async function login(req: Request, res: Response, next: NextFunction) {
  try {
    const { accessToken, refreshToken, user } = await authService.login(req.body, getMeta(req));
    setRefreshCookie(res, refreshToken, req.body.remember ?? false);
    return sendSuccess(res, "Login successful", { accessToken, user });
  } catch (err) {
    return next(err);
  }
}

export async function refresh(req: Request, res: Response, next: NextFunction) {
  try {
    const refreshToken = req.cookies.refreshToken as string | undefined;
    if (!refreshToken) {
      return sendSuccess(res, "No refresh token", { accessToken: null, user: null });
    }
    const { accessToken, refreshToken: newRefreshToken, user } = await authService.refresh(refreshToken, getMeta(req));
    setRefreshCookie(res, newRefreshToken, false);
    return sendSuccess(res, "Token refreshed", { accessToken, user });
  } catch (err) {
    clearRefreshCookie(res);
    return next(err);
  }
}

export async function logout(req: Request, res: Response, next: NextFunction) {
  try {
    const refreshToken = req.cookies.refreshToken as string | undefined;
    await authService.logout(refreshToken);
    clearRefreshCookie(res);
    return sendSuccess(res, "Logged out");
  } catch (err) {
    return next(err);
  }
}

export async function me(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await authService.getMe(req.user!.id);
    return sendSuccess(res, "User loaded", {
      id: user._id.toString(),
      accountType: normalizeAccountType(user.accountType),
      name: user.name,
      email: user.email,
      phone: user.phone,
      society: user.society,
      building: user.building,
      apartment: user.apartment,
      profileImageUrl: user.profileImage?.filename ? buildProfileImageUrl(user._id.toString()) : null
    });
  } catch (err) {
    return next(err);
  }
}

export async function forgotPassword(req: Request, res: Response, next: NextFunction) {
  try {
    const { devResetToken } = await authService.forgotPassword(req.body.email);
    return sendSuccess(res, "If the account exists, a reset link has been issued", {
      devResetToken: devResetToken ?? undefined
    });
  } catch (err) {
    return next(err);
  }
}

export async function resetPassword(req: Request, res: Response, next: NextFunction) {
  try {
    await authService.resetPassword(req.body.token, req.body.password);
    return sendSuccess(res, "Password reset successful");
  } catch (err) {
    return next(err);
  }
}

export async function oauthPlaceholder(_req: Request, res: Response) {
  return res.status(501).json({
    success: false,
    message: "OAuth provider not configured",
    errorCode: "OAUTH_NOT_IMPLEMENTED"
  });
}
