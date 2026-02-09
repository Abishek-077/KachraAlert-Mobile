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

export type ChatReplyPreview = {
  messageId: string;
  senderId: string;
  senderName: string;
  body: string;
};

export type ChatMessage = {
  id: string;
  senderId: string;
  recipientId: string;
  senderName: string;
  senderProfileImageUrl: string | null;
  recipientName: string;
  recipientProfileImageUrl: string | null;
  body: string;
  createdAt: Date;
  readAt: Date | null;
  editedAt: Date | null;
  deletedAt: Date | null;
  isDeleted: boolean;
  replyTo: ChatReplyPreview | null;
};

type UserMeta = {
  name: string;
  profileImageUrl: string | null;
};

type ReplyToRecord = {
  messageId: mongoose.Types.ObjectId;
  senderId: mongoose.Types.ObjectId;
  senderName: string;
  body: string;
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

function getConversationFilter(userAId: mongoose.Types.ObjectId, userBId: mongoose.Types.ObjectId) {
  return {
    $or: [
      { sender: userAId, recipient: userBId },
      { sender: userBId, recipient: userAId }
    ]
  };
}

async function loadUsersMeta(ids: string[]) {
  const uniqueIds = Array.from(new Set(ids.filter(Boolean)));
  if (uniqueIds.length === 0) {
    return new Map<string, UserMeta>();
  }

  const users = await User.find({ _id: { $in: uniqueIds } }).select("_id name profileImage");
  const usersMap = new Map<string, UserMeta>();
  for (const user of users) {
    const id = user._id.toString();
    usersMap.set(id, {
      name: user.name,
      profileImageUrl: user.profileImage?.filename ? buildProfileImageUrl(id) : null
    });
  }
  return usersMap;
}

function mapMessage(message: MessageDocument, usersMap: Map<string, UserMeta>): ChatMessage {
  const senderId = message.sender.toString();
  const recipientId = message.recipient.toString();
  const sender = usersMap.get(senderId);
  const recipient = usersMap.get(recipientId);
  const deleted = Boolean(message.deletedAt);

  let replyTo: ChatReplyPreview | null = null;
  if (message.replyTo) {
    const reply = message.replyTo as unknown as ReplyToRecord;
    replyTo = {
      messageId: reply.messageId.toString(),
      senderId: reply.senderId.toString(),
      senderName: reply.senderName,
      body: reply.body
    };
  }

  return {
    id: message._id.toString(),
    senderId,
    recipientId,
    senderName: sender?.name ?? "Unknown user",
    senderProfileImageUrl: sender?.profileImageUrl ?? null,
    recipientName: recipient?.name ?? "Unknown user",
    recipientProfileImageUrl: recipient?.profileImageUrl ?? null,
    body: deleted ? "" : message.body,
    createdAt: message.createdAt,
    readAt: message.readAt ?? null,
    editedAt: message.editedAt ?? null,
    deletedAt: message.deletedAt ?? null,
    isDeleted: deleted,
    replyTo
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

async function getConversationMessageOrThrow(
  messageId: string,
  userAId: mongoose.Types.ObjectId,
  userBId: mongoose.Types.ObjectId
) {
  ensureObjectId(messageId, "Message id");
  const message = await Message.findOne({
    _id: messageId,
    ...getConversationFilter(userAId, userBId)
  });
  if (!message) {
    throw new AppError("Message not found", 404, "NOT_FOUND");
  }
  return message;
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

async function mapSingleMessage(message: MessageDocument) {
  const usersMap = await loadUsersMeta([message.sender.toString(), message.recipient.toString()]);
  return mapMessage(message, usersMap);
}

export async function listContactsForUser(userId: string, accountType: string) {
  ensureObjectId(userId, "User id");
  const requesterType = normalizeAccountType(accountType);

  // Residents can only message admins/drivers.
  // Admins/drivers can only message residents.
  const filter =
    requesterType === "admin_driver"
      ? { accountType: "resident" as const }
      : { accountType: { $in: ["admin_driver", "admin"] } };

  const contacts = await User.find({
    ...filter,
    isBanned: { $ne: true },
    _id: { $ne: userId }
  }).sort({ name: 1 });

  return contacts.map(mapContact);
}

export async function listConversation(requesterId: string, contactId: string) {
  const requester = await getUserOrThrow(requesterId, "User");
  const contact = await getUserOrThrow(contactId, "Contact");
  assertMessagingAllowed(requester, contact);

  await Message.updateMany(
    { sender: contact._id, recipient: requester._id, readAt: null },
    { $set: { readAt: new Date() } }
  );

  const messages = await Message.find(getConversationFilter(requester._id, contact._id))
    .sort({ createdAt: 1 })
    .limit(500);

  const userIds = messages.flatMap((message) => [message.sender.toString(), message.recipient.toString()]);
  const usersMap = await loadUsersMeta(userIds);

  return messages.map((message) => mapMessage(message, usersMap));
}

export async function sendMessage(input: {
  senderId: string;
  recipientId: string;
  body: string;
  replyToMessageId?: string;
}) {
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

  let replyTo: ReplyToRecord | undefined;
  const replyToMessageId = input.replyToMessageId?.trim();
  if (replyToMessageId) {
    const repliedMessage = await getConversationMessageOrThrow(replyToMessageId, sender._id, recipient._id);
    const repliedSender = await User.findById(repliedMessage.sender).select("name");
    if (!repliedSender) {
      throw new AppError("Reply target sender not found", 404, "NOT_FOUND");
    }
    replyTo = {
      messageId: repliedMessage._id,
      senderId: repliedMessage.sender as mongoose.Types.ObjectId,
      senderName: repliedSender.name,
      body: repliedMessage.deletedAt ? "This message was deleted" : repliedMessage.body
    };
  }

  const message = await Message.create({
    sender: sender._id,
    recipient: recipient._id,
    body: normalizedBody,
    ...(replyTo ? { replyTo } : {})
  });

  return mapSingleMessage(message);
}

export async function editMessage(input: {
  requesterId: string;
  contactId: string;
  messageId: string;
  body: string;
}) {
  const requester = await getUserOrThrow(input.requesterId, "User");
  const contact = await getUserOrThrow(input.contactId, "Contact");
  assertMessagingAllowed(requester, contact);

  const message = await getConversationMessageOrThrow(input.messageId, requester._id, contact._id);
  if (message.sender.toString() !== requester._id.toString()) {
    throw new AppError("You can only edit your own messages", 403, "FORBIDDEN");
  }
  if (message.deletedAt) {
    throw new AppError("Deleted messages cannot be edited", 400, "BAD_REQUEST");
  }

  const normalizedBody = input.body.trim();
  if (!normalizedBody) {
    throw new AppError("Message body is required", 400, "BAD_REQUEST");
  }
  if (normalizedBody.length > 1000) {
    throw new AppError("Message is too long", 400, "BAD_REQUEST");
  }

  message.body = normalizedBody;
  message.editedAt = new Date();
  await message.save();

  return mapSingleMessage(message);
}

export async function deleteMessage(input: {
  requesterId: string;
  contactId: string;
  messageId: string;
}) {
  const requester = await getUserOrThrow(input.requesterId, "User");
  const contact = await getUserOrThrow(input.contactId, "Contact");
  assertMessagingAllowed(requester, contact);

  const message = await getConversationMessageOrThrow(input.messageId, requester._id, contact._id);
  if (message.sender.toString() !== requester._id.toString()) {
    throw new AppError("You can only delete your own messages", 403, "FORBIDDEN");
  }

  if (!message.deletedAt) {
    message.deletedAt = new Date();
    await message.save();
  }

  return mapSingleMessage(message);
}
