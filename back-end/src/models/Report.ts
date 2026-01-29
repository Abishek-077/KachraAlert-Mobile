import mongoose, { Schema, type InferSchemaType } from "mongoose";

const attachmentSchema = new Schema(
  {
    filename: { type: String, required: true },
    originalName: { type: String, required: true },
    mimeType: { type: String, required: true },
    size: { type: Number, required: true },
    uploadedAt: { type: Date, default: Date.now }
  },
  { _id: true }
);

const reportSchema = new Schema(
  {
    title: { type: String, required: true },
    category: {
      type: String,
      enum: ["Missed Pickup", "Overflow", "Payment", "Other"],
      required: true
    },
    priority: {
      type: String,
      enum: ["Low", "Medium", "High"],
      required: true
    },
    status: {
      type: String,
      enum: ["Open", "In Progress", "Resolved"],
      default: "Open",
      required: true
    },
    createdBy: { type: Schema.Types.ObjectId, ref: "User", required: true },
    attachments: { type: [attachmentSchema], default: [] }
  },
  { timestamps: true }
);

export type ReportDocument = InferSchemaType<typeof reportSchema> & { _id: mongoose.Types.ObjectId };

export const Report = mongoose.model("Report", reportSchema);
