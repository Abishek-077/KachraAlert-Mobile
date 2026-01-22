import type { Response, NextFunction } from "express";
import { Invoice, type InvoiceDocument } from "../models/Invoice.js";
import { Payment } from "../models/Payment.js";
import { sendSuccess } from "../utils/response.js";
import { AppError } from "../utils/errors.js";
import type { AuthRequest } from "../middleware/auth.js";

function mapInvoice(invoice: InvoiceDocument) {
  return {
    id: invoice._id.toString(),
    period: invoice.period,
    amountNPR: invoice.amountNPR,
    status: invoice.status,
    issuedAt: invoice.issuedAt,
    dueAt: invoice.dueAt
  };
}

export async function listInvoices(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const invoices = await Invoice.find({ userId: req.user!.id }).sort({ issuedAt: -1 });
    return sendSuccess(res, "Invoices loaded", invoices.map(mapInvoice));
  } catch (err) {
    return next(err);
  }
}

export async function listAllInvoices(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const invoices = await Invoice.find().sort({ issuedAt: -1 });
    return sendSuccess(res, "All invoices loaded", invoices.map(mapInvoice));
  } catch (err) {
    return next(err);
  }
}

export async function createInvoice(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const issuedAt = req.body.issuedAt ? new Date(req.body.issuedAt) : new Date();
    const dueAt = req.body.dueAt ? new Date(req.body.dueAt) : new Date();
    const invoice = await Invoice.create({
      userId: req.body.userId,
      period: req.body.period,
      amountNPR: req.body.amountNPR,
      status: req.body.status ?? "Due",
      issuedAt,
      dueAt
    });
    return sendSuccess(res, "Invoice created", mapInvoice(invoice));
  } catch (err) {
    return next(err);
  }
}

export async function payInvoice(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const invoice = await Invoice.findOne({ _id: req.params.id, userId: req.user!.id });
    if (!invoice) {
      throw new AppError("Invoice not found", 404, "NOT_FOUND");
    }

    if (invoice.status !== "Paid") {
      invoice.status = "Paid";
      await invoice.save();
      await Payment.create({
        invoiceId: invoice._id,
        userId: req.user!.id,
        amountNPR: invoice.amountNPR,
        provider: "test",
        reference: `test_${Date.now()}`,
        status: "success"
      });
    }

    return sendSuccess(res, "Invoice paid", mapInvoice(invoice));
  } catch (err) {
    return next(err);
  }
}
