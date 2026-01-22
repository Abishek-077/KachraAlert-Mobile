import type { Response, NextFunction } from "express";
import { Schedule, type ScheduleDocument } from "../models/Schedule.js";
import { User } from "../models/User.js";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/errors.js";
import { getIo } from "../utils/socket.js";
import type { AuthRequest } from "../middleware/auth.js";

function mapSchedule(schedule: ScheduleDocument) {
  return {
    id: schedule._id.toString(),
    dateISO: schedule.dateISO,
    timeLabel: schedule.timeLabel,
    waste: schedule.waste,
    status: schedule.status
  };
}

export async function listSchedules(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    let filter: Record<string, unknown> = {};
    if (req.user?.accountType !== "admin_driver") {
      const adminUsers = await User.find({ accountType: "admin_driver" }).select("_id").lean();
      const adminIds = adminUsers.map((admin) => admin._id);
      filter = { createdBy: { $in: adminIds } };
    }
    const schedules = await Schedule.find(filter).sort({ dateISO: 1, timeLabel: 1 });
    return sendSuccess(res, "Schedules loaded", schedules.map(mapSchedule));
  } catch (err) {
    return next(err);
  }
}

export async function createSchedule(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const schedule = await Schedule.create({
      dateISO: req.body.dateISO,
      timeLabel: req.body.timeLabel,
      waste: req.body.waste,
      status: req.body.status ?? "Upcoming",
      createdBy: req.user!.id
    });
    const payload = mapSchedule(schedule);
    getIo().emit("schedules:created", payload);
    return sendSuccess(res, "Schedule created", payload);
  } catch (err) {
    return next(err);
  }
}

export async function updateSchedule(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const schedule = await Schedule.findById(req.params.id);
    if (!schedule) {
      throw new AppError("Schedule not found", 404, "NOT_FOUND");
    }
    if (req.user?.accountType !== "admin_driver" && schedule.createdBy.toString() !== req.user!.id) {
      throw new AppError("Not authorized", 403, "FORBIDDEN");
    }

    if (req.body.status) {
      schedule.status = req.body.status;
    }
    if (req.body.dateISO) {
      schedule.dateISO = req.body.dateISO;
    }
    if (req.body.timeLabel) {
      schedule.timeLabel = req.body.timeLabel;
    }
    if (req.body.waste) {
      schedule.waste = req.body.waste;
    }

    await schedule.save();
    const payload = mapSchedule(schedule);
    getIo().emit("schedules:updated", payload);
    return sendSuccess(res, "Schedule updated", payload);
  } catch (err) {
    return next(err);
  }
}

export async function deleteSchedule(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const schedule = await Schedule.findById(req.params.id);
    if (!schedule) {
      throw new AppError("Schedule not found", 404, "NOT_FOUND");
    }
    if (req.user?.accountType !== "admin_driver" && schedule.createdBy.toString() !== req.user!.id) {
      throw new AppError("Not authorized", 403, "FORBIDDEN");
    }
    await schedule.deleteOne();
    getIo().emit("schedules:deleted", { id: schedule._id.toString() });
    return sendSuccess(res, "Schedule removed");
  } catch (err) {
    return next(err);
  }
}
