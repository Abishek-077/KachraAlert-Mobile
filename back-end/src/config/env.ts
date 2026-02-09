import dotenv from "dotenv";
import type { SignOptions } from "jsonwebtoken";

dotenv.config();

function requireEnv(key: string, fallback?: string) {
  const value = process.env[key] ?? fallback;
  if (!value) {
    throw new Error(`Missing required env var: ${key}`);
  }
  return value;
}

type TokenExpiresIn = NonNullable<SignOptions["expiresIn"]>;

const accessTokenTtl = (process.env.ACCESS_TOKEN_TTL ?? "15m") as TokenExpiresIn;

export const env = {
  nodeEnv: process.env.NODE_ENV ?? "development",
  port: Number(process.env.PORT ?? 4001),
  mongoUri: requireEnv("MONGODB_URI"),
  jwtAccessSecret: requireEnv("JWT_ACCESS_SECRET"),
  jwtRefreshSecret: requireEnv("JWT_REFRESH_SECRET"),
  accessTokenTtl,
  refreshTokenDays: Number(process.env.REFRESH_TOKEN_TTL_DAYS ?? 7),
  refreshTokenRememberDays: Number(process.env.REFRESH_TOKEN_TTL_DAYS_REMEMBER ?? 30),
  frontendUrl: requireEnv("FRONTEND_URL"),
  cookieDomain: process.env.COOKIE_DOMAIN,
  cookieSecure: process.env.COOKIE_SECURE === "true"
};
