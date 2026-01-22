import { RefreshToken } from "../models/RefreshToken.js";

export const refreshTokenRepository = {
  create(data: {
    userId: string;
    jti: string;
    hashedToken: string;
    expiresAt: Date;
    ip?: string;
    userAgent?: string;
  }) {
    return RefreshToken.create(data);
  },
  findByJti(jti: string) {
    return RefreshToken.findOne({ jti }).exec();
  },
  revokeByJti(jti: string) {
    return RefreshToken.findOneAndUpdate({ jti }, { revokedAt: new Date() }, { new: true }).exec();
  },
  revokeAllForUser(userId: string) {
    return RefreshToken.updateMany({ userId, revokedAt: { $exists: false } }, { revokedAt: new Date() }).exec();
  },
  updateLastUsed(jti: string) {
    return RefreshToken.findOneAndUpdate({ jti }, { lastUsedAt: new Date() }).exec();
  }
};
