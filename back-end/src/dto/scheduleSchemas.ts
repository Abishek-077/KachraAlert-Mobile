import { z } from "zod";

const wasteType = z.enum(["Biodegradable", "Dry Waste", "Plastic", "Glass", "Metal"]);
const scheduleStatus = z.enum(["Upcoming", "Completed", "Missed"]);

export const createScheduleSchema = z.object({
  dateISO: z.string().min(1, "Date is required"),
  timeLabel: z.string().min(1, "Time label is required"),
  waste: wasteType,
  status: scheduleStatus.optional()
});

export const updateScheduleSchema = z
  .object({
    dateISO: z.string().min(1).optional(),
    timeLabel: z.string().min(1).optional(),
    waste: wasteType.optional(),
    status: scheduleStatus.optional()
  })
  .refine((data) => data.dateISO || data.timeLabel || data.waste || data.status, {
    message: "Provide data to update"
  });
