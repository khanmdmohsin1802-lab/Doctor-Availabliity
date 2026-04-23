import jwt from "jsonwebtoken";
import User from "../models/User.js";

const protect = async (req, res, next) => {
  let token;

  // check if there is authentication header (Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...) AND
  // check the type of authentication (JWT conventionally starts with 'Bearer' )

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  )
    try {
      // just get the token by splitting the token in to two wherever there is space (remove Bearer from the start of the authorization header)
      token = req.headers.authorization.split(" ")[1];

      //decode the token and see if it matches with the jwt secret
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      //get the user by the id and store in the req.user object for other to use
      req.user = await User.findById(decoded.id).select("-password");

      next(); //to the next middleware
    } catch (error) {
      console.log(error.message);
      return res.status(401).json({ message: "Not Authorized, Token Failed" });
    }

  if (!token) {
    res.status(400).json({ message: "Not Authorized, No Token" });
  }
};

// this is a function that return function cause for a middleware we need req,res,next parameters but since we also want to check the role we have to do this
//...allowedRoles --> can accept array of roles can be used if i want to give access of a route to both the role
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    // req.user is available because the 'protect' middleware ran before this.
    // check if req.user exist or if user can access this route or not
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        message: `Role (${req.user ? req.user.role : "none"}) is not authorized to access this route`,
      });
    }
    next(); // to the next middleware
  };
};

export { protect, authorizeRoles };
