import { z } from "zod";

export const createInvoiceSchema = z.object({
  userId: z.string().min(1, "User is required"),
  period: z.string().min(1, "Period is required"),
  amountNPR: z.number().positive("Amount must be positive"),
  status: z.enum(["Paid", "Due", "Overdue"]).optional(),
  issuedAt: z.string().optional(),
  dueAt: z.string().optional(),
  lateFeePercent: z.number().min(0).max(100).optional()
});

export const payInvoiceSchema = z.object({
  amountNPR: z.number().positive("Amount must be positive"),
  provider: z.enum(["cash", "khalti", "esewa", "test"]).optional()
});

export const updateInvoiceAmountSchema = z.object({
  amountNPR: z.number().positive("Amount must be positive")
});

export const updateInvoiceLateFeeSchema = z.object({
  lateFeePercent: z.number().min(0).max(100)
});
