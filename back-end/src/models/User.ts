import mongoose, { Schema, type InferSchemaType } from "mongoose";

const userSchema = new Schema(
  {
    accountType: {
      type: String,
      enum: ["resident", "admin_driver"],
      required: true
    },
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    phone: { type: String, required: true },
    passwordHash: { type: String, required: true },
    society: { type: String, required: true },
    building: { type: String, required: true },
    apartment: { type: String, required: true },
    termsAcceptedAt: { type: Date, required: true },
    profilePhotoUrl: { type: String }
  },
  { timestamps: true }
);

export type UserDocument = InferSchemaType<typeof userSchema> & { _id: mongoose.Types.ObjectId };

export const User = mongoose.model("User", userSchema);
