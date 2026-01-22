import { User } from "../models/User.js";

export const userRepository = {
  findByEmail(email: string) {
    return User.findOne({ email: email.toLowerCase() }).exec();
  },
  findById(id: string) {
    return User.findById(id).exec();
  },
  create(data: {
    accountType: "resident" | "admin_driver";
    name: string;
    email: string;
    phone: string;
    passwordHash: string;
    society: string;
    building: string;
    apartment: string;
    termsAcceptedAt: Date;
  }) {
    return User.create(data);
  },
  updatePassword(id: string, passwordHash: string) {
    return User.findByIdAndUpdate(id, { passwordHash }, { new: true }).exec();
  }
};
