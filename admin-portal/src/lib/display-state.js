import { formatDate } from "./utils.js";

export function hasDisplayValue(value) {
  return value !== null && value !== undefined && value !== "";
}

export function toFiniteNumber(value) {
  if (!hasDisplayValue(value)) return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

export function formatOptionalMetric(value, { suffix = "", digits = null, fallback = "ไม่ได้รายงาน" } = {}) {
  const number = toFiniteNumber(value);
  if (number === null) return fallback;
  const formatted = digits === null ? number.toLocaleString() : number.toFixed(digits);
  return `${formatted}${suffix}`;
}

export function formatOptionalDate(value, fallback = "ไม่มีข้อมูล") {
  if (!hasDisplayValue(value)) return fallback;
  return formatDate(value);
}

export function formatOptionalIdentifier(value, { prefix = "", fallback = "—" } = {}) {
  return hasDisplayValue(value) ? `${prefix}${value}` : fallback;
}

export function getRiskState(score) {
  const numericScore = toFiniteNumber(score);
  if (numericScore === null) {
    return { available: false, score: null, label: "ไม่ทราบ", variant: "default" };
  }
  if (numericScore >= 70) {
    return { available: true, score: numericScore, label: "สูง", variant: "danger" };
  }
  if (numericScore >= 40) {
    return { available: true, score: numericScore, label: "กลาง", variant: "warning" };
  }
  return { available: true, score: numericScore, label: "ต่ำ", variant: "success" };
}

const OPERATIONAL_STATUS = {
  ok: { label: "ปกติ", variant: "success" },
  healthy: { label: "ปกติ", variant: "success" },
  ready: { label: "พร้อมใช้งาน", variant: "success" },
  degraded: { label: "มีข้อจำกัด", variant: "warning" },
  warning: { label: "มีข้อจำกัด", variant: "warning" },
  error: { label: "ใช้งานไม่ได้", variant: "danger" },
  unavailable: { label: "ใช้งานไม่ได้", variant: "danger" },
  down: { label: "ใช้งานไม่ได้", variant: "danger" },
};

export function getOperationalStatus(status) {
  if (!hasDisplayValue(status)) return { label: "ไม่ทราบ", variant: "default" };
  return OPERATIONAL_STATUS[String(status).toLowerCase()] || {
    label: String(status),
    variant: "default",
  };
}

const EVIDENCE_STATUS = {
  available: { label: "มีข้อมูล", variant: "primary" },
  unavailable: { label: "ยังไม่พร้อมใช้งาน", variant: "default" },
  not_checked: { label: "ยังไม่ได้ตรวจ", variant: "default" },
  checked_no_match: { label: "ตรวจแล้ว: ไม่พบภาพตรงกัน", variant: "info" },
  matches_found: { label: "ตรวจแล้ว: พบแหล่งที่มา", variant: "info" },
  error: { label: "ตรวจไม่สำเร็จ", variant: "danger" },
};

export function getEvidenceState(status) {
  if (!hasDisplayValue(status)) return { label: "ไม่ทราบ", variant: "default" };
  const key = String(status).toLowerCase().replaceAll("-", "_");
  return EVIDENCE_STATUS[key] || { label: "ไม่ทราบ", variant: "default" };
}
