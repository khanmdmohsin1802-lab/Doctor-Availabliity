import express from "express";
import { protect, authorizeRoles } from "../middlewares/authMilddleware.js";
import {
  getDoctors,
  getDoctorInfoById,
  handleJoinQueue,
} from "../controllers/patientController.js";

const router = express.Router();

router.use(protect);
router.use(authorizeRoles("patient"));

router.get("/doctors", getDoctors);
router.get("/doctors/:id", getDoctorInfoById);

router.post("/queue/join", handleJoinQueue);

export default router;
