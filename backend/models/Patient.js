import mongoose from "mongoose";
import User from "./User.js";

const patientSchema = new mongoose.Schema({
  age: {
    type: Number,
  },
  weight: {
    type: Number,
  },
});

const Patient = User.discriminator("patient", patientSchema);

export default Patient;
