import type { Response, NextFunction } from "express";
import { Alert, type AlertDocument } from "../models/Alert.js";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/errors.js";
import type { AuthRequest } from "../middleware/auth.js";
import { getIo } from "../utils/socket.js";
import { buildProfileImageUrl } from "../utils/userProfileImage.js";

type AlertCreator = {
  _id: { toString: () => string };
  name: string;
  profileImage?: {
    filename?: string;
  };
};

function mapCreatedBy(createdBy: unknown) {
  if (createdBy && typeof createdBy === "object" && "name" in createdBy && "_id" in createdBy) {
    const creator = createdBy as AlertCreator;
    const creatorId = creator._id.toString();
    return {
      id: creatorId,
      name: creator.name,
      profileImageUrl: creator.profileImage?.filename ? buildProfileImageUrl(creatorId) : null
    };
  }
  if (createdBy && typeof createdBy === "object" && "toString" in createdBy) {
    const creatorId = (createdBy as { toString: () => string }).toString();
    return {
      id: creatorId,
      name: "Unknown user",
      profileImageUrl: null
    };
  }
  return {
    id: "",
    name: "Unknown user",
    profileImageUrl: null
  };
}

function mapAlert(alert: AlertDocument, userId: string) {
  const readBy = (alert.readBy ?? []).map((id) => id.toString());
  return {
    id: alert._id.toString(),
    title: alert.title,
    body: alert.body,
    severity: alert.severity,
    createdAt: alert.createdAt,
    read: readBy.includes(userId),
    target: alert.target,
    createdBy: mapCreatedBy(alert.createdBy)
  };
}

export async function listAlerts(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const alerts = await Alert.find({ target: "all" })
      .sort({ createdAt: -1 })
      .populate("createdBy", "name profileImage");
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
    await alert.populate("createdBy", "name profileImage");

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
    ).populate("createdBy", "name profileImage");
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
