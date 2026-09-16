export const ROUTES = {
  login: '/login',
  dashboard: '/admin/dashboard',
  reports: '/admin/reports',
  reportDetail: (id = ':id') => `/admin/reports/${id}`,
  users: '/admin/users',
  userDetail: (id = ':id') => `/admin/users/${id}`,
  models: '/admin/models',
  dataset: '/admin/dataset',
  auditLog: '/admin/audit-log',
  profile: '/admin/profile',
};

export const NAV_SECTIONS = [
  {
    id: 'overview',
    label: 'ภาพรวม',
    items: [
      { to: ROUTES.dashboard, label: 'แดชบอร์ด' },
      { to: ROUTES.reports, label: 'รายงาน' },
      { to: ROUTES.users, label: 'ผู้ใช้' },
    ],
  },
  {
    id: 'operations',
    label: 'การดำเนินงาน',
    items: [
      { to: ROUTES.models, label: 'โมเดล' },
      { to: ROUTES.dataset, label: 'ชุดข้อมูล' },
    ],
  },
  {
    id: 'governance',
    label: 'กำกับดูแล',
    items: [
      { to: ROUTES.auditLog, label: 'บันทึกตรวจสอบ' },
      { to: ROUTES.profile, label: 'โปรไฟล์' },
    ],
  },
];
