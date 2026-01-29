import { Router } from "express";
import * as invoicesController from "../controllers/invoicesController.js";
import { requireAuth, requireAdmin } from "../middleware/auth.js";
import { validateBody } from "../middleware/validate.js";
import { createInvoiceSchema, payInvoiceSchema, updateInvoiceAmountSchema } from "../dto/invoiceSchemas.js";

const router = Router();

router.get("/", requireAuth, invoicesController.listInvoices);
router.post("/:id/pay", requireAuth, validateBody(payInvoiceSchema), invoicesController.payInvoice);
router.get("/all", requireAuth, requireAdmin, invoicesController.listAllInvoices);
router.post("/", requireAuth, requireAdmin, validateBody(createInvoiceSchema), invoicesController.createInvoice);
router.patch("/:id/amount", requireAuth, requireAdmin, validateBody(updateInvoiceAmountSchema), invoicesController.updateInvoiceAmount);

export default router;
