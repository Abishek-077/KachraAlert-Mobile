import mongoose, { Schema, type InferSchemaType } from "mongoose";

const refreshTokenSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    jti: { type: String, required: true, unique: true },
    hashedToken: { type: String, required: true },
    expiresAt: { type: Date, required: true },
    revokedAt: { type: Date },
    lastUsedAt: { type: Date },
    ip: { type: String },
    userAgent: { type: String }
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

export type RefreshTokenDocument = InferSchemaType<typeof refreshTokenSchema> & { _id: mongoose.Types.ObjectId };

export const RefreshToken = mongoose.model("RefreshToken", refreshTokenSchema);
