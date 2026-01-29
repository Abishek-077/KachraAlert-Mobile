import type { Response, NextFunction } from "express";
import { Alert, type AlertDocument } from "../models/Alert.js";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/errors.js";
import type { AuthRequest } from "../middleware/auth.js";
import { getIo } from "../utils/socket.js";

function mapAlert(alert: AlertDocument, userId: string) {
  const readBy = (alert.readBy ?? []).map((id) => id.toString());
  return {
    id: alert._id.toString(),
    title: alert.title,
    body: alert.body,
    severity: alert.severity,
    createdAt: alert.createdAt,
    read: readBy.includes(userId),
    target: alert.target
  };
}

export async function listAlerts(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const alerts = await Alert.find({ target: "all" }).sort({ createdAt: -1 });
    const userId = req.user!.id;
    return sendSuccess(res, "Alerts loaded", alerts.map((alert) => mapAlert(alert, userId)));
  } catch (err) {
    return next(err);
  }
}

export async function broadcastAlert(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const alert = await Alert.create({
      title: req.body.title,
      body: req.body.body,
      severity: req.body.severity ?? "info",
      target: req.body.target ?? "all",
      createdBy: req.user!.id,
      readBy: []
    });

    const payload = mapAlert(alert, "");
    getIo().emit("alerts:new", payload);

    return sendSuccess(res, "Alert broadcasted", payload);
  } catch (err) {
    return next(err);
  }
}

export async function markRead(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const alert = await Alert.findByIdAndUpdate(
      req.params.id,
      { $addToSet: { readBy: req.user!.id } },
      { new: true }
    );
    if (!alert) {
      throw new AppError("Alert not found", 404, "NOT_FOUND");
    }
    return sendSuccess(res, "Alert marked read", mapAlert(alert, req.user!.id));
  } catch (err) {
    return next(err);
  }
}

export async function markAllRead(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await Alert.updateMany({ target: "all" }, { $addToSet: { readBy: req.user!.id } });
    return sendSuccess(res, "All alerts marked read");
  } catch (err) {
    return next(err);
  }
}
