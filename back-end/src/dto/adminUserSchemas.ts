import { z } from "zod";

export const adminCreateUserSchema = z.object({
  accountType: z.enum(["resident", "admin_driver"]),
  name: z.string().min(1, "Name is required"),
  email: z.string().email("Valid email is required"),
  phone: z.string().min(1, "Phone is required"),
  password: z.string().min(6, "Password must be at least 6 characters"),
  society: z.string().min(1, "Society is required"),
  building: z.string().min(1, "Building is required"),
  apartment: z.string().min(1, "Apartment is required")
});

export const adminUpdateUserSchema = z.object({
  accountType: z.enum(["resident", "admin_driver"]).optional(),
  name: z.string().min(1, "Name is required").optional(),
  email: z.string().email("Valid email is required").optional(),
  phone: z.string().min(1, "Phone is required").optional(),
  password: z.string().min(6, "Password must be at least 6 characters").optional(),
  society: z.string().min(1, "Society is required").optional(),
  building: z.string().min(1, "Building is required").optional(),
  apartment: z.string().min(1, "Apartment is required").optional(),
  isBanned: z.boolean().optional(),
  lateFeePercent: z.number().min(0).max(100).optional()
});

export const adminUpdateUserStatusSchema = z.object({
  isBanned: z.boolean().optional(),
  lateFeePercent: z.number().min(0).max(100).optional()
});
