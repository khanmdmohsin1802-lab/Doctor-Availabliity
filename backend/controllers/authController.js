import "dotenv/config";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import User from "../models/User.js";
import Patient from "../models/Patient.js";
import Doctor from "../models/Doctor.js";

//jwt token genration function
const genrateToken = (id, role) => {
  return jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: "30d" });
};

//sing up function
const handleRegister = async (req, res) => {
  try {
    const { name, email, password, ...rest } = req.body; // ...rest --> means take the remaining fields (just mention the fields you want to do the opreations on)
    const role = req.body.role?.toLowerCase(); // to make sure if user types Patient or PATIENT the function validates it as valid

    //check if user already exist
    const userExist = await User.findOne({ email });

    if (userExist) {
      return res
        .status(400)
        .json({ message: "User already exist", help: "Try logging in" });
    }
    //hash the password before storing
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(password, salt);

    //check who signed up
    let newUser;
    if (role == "doctor") {
      newUser = await Doctor.create({ name, email, password: hash, ...rest }); // we explicitly write password:hash cause in the schema there is no field/attribute named hash
    } else if (role == "patient") {
      newUser = await Patient.create({ name, email, password: hash, ...rest });
    } else {
      return res.status(400).json({ message: "Invaild role rovided" });
    }

    //send the response for the frontend to use
    res.json({
      _id: newUser._id,
      name: newUser.name,
      email: newUser.email,
      role: newUser.role,
      token: genrateToken(newUser._id, newUser.role),
    });
  } catch (error) {
    res.status(500).json({ Error: error.message });
  }
};

//Login function
const handleLogin = async (req, res) => {
  const { email, password } = req.body;

  const tryUser = await User.findOne({ email }); // stores the one with that email or gives false if not exist

  //check if user exist and also check the password by comparing the recived password and the tryUser password stord in form of hash using bcrypt compare
  if (tryUser && (await bcrypt.compare(password, tryUser.password))) {
    res.json({
      _id: tryUser._id,
      name: tryUser.name,
      email: tryUser.email,
      role: tryUser.role,
      token: genrateToken(tryUser._id, tryUser.role),
    });
  }
};
export { handleRegister, handleLogin };
