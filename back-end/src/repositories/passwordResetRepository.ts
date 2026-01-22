import { PasswordResetToken } from "../models/PasswordResetToken.js";

export const passwordResetRepository = {
  create(data: { userId: string; tokenHash: string; expiresAt: Date }) {
    return PasswordResetToken.create(data);
  },
  findValid(tokenHash: string) {
    return PasswordResetToken.findOne({
      tokenHash,
      usedAt: { $exists: false },
      expiresAt: { $gt: new Date() }
    }).exec();
  },
  markUsed(id: string) {
    return PasswordResetToken.findByIdAndUpdate(id, { usedAt: new Date() }).exec();
  }
};
