export interface HeatmapBox {
  x: number;
  y: number;
  w: number;
  h: number;
  intensity: number;
}

export interface OCRAnalysis {
  status: "SAFE" | "WARNING" | "DANGER";
  details: string;
  flags: string[];
  confidence: number;
}

export interface SourceCheck {
  status: "SAFE" | "WARNING" | "DANGER";
  firstSeen: string;
  frequency: number;
  blacklistLinks: string[];
}

export interface VisualCheck {
  status: "SAFE" | "WARNING" | "DANGER";
  aiGeneratedProb: number;
  anomalyScore: number;
  explanation: string;
  heatmapBoxes: HeatmapBox[];
}

export interface Highlights {
  contact: "SAFE" | "SUSPICIOUS" | "DANGER";
  transaction: "SAFE" | "WARNING" | "DANGER";
}

export interface ScanResult {
  id: string;
  name: string;
  date: string;
  score: number;
  riskLevel: "SAFE" | "WARNING" | "DANGER";
  summary: string;
  ocrText: string;
  ocrAnalysis: OCRAnalysis;
  sourceCheck: SourceCheck;
  visualCheck: VisualCheck;
  highlights: Highlights;
  imageUrl?: string;
}

export type AppScreen =
  | "splash"
  | "welcome"
  | "register"
  | "login"
  | "main"
  | "crop_editor"
  | "scanning"
  | "results"
  | "details"
  | "heatmap"
  | "privacy"
  | "notifications";

export type TabType = "home" | "history" | "report" | "settings";

export interface NotificationItem {
  id: string;
  type: "success" | "warning" | "error";
  title: string;
  message: string;
  time: string;
}
