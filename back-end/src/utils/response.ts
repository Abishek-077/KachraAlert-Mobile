import type { Response } from "express";

export function sendSuccess(res: Response, message: string, data?: unknown) {
  return res.json({ success: true, message, data });
}

export function sendError(res: Response, message: string, statusCode: number, errorCode?: string) {
  return res.status(statusCode).json({ success: false, message, errorCode });
}
