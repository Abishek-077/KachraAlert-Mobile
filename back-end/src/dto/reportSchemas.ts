import { z } from "zod";

const attachmentSchema = z.object({
  name: z.string().min(1, "Attachment name is required"),
  mimeType: z.string().min(1, "Attachment type is required"),
  dataBase64: z.string().min(1, "Attachment data is required")
});

export const createReportSchema = z.object({
  title: z.string().min(6, "Title must be at least 6 characters"),
  category: z.enum(["Missed Pickup", "Overflow", "Payment", "Other"]),
  priority: z.enum(["Low", "Medium", "High"]).optional(),
  attachment: attachmentSchema.optional()
});

export const addAttachmentSchema = z.object({
  attachment: attachmentSchema
});

export const updateReportSchema = z
  .object({
    status: z.enum(["Open", "In Progress", "Resolved"]).optional(),
    priority: z.enum(["Low", "Medium", "High"]).optional()
  })
  .refine((data) => data.status || data.priority, {
    message: "Provide status or priority to update"
  });
