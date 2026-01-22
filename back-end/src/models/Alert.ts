import mongoose, { Schema, type InferSchemaType } from "mongoose";

const alertSchema = new Schema(
  {
    title: { type: String, required: true },
    body: { type: String, required: true },
    severity: {
      type: String,
      enum: ["info", "warning", "urgent"],
      default: "info",
      required: true
    },
    target: { type: String, default: "all" },
    createdBy: { type: Schema.Types.ObjectId, ref: "User", required: true },
    readBy: [{ type: Schema.Types.ObjectId, ref: "User" }]
  },
  { timestamps: true }
);

export type AlertDocument = InferSchemaType<typeof alertSchema> & { _id: mongoose.Types.ObjectId };

export const Alert = mongoose.model("Alert", alertSchema);
