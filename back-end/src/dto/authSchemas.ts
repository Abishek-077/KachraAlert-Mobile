import { z } from "zod";

const passwordSchema = z
  .string()
  .min(8, "Password must be at least 8 characters")
  .regex(/[a-z]/, "Password must include a lowercase letter")
  .regex(/[A-Z]/, "Password must include an uppercase letter")
  .regex(/[0-9]/, "Password must include a number")
  .regex(/[^A-Za-z0-9]/, "Password must include a special character");

export const registerSchema = z.object({
  accountType: z.enum(["resident", "admin_driver"]),
  name: z.string().min(2),
  email: z.string().email(),
  phone: z.string().min(7),
  password: passwordSchema,
  society: z.string().min(2),
  building: z.string().min(1),
  apartment: z.string().min(1),
  terms: z.boolean().refine((v) => v === true, "Terms must be accepted"),
  adminCode: z.string().optional()
}).superRefine((payload, ctx) => {
  if (payload.accountType === "admin_driver" && payload.adminCode !== "soul777") {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: ["adminCode"],
      message: "Invalid admin code"
    });
  }
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
  remember: z.boolean().optional(),
  adminCode: z.string().optional()
});

export const refreshSchema = z.object({});

export const forgotPasswordSchema = z.object({
  email: z.string().email()
});

export const resetPasswordSchema = z.object({
  token: z.string().min(1),
  password: passwordSchema
});
