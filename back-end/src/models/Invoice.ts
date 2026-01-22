import mongoose, { Schema, type InferSchemaType } from "mongoose";

const invoiceSchema = new Schema(
  {
    period: { type: String, required: true },
    amountNPR: { type: Number, required: true },
    status: {
      type: String,
      enum: ["Paid", "Due", "Overdue"],
      default: "Due",
      required: true
    },
    issuedAt: { type: Date, default: Date.now, required: true },
    dueAt: { type: Date, required: true },
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true }
  },
  { timestamps: true }
);

export type InvoiceDocument = InferSchemaType<typeof invoiceSchema> & { _id: mongoose.Types.ObjectId };

export const Invoice = mongoose.model("Invoice", invoiceSchema);
