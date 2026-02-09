import type { Response, NextFunction } from "express";
import type { AuthRequest } from "../middleware/auth.js";
import { sendSuccess } from "../utils/response.js";
import { emitChatMessage, emitChatMessageUpdate } from "../utils/socket.js";
import * as messageService from "../services/messageService.js";

export async function listContacts(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const contacts = await messageService.listContactsForUser(req.user!.id, req.user!.accountType);
    return sendSuccess(res, "Contacts loaded", contacts);
  } catch (err) {
    return next(err);
  }
}

export async function listConversation(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const messages = await messageService.listConversation(req.user!.id, req.params.contactId);
    return sendSuccess(res, "Conversation loaded", messages);
  } catch (err) {
    return next(err);
  }
}

export async function sendMessage(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const message = await messageService.sendMessage({
      senderId: req.user!.id,
      recipientId: req.params.contactId,
      body: req.body.body,
      replyToMessageId: req.body.replyToMessageId
    });
    emitChatMessage(message);
    return sendSuccess(res, "Message sent", message);
  } catch (err) {
    return next(err);
  }
}

export async function editMessage(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const message = await messageService.editMessage({
      requesterId: req.user!.id,
      contactId: req.params.contactId,
      messageId: req.params.messageId,
      body: req.body.body
    });
    emitChatMessageUpdate(message);
    return sendSuccess(res, "Message updated", message);
  } catch (err) {
    return next(err);
  }
}

export async function deleteMessage(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const message = await messageService.deleteMessage({
      requesterId: req.user!.id,
      contactId: req.params.contactId,
      messageId: req.params.messageId
    });
    emitChatMessageUpdate(message);
    return sendSuccess(res, "Message deleted", message);
  } catch (err) {
    return next(err);
  }
}
