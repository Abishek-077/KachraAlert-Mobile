import mongoose, { Schema, type InferSchemaType } from "mongoose";

const scheduleSchema = new Schema(
  {
    dateISO: { type: String, required: true },
    timeLabel: { type: String, required: true },
    waste: {
      type: String,
      enum: ["Biodegradable", "Dry Waste", "Plastic", "Glass", "Metal"],
      required: true
    },
    status: {
      type: String,
      enum: ["Upcoming", "Completed", "Missed"],
      default: "Upcoming",
      required: true
    },
    createdBy: { type: Schema.Types.ObjectId, ref: "User", required: true }
  },
  { timestamps: true }
);

export type ScheduleDocument = InferSchemaType<typeof scheduleSchema> & { _id: mongoose.Types.ObjectId };

export const Schedule = mongoose.model("Schedule", scheduleSchema);
