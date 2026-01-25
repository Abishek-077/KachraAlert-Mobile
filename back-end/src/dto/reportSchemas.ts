import { z } from "zod";

export const createReportSchema = z.object({
  title: z.string().min(6, "Title must be at least 6 characters"),
  category: z.enum(["Missed Pickup", "Overflow", "Payment", "Other"]),
  priority: z.enum(["Low", "Medium", "High"]).optional()
});

export const updateReportSchema = z
  .object({
    title: z.string().min(6, "Title must be at least 6 characters").optional(),
    category: z.enum(["Missed Pickup", "Overflow", "Payment", "Other"]).optional(),
    status: z.enum(["Open", "In Progress", "Resolved"]).optional(),
    priority: z.enum(["Low", "Medium", "High"]).optional()
  })
  .refine((data) => data.title || data.category || data.status || data.priority, {
    message: "Provide at least one field to update"
  });
