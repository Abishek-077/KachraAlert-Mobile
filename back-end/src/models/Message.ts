import mongoose, { Schema, type InferSchemaType } from "mongoose";

const replyPreviewSchema = new Schema(
  {
    messageId: { type: Schema.Types.ObjectId, ref: "Message", required: true },
    senderId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    senderName: { type: String, required: true },
    body: { type: String, required: true, trim: true, maxlength: 1000 }
  },
  { _id: false }
);

const messageSchema = new Schema(
  {
    sender: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    recipient: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    body: { type: String, required: true, trim: true, maxlength: 1000 },
    readAt: { type: Date },
    editedAt: { type: Date },
    deletedAt: { type: Date },
    replyTo: { type: replyPreviewSchema }
  },
  { timestamps: true }
);

messageSchema.index({ sender: 1, recipient: 1, createdAt: 1 });

export type MessageDocument = InferSchemaType<typeof messageSchema> & { _id: mongoose.Types.ObjectId };

export const Message = mongoose.model("Message", messageSchema);
