import mongoose, { Schema, type InferSchemaType } from "mongoose";

const messageSchema = new Schema(
  {
    sender: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    recipient: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    body: { type: String, required: true, trim: true, maxlength: 1000 },
    readAt: { type: Date }
  },
  { timestamps: true }
);

messageSchema.index({ sender: 1, recipient: 1, createdAt: 1 });

export type MessageDocument = InferSchemaType<typeof messageSchema> & { _id: mongoose.Types.ObjectId };

export const Message = mongoose.model("Message", messageSchema);
