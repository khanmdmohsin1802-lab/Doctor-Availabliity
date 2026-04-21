import mongoose from "mongoose";

const baseOptions = {
  discriminatorKey: "role",
  timestamps: true,
};

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
    },
    password: {
      type: String,
      required: true,
    },
  },
  baseOptions,
);

const User = mongoose.model("user", userSchema);

export default User;
