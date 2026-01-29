import { z } from "zod";

export const updateProfileSchema = z
  .object({
    name: z.string().min(1, "Name is required").optional(),
    phone: z.string().min(1, "Phone is required").optional(),
    society: z.string().min(1, "Society is required").optional(),
    building: z.string().min(1, "Building is required").optional(),
    apartment: z.string().min(1, "Apartment is required").optional()
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "No profile updates provided"
  });

export const uploadProfileImageSchema = z.object({
  image: z.object({
    name: z.string().min(1, "Image name is required"),
    mimeType: z.string().min(1, "Image mime type is required"),
    dataBase64: z.string().min(1, "Image data is required")
  })
});
