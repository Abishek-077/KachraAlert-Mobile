import type { UserDocument } from "../models/User.js";
import { buildProfileImageUrl } from "./userProfileImage.js";
import { normalizeAccountType } from "./accountType.js";

export function mapUser(user: UserDocument) {
  return {
    id: user._id.toString(),
    accountType: normalizeAccountType(user.accountType),
    name: user.name,
    email: user.email,
    phone: user.phone,
    society: user.society,
    building: user.building,
    apartment: user.apartment,
    isBanned: user.isBanned ?? false,
    lateFeePercent: user.lateFeePercent ?? 0,
    profileImageUrl: user.profileImage?.filename ? buildProfileImageUrl(user._id.toString()) : null
  };
}
