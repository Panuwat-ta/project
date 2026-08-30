import { ScanResult, NotificationItem } from "./types";

// Safety tips displayed on home dashboard
export interface SafetyTip {
  id: string;
  icon: string;
  title: string;
}

export const SAFETY_TIPS: SafetyTip[] = [
  {
    id: "tip1",
    icon: "ShieldAlert",
    title: "เช็คเครื่องหมายยืนยันตัวตนเสมอ"
  },
  {
    id: "tip2",
    icon: "Link",
    title: "ระวังลิงก์แปลกปลอมในข้อความ"
  },
  {
    id: "tip3",
    icon: "AlertTriangle",
    title: "อย่าโอนเงินให้บัญชีบุคคลที่ไม่รู้จัก"
  }
];

// Preset scanning history items for rich initial states
export const INITIAL_HISTORY: ScanResult[] = [
  {
    id: "scan1",
    name: "สลิปโอนเงินต้องสงสัย.jpg",
    date: "24 ต.ค. 2566 • 14:20",
    score: 92,
    riskLevel: "DANGER",
    summary: "พบสัญญาณหลายอย่างที่เกี่ยวข้องกับการหลอกลวง ระบบตรวจพบองค์ประกอบที่น่าสงสัยอย่างมากภายในรูปภาพสลิปนี้",
    ocrText: "ธนาคารพานิชย์ไทย\nโอนเงินสำเร็จ\nนายสมหวัง มั่งมี\nไปยัง นายมิจฉาชีพ บินเดี่ยว\nจำนวนเงิน: 50,000.00 บาท\nRef: 202310241420",
    ocrAnalysis: {
      status: "DANGER",
      details: "พบคำเร่งรัดและชื่อบัญชีปลายทางที่ตรงกับฐานข้อมูลเฝ้าระวังภัยทุจริต ยอดเงินโอนสูงผิดปกติ",
      flags: ["ชื่อบัญชีแบล็คลิสต์", "ฟอนต์ไม่สม่ำเสมอ", "ยอดเงินสูงผิดปกติ"],
      confidence: 98.5
    },
    sourceCheck: {
      status: "DANGER",
      firstSeen: "12 ม.ค. 2567",
      frequency: 42,
      blacklistLinks: ["report-scam-th.org/database", "blacklisted-domains.net/phish"]
    },
    visualCheck: {
      status: "DANGER",
      aiGeneratedProb: 35,
      anomalyScore: 0.82,
      explanation: "ตรวจสอบพบความผิดปกติของการบีบอัดพิกเซล (Compression artifacts) รอบตัวเลข้อ้างอิงและจำนวนเงิน ซึ่งบ่งชี้ว่าอาจมีการตัดต่อข้อความบนสลิป",
      heatmapBoxes: [
        { x: 30, y: 35, w: 40, h: 12, intensity: 90 },
        { x: 35, y: 55, w: 30, h: 8, intensity: 75 }
      ]
    },
    highlights: {
      contact: "SUSPICIOUS",
      transaction: "DANGER"
    },
    imageUrl: "https://images.unsplash.com/photo-1563013544-824ae1d704d3?auto=format&fit=crop&q=80&w=400"
  },
  {
    id: "scan2",
    name: "คิวอาร์โค้ดชำระเงิน.png",
    date: "23 ต.ค. 2566 • 10:45",
    score: 45,
    riskLevel: "WARNING",
    summary: "พบความเสี่ยงระดับปานกลาง ลิงก์จาก QR Code นำทางไปสู่โดเมนจดทะเบียนใหม่ที่มีประวัติไม่ชัดเจน โปรดระมัดระวัง",
    ocrText: "Scan to Pay\nMerchant: FastService Co.\nAmount: 1,200 THB",
    ocrAnalysis: {
      status: "WARNING",
      details: "ข้อมูลการชำระเงินคิวอาร์โค้ดปกติ แต่ลิงก์ที่ถูกแปลงจาก QR นำไปสู่เว็บไซต์บริการชำระเงินบุคคลที่สาม",
      flags: ["ลิงก์ภายนอก", "โดเมนเปิดใหม่"],
      confidence: 95.0
    },
    sourceCheck: {
      status: "WARNING",
      firstSeen: "01 มิ.ย. 2566",
      frequency: 3,
      blacklistLinks: ["quickpay-th.gateway-check.com"]
    },
    visualCheck: {
      status: "SAFE",
      aiGeneratedProb: 5,
      anomalyScore: 0.15,
      explanation: "ไม่พบความผิดปกติในการดัดแปลงรูปภาพ QR Code สัดส่วนและรายละเอียดพิกเซลมีความคมชัดปกติ",
      heatmapBoxes: [
        { x: 40, y: 40, w: 20, h: 20, intensity: 30 }
      ]
    },
    highlights: {
      contact: "SAFE",
      transaction: "WARNING"
    },
    imageUrl: "https://images.unsplash.com/photo-1595079676339-1534801ad6cf?auto=format&fit=crop&q=80&w=400"
  },
  {
    id: "scan3",
    name: "ใบแจ้งหนี้ปลอม.png",
    date: "22 ต.ค. 2566 • 09:12",
    score: 82,
    riskLevel: "DANGER",
    summary: "พบสัญญาณทุจริตในใบแจ้งหนี้ รูปแบบตัวอักษรและบัญชีปลายทางไม่ถูกต้องและอ้างชื่อผู้ส่งเป็นหน่วยงานรัฐ",
    ocrText: "ใบแจ้งหนี้ค่าไฟฟ้าค้างชำระ\nการไฟฟ้าส่วนรวม\nกรุณาชำระเงินทันทีเพื่อหลีกเลี่ยงการงดจ่ายไฟ\nเลขที่บัญชี: 123-4-56789-0",
    ocrAnalysis: {
      status: "DANGER",
      details: "พบการใช้คำข่มขู่หรือสร้างความเร่งด่วน ('งดจ่ายไฟทันที') และใช้บัญชีรับเงินบุคคลธรรมดาแทนบัญชีองค์กร",
      flags: ["บัญชีบุคคลธรรมดา", "สร้างความตื่นตระหนก"],
      confidence: 97.2
    },
    sourceCheck: {
      status: "DANGER",
      firstSeen: "10 พ.ย. 2566",
      frequency: 18,
      blacklistLinks: ["mea-scam-alert.org"]
    },
    visualCheck: {
      status: "WARNING",
      aiGeneratedProb: 12,
      anomalyScore: 0.48,
      explanation: "พบการซ้อนทับภาพโลโก้ที่มีความละเอียดไม่เหมาะสมและรอยหยักพิกเซลขัดแย้งกับข้อความข้างเคียง",
      heatmapBoxes: [
        { x: 15, y: 15, w: 30, h: 15, intensity: 80 }
      ]
    },
    highlights: {
      contact: "SUSPICIOUS",
      transaction: "DANGER"
    },
    imageUrl: "https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&q=80&w=400"
  },
  {
    id: "scan4",
    name: "ลิงก์ข้อความ SMS.jpg",
    date: "21 ต.ค. 2566 • 18:30",
    score: 88,
    riskLevel: "DANGER",
    summary: "ตรวจพบลิงก์ฟิชชิงและข้อความเชิญชวนที่เร่งรีบอย่างน่าสงสัย ห้ามกดลิงก์หรือให้ข้อมูลเด็ดขาด",
    ocrText: "ยินดีด้วย! คุณได้รับสิทธิ์กู้เงินด่วน 50,000 บาท คลิกที่ลิงก์เพื่อรับสิทธิ์ด่วนก่อนหมดเวลา... http://scam-loan-quick.com",
    ocrAnalysis: {
      status: "DANGER",
      details: "ข้อความมีรูปแบบเร่งเร้า (Urgency) และนำเสนอผลประโยชน์ที่เกินจริง ซึ่งเป็นลักษณะเฉพาะของการหลอกลวงแบบ Phishing",
      flags: ["ลิงก์ด่วนก่อนหมดเวลา", "สินเชื่อด่วน", "คลิกที่ลิงก์"],
      confidence: 99.0
    },
    sourceCheck: {
      status: "DANGER",
      firstSeen: "12 ม.ค. 2567",
      frequency: 42,
      blacklistLinks: ["scam-loan-quick.com", "blacklisted-domains.net/phish"]
    },
    visualCheck: {
      status: "SAFE",
      aiGeneratedProb: 10,
      anomalyScore: 0.20,
      explanation: "สกรีนช็อตข้อความมีคุณภาพปกติ แต่เนื้อหาข้อความจัดอยู่ในระดับอันตรายสูงสุด",
      heatmapBoxes: [
        { x: 20, y: 40, w: 60, h: 20, intensity: 85 }
      ]
    },
    highlights: {
      contact: "DANGER",
      transaction: "DANGER"
    },
    imageUrl: "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&q=80&w=400"
  }
];

// Default notifications feed
export const INITIAL_NOTIFICATIONS: NotificationItem[] = [
  {
    id: "notif1",
    type: "success",
    title: "วิเคราะห์เสร็จสิ้น",
    message: "รูปภาพสลิปโอนเงินของคุณวิเคราะห์เสร็จแล้ว",
    time: "2 นาทีที่แล้ว"
  },
  {
    id: "notif2",
    type: "warning",
    title: "พบความเสี่ยงใหม่",
    message: "Scam Alert: ระวังลิงก์ปลอมจาก SMS กู้เงินด่วน",
    time: "1 ชั่วโมงที่แล้ว"
  },
  {
    id: "notif3",
    type: "error",
    title: "งานวิเคราะห์ล้มเหลว",
    message: "ไม่สามารถประมวลผลรูปภาพได้ เนื่องจากขนาดไฟล์ใหญ่เกินไป",
    time: "5 ชั่วโมงที่แล้ว"
  }
];
