import { Router } from "express";
import * as messagesController from "../controllers/messagesController.js";
import { requireAuth } from "../middleware/auth.js";
import { validateBody } from "../middleware/validate.js";
import { sendMessageSchema } from "../dto/messageSchemas.js";

const router = Router();

router.use(requireAuth);

router.get("/contacts", messagesController.listContacts);
router.get("/:contactId", messagesController.listConversation);
router.post("/:contactId", validateBody(sendMessageSchema), messagesController.sendMessage);

export default router;
