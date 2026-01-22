import express from "express";
import cors from "cors";
import helmet from "helmet";
import cookieParser from "cookie-parser";
import morgan from "morgan";
import authRoutes from "./routes/authRoutes.js";
import alertRoutes from "./routes/alertsRoutes.js";
import reportRoutes from "./routes/reportRoutes.js";
import invoiceRoutes from "./routes/invoiceRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import schedulesRoutes from "./routes/schedulesRoutes.js";
import { errorHandler } from "./middleware/error.js";
import { env } from "./config/env.js";

const app = express();

app.use(helmet());
app.use(
  cors({
    origin: env.frontendUrl,
    credentials: true
  })
);
app.use(express.json());
app.use(cookieParser());
app.use(morgan("dev"));

app.get("/api/v1/health", (_req, res) => {
  res.json({ success: true, message: "OK" });
});

app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/alerts", alertRoutes);
app.use("/api/v1/reports", reportRoutes);
app.use("/api/v1/invoices", invoiceRoutes);
app.use("/api/v1/users", userRoutes);
app.use("/api/v1/schedules", schedulesRoutes);

app.use(errorHandler);

export default app;
