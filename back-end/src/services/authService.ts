import bcrypt from "bcryptjs";
import { env } from "../config/env.js";
import { userRepository } from "../repositories/userRepository.js";
import { refreshTokenRepository } from "../repositories/refreshTokenRepository.js";
import { passwordResetRepository } from "../repositories/passwordResetRepository.js";
import { AppError } from "../utils/errors.js";
import { hashToken, generateRandomToken, timingSafeEqual } from "../utils/crypto.js";
import { signAccessToken, signRefreshToken, verifyRefreshToken } from "../utils/jwt.js";
import { v4 as uuidv4 } from "uuid";

const PASSWORD_SALT_ROUNDS = 12;
function getRefreshExpiry(remember?: boolean) {
  const days = remember ? env.refreshTokenRememberDays : env.refreshTokenDays;
  const expiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
  return { expiresAt, days };
}

function getRefreshExpiresIn(days: number) {
  return `${days}d`;
}

export async function register(payload: {
  accountType: "resident" | "admin_driver";
  name: string;
  email: string;
  phone: string;
  password: string;
  society: string;
  building: string;
  apartment: string;
  terms: boolean;
}, meta: { ip?: string; userAgent?: string }) {
  const existing = await userRepository.findByEmail(payload.email);
  if (existing) {
    throw new AppError("Account already exists", 409, "ACCOUNT_EXISTS");
  }

  const passwordHash = await bcrypt.hash(payload.password, PASSWORD_SALT_ROUNDS);
  const user = await userRepository.create({
    accountType: payload.accountType,
    name: payload.name,
    email: payload.email,
    phone: payload.phone,
    passwordHash,
    society: payload.society,
    building: payload.building,
    apartment: payload.apartment,
    termsAcceptedAt: new Date()
  });

  return issueTokens(user, meta, false);
}

export async function login(payload: { email: string; password: string; remember?: boolean }, meta: { ip?: string; userAgent?: string }) {
  const user = await userRepository.findByEmail(payload.email);
  if (!user) {
    throw new AppError("Invalid credentials", 401, "INVALID_CREDENTIALS");
  }

  const matches = await bcrypt.compare(payload.password, user.passwordHash);
  if (!matches) {
    throw new AppError("Invalid credentials", 401, "INVALID_CREDENTIALS");
  }

  return issueTokens(user, meta, payload.remember ?? false);
}

export async function refresh(refreshToken: string, meta: { ip?: string; userAgent?: string }) {
  let payload: { sub: string; jti: string };
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw new AppError("Invalid refresh token", 401, "INVALID_REFRESH");
  }

  const session = await refreshTokenRepository.findByJti(payload.jti);
  if (!session) {
    throw new AppError("Refresh token not recognized", 401, "INVALID_REFRESH");
  }

  if (session.revokedAt) {
    await refreshTokenRepository.revokeAllForUser(payload.sub);
    throw new AppError("Refresh token reuse detected", 401, "TOKEN_REUSED");
  }

  if (session.expiresAt <= new Date()) {
    await refreshTokenRepository.revokeByJti(payload.jti);
    throw new AppError("Refresh token expired", 401, "TOKEN_EXPIRED");
  }

  const incomingHash = hashToken(refreshToken);
  if (!timingSafeEqual(incomingHash, session.hashedToken)) {
    await refreshTokenRepository.revokeAllForUser(payload.sub);
    throw new AppError("Refresh token reuse detected", 401, "TOKEN_REUSED");
  }

  await refreshTokenRepository.revokeByJti(payload.jti);

  const user = await userRepository.findById(payload.sub);
  if (!user) {
    throw new AppError("User not found", 404, "USER_NOT_FOUND");
  }

  return issueTokens(user, meta, false);
}

export async function logout(refreshToken?: string) {
  if (!refreshToken) return;
  try {
    const payload = verifyRefreshToken(refreshToken);
    await refreshTokenRepository.revokeByJti(payload.jti);
  } catch {
    return;
  }
}

export async function forgotPassword(email: string) {
  const user = await userRepository.findByEmail(email);
  if (!user) {
    return { devResetToken: null };
  }
  const token = generateRandomToken(32);
  const tokenHash = hashToken(token);
  const expiresAt = new Date(Date.now() + 1000 * 60 * 30);
  await passwordResetRepository.create({ userId: user._id.toString(), tokenHash, expiresAt });
  return { devResetToken: env.nodeEnv === "development" ? token : null };
}

export async function resetPassword(token: string, password: string) {
  const tokenHash = hashToken(token);
  const reset = await passwordResetRepository.findValid(tokenHash);
  if (!reset) {
    throw new AppError("Invalid or expired reset token", 400, "INVALID_RESET_TOKEN");
  }

  const passwordHash = await bcrypt.hash(password, PASSWORD_SALT_ROUNDS);
  await userRepository.updatePassword(reset.userId.toString(), passwordHash);
  await passwordResetRepository.markUsed(reset._id.toString());
  await refreshTokenRepository.revokeAllForUser(reset.userId.toString());
}

export async function getMe(userId: string) {
  const user = await userRepository.findById(userId);
  if (!user) throw new AppError("User not found", 404, "USER_NOT_FOUND");
  return user;
}

async function issueTokens(user: { _id: { toString(): string } } & { email: string; accountType: string; name: string; phone: string; society: string; building: string; apartment: string; }, meta: { ip?: string; userAgent?: string }, remember: boolean) {
  const accessToken = signAccessToken(user as any);
  const jti = uuidv4();
  const { expiresAt, days } = getRefreshExpiry(remember);
  const refreshToken = signRefreshToken(user._id.toString(), jti, getRefreshExpiresIn(days));
  const hashedToken = hashToken(refreshToken);

  await refreshTokenRepository.create({
    userId: user._id.toString(),
    jti,
    hashedToken,
    expiresAt,
    ip: meta.ip,
    userAgent: meta.userAgent
  });

  return {
    accessToken,
    refreshToken,
    user: {
      id: user._id.toString(),
      accountType: user.accountType,
      name: user.name,
      email: user.email,
      phone: user.phone,
      society: user.society,
      building: user.building,
      apartment: user.apartment
    }
  };
}
