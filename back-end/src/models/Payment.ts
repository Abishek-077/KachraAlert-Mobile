import mongoose, { Schema, type InferSchemaType } from "mongoose";

const paymentSchema = new Schema(
  {
    invoiceId: { type: Schema.Types.ObjectId, ref: "Invoice", required: true },
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    amountNPR: { type: Number, required: true },
    provider: {
      type: String,
      enum: ["cash", "khalti", "esewa", "test"],
      default: "test",
      required: true
    },
    reference: { type: String },
    status: {
      type: String,
      enum: ["pending", "success", "failed"],
      default: "success",
      required: true
    }
  },
  { timestamps: true }
);

export type PaymentDocument = InferSchemaType<typeof paymentSchema> & { _id: mongoose.Types.ObjectId };

export const Payment = mongoose.model("Payment", paymentSchema);
