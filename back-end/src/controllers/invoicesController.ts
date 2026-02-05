import type { Response, NextFunction } from "express";
import mongoose from "mongoose";
import { Invoice, type InvoiceDocument } from "../models/Invoice.js";
import { Payment } from "../models/Payment.js";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/errors.js";
import type { AuthRequest } from "../middleware/auth.js";
import { User } from "../models/User.js";

function mapInvoice(invoice: InvoiceDocument) {
  return {
    id: invoice._id.toString(),
    period: invoice.period,
    amountNPR: invoice.amountNPR,
    status: invoice.status,
    issuedAt: invoice.issuedAt,
    dueAt: invoice.dueAt,
    lateFeePercent: invoice.lateFeePercent ?? 0,
    userId: invoice.userId.toString()
  };
}

export async function listInvoices(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await Invoice.updateMany(
      { status: "Due", dueAt: { $lt: new Date() } },
      { $set: { status: "Overdue" } }
    );
    const userObjectId = new mongoose.Types.ObjectId(req.user!.id);
    const invoices = await Invoice.find({ userId: userObjectId }).sort({ issuedAt: -1 });
    return sendSuccess(res, "Invoices loaded", invoices.map(mapInvoice));
  } catch (err) {
    return next(err);
  }
}

export async function listAllInvoices(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await Invoice.updateMany(
      { status: "Due", dueAt: { $lt: new Date() } },
      { $set: { status: "Overdue" } }
    );
    const invoices = await Invoice.find().sort({ issuedAt: -1 });
    return sendSuccess(res, "All invoices loaded", invoices.map(mapInvoice));
  } catch (err) {
    return next(err);
  }
}

export async function createInvoice(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.body.userId)) {
      throw new AppError("Invalid user ID", 400, "INVALID_USER");
    }
    const targetUser = await User.findById(req.body.userId).select("accountType").lean();
    if (!targetUser) {
      throw new AppError("User not found", 404, "USER_NOT_FOUND");
    }
    if (targetUser.accountType !== "resident") {
      throw new AppError("Invoices can only be issued to residents", 400, "INVALID_USER_TYPE");
    }
    const issuedAt = req.body.issuedAt ? new Date(req.body.issuedAt) : new Date();
    const dueAt = req.body.dueAt ? new Date(req.body.dueAt) : new Date();
    const invoice = await Invoice.create({
      userId: new mongoose.Types.ObjectId(req.body.userId),
      period: req.body.period,
      amountNPR: req.body.amountNPR,
      status: req.body.status ?? "Due",
      issuedAt,
      dueAt,
      lateFeePercent: req.body.lateFeePercent ?? 0
    });
    return sendSuccess(res, "Invoice created", mapInvoice(invoice));
  } catch (err) {
    return next(err);
  }
}

export async function payInvoice(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const isAdmin = req.user?.accountType === "admin_driver";
    const invoice = await Invoice.findOne(isAdmin ? { _id: req.params.id } : { _id: req.params.id, userId: req.user!.id });
    if (!invoice) {
      throw new AppError("Invoice not found", 404, "NOT_FOUND");
    }

    if (invoice.status === "Paid") {
      return sendSuccess(res, "Invoice already paid", mapInvoice(invoice));
    }

    const paymentAmount = req.body.amountNPR as number;
    const provider = req.body.provider ?? "test";
    const paymentUserId = invoice.userId;

    if (paymentAmount !== invoice.amountNPR) {
      await Payment.create({
        invoiceId: invoice._id,
        userId: paymentUserId,
        amountNPR: paymentAmount,
        provider,
        reference: `test_${Date.now()}`,
        status: "failed"
      });
      throw new AppError("Payment amount does not match invoice total", 400, "AMOUNT_MISMATCH");
    }

    invoice.status = "Paid";
    await invoice.save();
    await Payment.create({
      invoiceId: invoice._id,
      userId: paymentUserId,
      amountNPR: invoice.amountNPR,
      provider,
      reference: `test_${Date.now()}`,
      status: "success"
    });

    return sendSuccess(res, "Invoice paid", mapInvoice(invoice));
  } catch (err) {
    return next(err);
  }
}

export async function updateInvoiceAmount(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const invoice = await Invoice.findById(req.params.id);
    if (!invoice) {
      throw new AppError("Invoice not found", 404, "NOT_FOUND");
    }

    if (invoice.status === "Paid") {
      throw new AppError("Paid invoices cannot be modified", 400, "INVOICE_LOCKED");
    }

    invoice.amountNPR = req.body.amountNPR;
    await invoice.save();

    return sendSuccess(res, "Invoice amount updated", mapInvoice(invoice));
  } catch (err) {
    return next(err);
  }
}

export async function applyInvoiceLateFee(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const invoice = await Invoice.findById(req.params.id);
    if (!invoice) {
      throw new AppError("Invoice not found", 404, "NOT_FOUND");
    }

    if (invoice.status === "Paid") {
      throw new AppError("Paid invoices cannot be modified", 400, "INVOICE_LOCKED");
    }

    const percent = req.body.lateFeePercent as number;
    const multiplier = 1 + percent / 100;
    invoice.amountNPR = Math.round(invoice.amountNPR * multiplier);
    invoice.lateFeePercent = percent;
    if (invoice.dueAt < new Date() && invoice.status === "Due") {
      invoice.status = "Overdue";
    }
    await invoice.save();

    return sendSuccess(res, "Late fee applied", mapInvoice(invoice));
  } catch (err) {
    return next(err);
  }
}

export async function deleteInvoice(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const invoice = await Invoice.findById(req.params.id);
    if (!invoice) {
      throw new AppError("Invoice not found", 404, "NOT_FOUND");
    }
    await invoice.deleteOne();
    return sendSuccess(res, "Invoice deleted");
  } catch (err) {
    return next(err);
  }
}
