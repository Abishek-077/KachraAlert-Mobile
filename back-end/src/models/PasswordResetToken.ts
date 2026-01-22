import mongoose, { Schema, type InferSchemaType } from "mongoose";

const passwordResetSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    tokenHash: { type: String, required: true },
    expiresAt: { type: Date, required: true },
    usedAt: { type: Date }
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

export type PasswordResetDocument = InferSchemaType<typeof passwordResetSchema> & { _id: mongoose.Types.ObjectId };

export const PasswordResetToken = mongoose.model("PasswordResetToken", passwordResetSchema);
