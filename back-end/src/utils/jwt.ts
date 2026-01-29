import jwt, { type SignOptions } from "jsonwebtoken";
import { env } from "../config/env.js";
import type { UserDocument } from "../models/User.js";

export type AccessTokenPayload = {
  sub: string;
  email: string;
  accountType: string;
};

export type RefreshTokenPayload = {
  sub: string;
  jti: string;
};

type TokenExpiresIn = NonNullable<SignOptions["expiresIn"]>;

export function signAccessToken(user: UserDocument) {
  const payload: AccessTokenPayload = {
    sub: user._id.toString(),
    email: user.email,
    accountType: user.accountType
  };
  return jwt.sign(payload, env.jwtAccessSecret, { expiresIn: env.accessTokenTtl });
}

export function signRefreshToken(userId: string, jti: string, expiresIn: TokenExpiresIn) {
  const payload: RefreshTokenPayload = { sub: userId, jti };
  return jwt.sign(payload, env.jwtRefreshSecret, { expiresIn });
}

export function verifyAccessToken(token: string) {
  return jwt.verify(token, env.jwtAccessSecret) as AccessTokenPayload;
}

export function verifyRefreshToken(token: string) {
  return jwt.verify(token, env.jwtRefreshSecret) as RefreshTokenPayload;
}
