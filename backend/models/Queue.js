import mongoose from "mongoose";

const queueSchema = new mongoose.Schema(
  {
    patientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "user",
      required: true,
    },
    doctorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "user",
      required: true,
    },
    reasonForVisit: {
      type: String,
      default: "Genral Consultation",
    },
    status: {
      type: String,
      enum: ["waiting", "in-progress", "completed", "cancelled"],
      default: "waiting",
    },
  },
  {
    timestamps: true,
  },
);

const Queue = mongoose.model("queue", queueSchema);

export default Queue;
