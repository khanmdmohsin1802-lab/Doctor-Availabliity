import User from "../models/User.js";
import Doctor from "../models/Doctor.js";

const getDoctors = async (req, res) => {
  try {
    // get required data from the query ---> (work of frontend)
    const { search, specialty, page = 1, limit = 5 } = req.query;

    // create an object
    let query = { role: "doctor" };

    if (search) {
      /* add this in the query object 
       query = {
                role : "doctor", 
                name: { $regex: 'moh', $options: 'i' } 
               }
     */
      query.name = { $regex: search, $option: i };
    }

    // same as query.name
    if (specialty) {
      query.specialty = specialty;
    }

    // Hardcap the Limit --> just incase if the hacker tries to chnage limit=10000 and freeze the database
    let limitNum = parseInt(limit) || 5;
    if (limitNum > 10) limitNum = 10;

    const skipIndex = (page - 1) * limitNum;

    // store all of the doctors that satisfies the query
    const doctors = await User.find(query)
      .select("-password") // remove password for security
      .limit(limitNum)
      .skip(skipIndex)
      .sort({ createdAt: -1 });

    // get the number of total item as per the query to determine Total Pages
    const totalDoctors = await User.countDocuments(query);

    res.status(200).json({
      success: true,
      data: doctors,
      pagination: {
        total: totalDoctors,
        currrentPage: parseInt(page),
        totalPages: totalDoctors / limitNum,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getDoctorInfoById = async (req, res) => {
  try {
    const doctorId = req.params.id;

    const doctor = await User.findById(doctorId).select("-password");

    if (!doctor || doctor.role != "doctor") {
      return res.status(404).json({
        success: false,
        message: "Doctor Not Found",
      });
    }

    res.status(200).json({
      success: true,
      data: doctor,
    });
  } catch (error) {
    console.log(error.message);
    res.staus(500).json({ success: false, message: "Internal Server Error" });
  }
};

export { getDoctors, getDoctorInfoById };
