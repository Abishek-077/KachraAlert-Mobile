import type { Response, NextFunction } from "express";
import type { AuthRequest } from "../middleware/auth.js";
import { sendSuccess } from "../utils/response.js";
import { emitChatMessage } from "../utils/socket.js";
import * as messageService from "../services/messageService.js";

export async function listContacts(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const limitRaw = req.query.limit as string | undefined;
    const queryRaw = req.query.query as string | undefined;
    const limit = limitRaw ? Number(limitRaw) : undefined;

    const contacts = await messageService.listContactsForUser(
      req.user!.id,
      req.user!.accountType,
      {
        limit: Number.isFinite(limit) ? limit : undefined,
        query: queryRaw ?? undefined
      }
    );
    return sendSuccess(res, "Contacts loaded", contacts);
  } catch (err) {
    return next(err);
  }
}

export async function listConversation(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const limitRaw = req.query.limit as string | undefined;
    const beforeRaw = req.query.before as string | undefined;
    const limit = limitRaw ? Number(limitRaw) : undefined;
    const before = beforeRaw ? parseBefore(beforeRaw) : null;

    const messages = await messageService.listConversation(req.user!.id, req.params.contactId, {
      limit: Number.isFinite(limit) ? limit : undefined,
      before
    });
    return sendSuccess(res, "Conversation loaded", messages);
  } catch (err) {
    return next(err);
  }
}

function parseBefore(value: string): Date | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  if (/^\d+$/.test(trimmed)) {
    const asNumber = Number(trimmed);
    if (Number.isFinite(asNumber)) {
      return new Date(asNumber);
    }
  }
  const parsed = new Date(trimmed);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed;
}

export async function sendMessage(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const message = await messageService.sendMessage({
      senderId: req.user!.id,
      recipientId: req.params.contactId,
      body: req.body.body
    });
    emitChatMessage(message);
    return sendSuccess(res, "Message sent", message);
  } catch (err) {
    return next(err);
  }
}
