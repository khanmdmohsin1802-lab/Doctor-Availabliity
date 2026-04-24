import express from "express";
import { protect, authorizeRoles } from "../middlewares/authMilddleware.js";
import {
  getDoctors,
  getDoctorInfoById,
} from "../controllers/patientController.js";

const router = express.Router();

router.use(protect);
router.use(authorizeRoles("patient"));

router.get("/doctors", getDoctors);
router.get("/doctors/:id", getDoctorInfoById);

export default router;
