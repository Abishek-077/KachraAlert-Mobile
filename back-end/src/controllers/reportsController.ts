import type { Response, NextFunction } from "express";
import { Report, type ReportDocument } from "../models/Report.js";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/errors.js";
import type { AuthRequest } from "../middleware/auth.js";
import { reportUploadsDir, writeReportAttachment } from "../utils/reportAttachments.js";
import path from "path";
import fs from "fs";

type AttachmentResponse = {
  id: string;
  originalName: string;
  mimeType: string;
  size: number;
  uploadedAt: Date;
  url: string;
};

function mapReport(report: ReportDocument) {
  const attachments: AttachmentResponse[] =
    report.attachments?.map((attachment) => ({
      id: attachment._id.toString(),
      originalName: attachment.originalName,
      mimeType: attachment.mimeType,
      size: attachment.size,
      uploadedAt: attachment.uploadedAt,
      url: `/api/v1/reports/${report._id.toString()}/attachments/${attachment._id.toString()}`
    })) ?? [];
  return {
    id: report._id.toString(),
    title: report.title,
    category: report.category,
    priority: report.priority,
    status: report.status,
    createdAt: report.createdAt,
    attachments
  };
}

export async function listReports(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const filter = req.user!.accountType === "admin_driver" ? {} : { createdBy: req.user!.id };
    const reports = await Report.find(filter).sort({ createdAt: -1 });
    return sendSuccess(res, "Reports loaded", reports.map(mapReport));
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
    return sendSuccess(res, "Report loaded", mapReport(report));
  } catch (err) {
    return next(err);
  }
}

export async function createReport(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const attachments = req.body.attachment ? [writeReportAttachment(req.body.attachment)] : [];
    const report = await Report.create({
      title: req.body.title,
      category: req.body.category,
      priority: req.body.priority ?? "Medium",
      createdBy: req.user!.id,
      status: "Open",
      attachments
    });
    return sendSuccess(res, "Report created", mapReport(report));
  } catch (err) {
    return next(err);
  }
}

export async function updateReport(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const report = await Report.findByIdAndUpdate(
      req.params.id,
      {
        ...(req.body.status ? { status: req.body.status } : {}),
        ...(req.body.priority ? { priority: req.body.priority } : {})
      },
      { new: true }
    );
    if (!report) {
      throw new AppError("Report not found", 404, "NOT_FOUND");
    }
    return sendSuccess(res, "Report updated", mapReport(report));
  } catch (err) {
    return next(err);
  }
}

export async function addReportAttachment(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const report = await Report.findById(req.params.id);
    if (!report) {
      throw new AppError("Report not found", 404, "NOT_FOUND");
    }
    if (req.user!.accountType !== "admin_driver" && report.createdBy.toString() !== req.user!.id) {
      throw new AppError("Not authorized", 403, "FORBIDDEN");
    }
    const attachmentPayload = req.body.attachment;
    if (!attachmentPayload) {
      throw new AppError("Attachment is required", 400, "BAD_REQUEST");
    }
    report.attachments.push(writeReportAttachment(attachmentPayload));
    await report.save();
    return sendSuccess(res, "Attachment added", mapReport(report));
  } catch (err) {
    return next(err);
  }
}

export async function getReportAttachment(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const report = await Report.findById(req.params.id);
    if (!report) {
      throw new AppError("Report not found", 404, "NOT_FOUND");
    }
    if (req.user!.accountType !== "admin_driver" && report.createdBy.toString() !== req.user!.id) {
      throw new AppError("Not authorized", 403, "FORBIDDEN");
    }
    const attachment = report.attachments.id(req.params.attachmentId);
    if (!attachment) {
      throw new AppError("Attachment not found", 404, "NOT_FOUND");
    }
    const filePath = path.join(reportUploadsDir, attachment.filename);
    if (!fs.existsSync(filePath)) {
      throw new AppError("Attachment file missing", 404, "NOT_FOUND");
    }
    res.setHeader("Content-Type", attachment.mimeType);
    res.setHeader("Content-Disposition", `attachment; filename="${attachment.originalName}"`);
    return res.sendFile(filePath);
  } catch (err) {
    return next(err);
  }
}
