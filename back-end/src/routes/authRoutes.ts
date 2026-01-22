import { Router } from "express";
import * as authController from "../controllers/authController.js";
import { validateBody } from "../middleware/validate.js";
import {
  registerSchema,
  loginSchema,
  forgotPasswordSchema,
  resetPasswordSchema
} from "../dto/authSchemas.js";
import { requireAuth } from "../middleware/auth.js";
import { loginLimiter, forgotPasswordLimiter } from "../middleware/rateLimit.js";

const router = Router();

router.post("/register", validateBody(registerSchema), authController.register);
router.post("/login", loginLimiter, validateBody(loginSchema), authController.login);
router.get("/me", requireAuth, authController.me);
router.post("/refresh", authController.refresh);
router.post("/logout", authController.logout);
router.post("/forgot-password", forgotPasswordLimiter, validateBody(forgotPasswordSchema), authController.forgotPassword);
router.post("/reset-password", validateBody(resetPasswordSchema), authController.resetPassword);
router.get("/oauth/:provider/start", authController.oauthPlaceholder);
router.get("/oauth/:provider/callback", authController.oauthPlaceholder);

export default router;
