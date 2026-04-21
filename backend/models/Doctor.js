import mongoose from "mongoose";
import User from "./User.js";

//Doctors can only select from this --> this is to avoid typos and junk inputs
const validSpecialty = [
  "General Physician",
  "Cardiologist",
  "Dermatologist",
  "Pediatrician",
  "Orthopedic",
];

const doctorSchema = new mongoose.Schema({
  // doctors specialty attribute
  specialty: {
    type: String,
    required: true,
    enum: {
      values: validSpecialty,
    },
  },
  // doctors years of experience attribute
  experienceYears: {
    type: Number,
  },
  // wheater doctor is accepting or not attribute
  isAcceptingPatients: {
    type: Boolean,
    default: false,
  },
});

const Doctor = User.discriminator("doctor", doctorSchema);

export default Doctor;
