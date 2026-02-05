export type NormalizedAccountType = "resident" | "admin_driver";

export function normalizeAccountType(value: string): NormalizedAccountType {
  if (value === "admin_driver" || value === "admin") {
    return "admin_driver";
  }
  return "resident";
}
