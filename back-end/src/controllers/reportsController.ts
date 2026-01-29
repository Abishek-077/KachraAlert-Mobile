import type { Response, NextFunction } from "express";
import { Report, type ReportDocument } from "../models/Report.js";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/errors.js";
import { toPublicUrl } from "../utils/publicUrl.js";
import type { AuthRequest } from "../middleware/auth.js";

function mapReport(req: AuthRequest, report: ReportDocument) {
  return {
    id: report._id.toString(),
    title: report.title,
    category: report.category,
    priority: report.priority,
    status: report.status,
    createdAt: report.createdAt,
    attachmentUrl: toPublicUrl(req, report.attachmentUrl)
  };
}

export async function listReports(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const filter = req.user!.accountType === "admin_driver" ? {} : { createdBy: req.user!.id };
    const reports = await Report.find(filter).sort({ createdAt: -1 });
    return sendSuccess(res, "Reports loaded", reports.map((report) => mapReport(req, report)));
  } catch (err) {
    return next(err);
  }
}

export async function getReport(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const report = await Report.findById(req.params.id);
    if (!report) {
      throw new AppError("Report not found", 404, "NOT_FOUND");
    }
    if (req.user!.accountType !== "admin_driver" && report.createdBy.toString() !== req.user!.id) {
      throw new AppError("Not authorized", 403, "FORBIDDEN");
    }
    return sendSuccess(res, "Report loaded", mapReport(req, report));
  } catch (err) {
    return next(err);
  }
}

export async function createReport(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const attachmentUrl = req.file ? `/uploads/reports/${req.file.filename}` : undefined;
    const report = await Report.create({
      title: req.body.title,
      category: req.body.category,
      priority: req.body.priority ?? "Medium",
      ...(attachmentUrl ? { attachmentUrl } : {}),
      createdBy: req.user!.id,
      status: "Open"
    });
    return sendSuccess(res, "Report created", mapReport(req, report));
  } catch (err) {
    return next(err);
  }
}

export async function updateReport(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const report = await Report.findById(req.params.id);
    if (!report) {
      throw new AppError("Report not found", 404, "NOT_FOUND");
    }
    if (req.user!.accountType !== "admin_driver" && report.createdBy.toString() !== req.user!.id) {
      throw new AppError("Not authorized", 403, "FORBIDDEN");
    }

    if (req.user!.accountType !== "admin_driver" && (req.body.status || req.body.priority)) {
      throw new AppError("Not authorized to update status or priority", 403, "FORBIDDEN");
    }

    if (req.body.title) report.title = req.body.title;
    if (req.body.category) report.category = req.body.category;
    if (req.body.status) report.status = req.body.status;
    if (req.body.priority) report.priority = req.body.priority;

    await report.save();
    return sendSuccess(res, "Report updated", mapReport(req, report));
  } catch (err) {
    return next(err);
  }
}

export async function deleteReport(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const report = await Report.findById(req.params.id);
    if (!report) {
      throw new AppError("Report not found", 404, "NOT_FOUND");
    }
    if (req.user!.accountType !== "admin_driver" && report.createdBy.toString() !== req.user!.id) {
      throw new AppError("Not authorized", 403, "FORBIDDEN");
    }

    await report.deleteOne();
    return sendSuccess(res, "Report deleted", { id: report._id.toString() });
  } catch (err) {
    return next(err);
  }
}
