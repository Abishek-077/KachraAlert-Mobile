import mongoose from "mongoose";
import { Message, type MessageDocument } from "../models/Message.js";
import { User, type UserDocument } from "../models/User.js";
import { AppError } from "../utils/errors.js";
import { buildProfileImageUrl } from "../utils/userProfileImage.js";

export type MessagingAccountType = "resident" | "admin_driver";

export type ChatContact = {
  id: string;
  name: string;
  accountType: MessagingAccountType;
  profileImageUrl: string | null;
};

export type ChatMessage = {
  id: string;
  senderId: string;
  recipientId: string;
  body: string;
  createdAt: Date;
  readAt: Date | null;
};

function ensureObjectId(id: string, fieldName: string) {
  if (!mongoose.isValidObjectId(id)) {
    throw new AppError(`Invalid ${fieldName}`, 400, "BAD_REQUEST");
  }
}

function normalizeAccountType(value: string): MessagingAccountType {
  if (value === "resident") {
    return "resident";
  }
  if (value === "admin_driver" || value === "admin") {
    return "admin_driver";
  }
  throw new AppError("Invalid account type", 403, "FORBIDDEN");
}

function mapContact(user: UserDocument): ChatContact {
  let accountType: MessagingAccountType;
  try {
    accountType = normalizeAccountType(user.accountType);
  } catch {
    accountType = "resident";
  }
  return {
    id: user._id.toString(),
    name: user.name,
    accountType,
    profileImageUrl: user.profileImage?.filename ? buildProfileImageUrl(user._id.toString()) : null
  };
}

function mapMessage(message: MessageDocument): ChatMessage {
  return {
    id: message._id.toString(),
    senderId: message.sender.toString(),
    recipientId: message.recipient.toString(),
    body: message.body,
    createdAt: message.createdAt,
    readAt: message.readAt ?? null
  };
}

async function getUserOrThrow(userId: string, label: string) {
  ensureObjectId(userId, `${label} id`);
  const user = await User.findById(userId);
  if (!user) {
    throw new AppError(`${label} not found`, 404, "NOT_FOUND");
  }
  return user;
}

function assertMessagingAllowed(sender: UserDocument, recipient: UserDocument) {
  if (sender._id.equals(recipient._id)) {
    throw new AppError("You cannot message yourself", 400, "BAD_REQUEST");
  }

  if (sender.isBanned) {
    throw new AppError("Account is suspended", 403, "ACCOUNT_BANNED");
  }
  if (recipient.isBanned) {
    throw new AppError("Recipient account is suspended", 403, "FORBIDDEN");
  }

  const senderIsAdmin = normalizeAccountType(sender.accountType) === "admin_driver";
  const recipientIsAdmin = normalizeAccountType(recipient.accountType) === "admin_driver";
  if (senderIsAdmin === recipientIsAdmin) {
    throw new AppError(
      "Messaging is only available between resident and admin users",
      403,
      "FORBIDDEN"
    );
  }
}

export async function listContactsForUser(userId: string, accountType: string) {
  ensureObjectId(userId, "User id");
  const requesterType = normalizeAccountType(accountType);
  const preferredFilter =
    requesterType === "admin_driver"
      ? { accountType: "resident" as const }
      : { accountType: { $in: ["admin_driver", "admin"] } };

  const preferredContacts = await User.find({
    ...preferredFilter,
    isBanned: { $ne: true },
    _id: { $ne: userId }
  }).sort({ name: 1 });

  if (preferredContacts.length > 0) {
    return preferredContacts.map(mapContact);
  }

  // Fallback for legacy/inconsistent seed data: show other active accounts.
  const fallbackContacts = await User.find({
    isBanned: { $ne: true },
    _id: { $ne: userId }
  }).sort({ name: 1 });
  return fallbackContacts.map(mapContact);
}

export async function listConversation(requesterId: string, contactId: string) {
  const requester = await getUserOrThrow(requesterId, "User");
  const contact = await getUserOrThrow(contactId, "Contact");
  assertMessagingAllowed(requester, contact);

  await Message.updateMany(
    { sender: contact._id, recipient: requester._id, readAt: null },
    { $set: { readAt: new Date() } }
  );

  const messages = await Message.find({
    $or: [
      { sender: requester._id, recipient: contact._id },
      { sender: contact._id, recipient: requester._id }
    ]
  })
    .sort({ createdAt: 1 })
    .limit(500);

  return messages.map(mapMessage);
}

export async function sendMessage(input: { senderId: string; recipientId: string; body: string }) {
  const sender = await getUserOrThrow(input.senderId, "Sender");
  const recipient = await getUserOrThrow(input.recipientId, "Recipient");
  assertMessagingAllowed(sender, recipient);

  const normalizedBody = input.body.trim();
  if (!normalizedBody) {
    throw new AppError("Message body is required", 400, "BAD_REQUEST");
  }
  if (normalizedBody.length > 1000) {
    throw new AppError("Message is too long", 400, "BAD_REQUEST");
  }

  const message = await Message.create({
    sender: sender._id,
    recipient: recipient._id,
    body: normalizedBody
  });

  return mapMessage(message);
}
