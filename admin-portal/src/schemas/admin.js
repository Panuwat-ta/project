import { z } from 'zod';

// Central runtime contracts for the admin API. Mirrors server/app/schemas/admin.py.
// Extra backend fields are allowed (.passthrough()) so additive changes don't break the UI.

const datetime = z.union([z.string(), z.number()]).nullable().optional();

export const dashboardOverviewSchema = z
  .object({
    total_users: z.number(),
    active_users_today: z.number(),
    total_scans: z.number(),
    scans_today: z.number(),
    scans_this_week: z.number(),
    scans_this_month: z.number(),
  })
  .passthrough();

export const dashboardReportsSchema = z
  .object({
    total: z.number(),
    pending: z.number(),
    reviewing: z.number(),
    approved: z.number(),
    rejected: z.number(),
  })
  .passthrough();

export const dashboardModelSchema = z
  .object({
    active_version: z.string().nullable().optional(),
    deployed_at: datetime,
    total_versions: z.number(),
    a_acc: z.number().nullable().optional(),
    m_iou: z.number().nullable().optional(),
    m_acc: z.number().nullable().optional(),
    m_dice: z.number().nullable().optional(),
  })
  .passthrough();

export const trendItemSchema = z.object({ date: z.string(), count: z.number() }).passthrough();

export const dashboardSchema = z
  .object({
    overview: dashboardOverviewSchema,
    risk_distribution: z.record(z.string(), z.number()),
    reports: dashboardReportsSchema,
    category_breakdown: z.record(z.string(), z.number()),
    model: dashboardModelSchema,
    scan_trend: z.array(trendItemSchema),
  })
  .passthrough();

export const healthSchema = z
  .object({
    database: z.string(),
    storage: z.string(),
    models: z.string(),
    queue: z.string(),
    last_check: z.union([z.string(), z.number()]),
  })
  .passthrough();

export const searchItemSchema = z
  .object({
    id: z.string(),
    type: z.string(),
    title: z.string(),
    subtitle: z.string().nullable().optional(),
    url: z.string(),
  })
  .passthrough();

export const searchResponseSchema = z
  .object({ items: z.array(searchItemSchema), total: z.number() })
  .passthrough();

export const reportUserSchema = z
  .object({
    id: z.number(),
    email: z.string(),
    full_name: z.string().nullable().optional(),
    total_reports_submitted: z.number().nullable().optional(),
  })
  .passthrough();

export const reportScanBriefSchema = z
  .object({
    id: z.string(),
    thumbnail_url: z.string().nullable().optional(),
    total_risk_score: z.number(),
    risk_grade: z.string(),
  })
  .passthrough();

export const reportListItemSchema = z
  .object({
    id: z.number(),
    user: reportUserSchema.nullable().optional(),
    scan: reportScanBriefSchema.nullable().optional(),
    category: z.string(),
    description: z.string(),
    platform: z.string().nullable().optional(),
    reference_url: z.string().nullable().optional(),
    allow_research_use: z.boolean(),
    status: z.string(),
    admin_note: z.string().nullable().optional(),
    moderated_by: z.number().nullable().optional(),
    moderated_at: datetime,
    created_at: z.union([z.string(), z.number()]),
    version: z.number(),
  })
  .passthrough();

export const reportListSchema = z
  .object({
    items: z.array(reportListItemSchema),
    total: z.number(),
    page: z.number(),
    limit: z.number(),
  })
  .passthrough();

export const reportDetailSchema = reportListItemSchema
  .extend({ scan: z.record(z.string(), z.unknown()).nullable().optional() })
  .passthrough();

export const decisionSchema = z.object({
  status: z.enum(['approved', 'rejected']),
  admin_note: z.string().min(1, 'กรุณาระบุเหตุผลประกอบการตัดสิน'),
});

export const userSchema = z
  .object({
    id: z.number(),
    email: z.string(),
    full_name: z.string().nullable().optional(),
    role: z.string(),
    is_active: z.boolean(),
    total_scans: z.number().default(0),
    total_reports: z.number().default(0),
    created_at: z.union([z.string(), z.number()]),
    updated_at: z.union([z.string(), z.number()]),
  })
  .passthrough();

export const userListSchema = z
  .object({ items: z.array(userSchema), total: z.number(), page: z.number(), limit: z.number() })
  .passthrough();

export const userDetailSchema = userSchema
  .extend({
    stats: z
      .object({
        total_scans: z.number(),
        scans_this_month: z.number(),
        total_reports_submitted: z.number(),
        reports_approved: z.number(),
        reports_rejected: z.number(),
        reports_pending: z.number(),
      })
      .passthrough(),
    recent_scans: z.array(z.record(z.string(), z.unknown())),
    recent_reports: z.array(z.record(z.string(), z.unknown())),
    ban_reason: z.string().nullable().optional(),
  })
  .passthrough();

export const userUpdateSchema = z.object({
  is_active: z.boolean(),
  reason: z.string().min(1, 'กรุณาระบุเหตุผล'),
});

export const modelVersionSchema = z
  .object({
    id: z.number(),
    version_tag: z.string(),
    file_path: z.string(),
    is_active: z.boolean(),
    deployed_at: datetime,
    artifact_checksum: z.string().nullable().optional(),
    framework_compatibility: z.string().nullable().optional(),
    a_acc: z.number().nullable().optional(),
    m_iou: z.number().nullable().optional(),
    m_acc: z.number().nullable().optional(),
    m_dice: z.number().nullable().optional(),
    dataset_reference: z.string().nullable().optional(),
    created_by: z.number().nullable().optional(),
    status: z.string(),
    deployment_history: z.unknown().nullable().optional(),
  })
  .passthrough();

export const modelListSchema = z
  .object({ items: z.array(modelVersionSchema), total: z.number() })
  .passthrough();

export const deployModelSchema = z.object({
  reason: z.string().min(1, 'กรุณาระบุเหตุผลในการ deploy'),
});

export const dryRunSchema = z
  .object({
    success: z.boolean(),
    message: z.string(),
    details: z.record(z.string(), z.unknown()).nullable().optional(),
  })
  .passthrough();

export const exportCreateSchema = z.object({
  categories: z.array(z.string()).optional(),
  from_date: z.string().optional(),
  to_date: z.string().optional(),
  include_metadata: z.boolean().default(true),
  format: z.string().default('zip'),
});

export const exportJobSchema = z
  .object({
    id: z.string(),
    status: z.string(),
    progress: z.number(),
    total_rows: z.number().nullable().optional(),
    file_size_bytes: z.number().nullable().optional(),
    error_message: z.string().nullable().optional(),
    created_at: z.union([z.string(), z.number()]),
    completed_at: datetime,
    expires_at: datetime,
  })
  .passthrough();

export const exportJobListSchema = z
  .object({ items: z.array(exportJobSchema), total: z.number(), page: z.number(), limit: z.number() })
  .passthrough();

export const auditLogSchema = z
  .object({
    id: z.number(),
    admin_id: z.number().nullable().optional(),
    action: z.string(),
    entity_type: z.string().nullable().optional(),
    entity_id: z.string().nullable().optional(),
    before_state: z.record(z.string(), z.unknown()).nullable().optional(),
    after_state: z.record(z.string(), z.unknown()).nullable().optional(),
    reason: z.string().nullable().optional(),
    ip_address: z.string().nullable().optional(),
    user_agent: z.string().nullable().optional(),
    request_id: z.string().nullable().optional(),
    details: z.string().nullable().optional(),
    created_at: z.union([z.string(), z.number()]),
  })
  .passthrough();

export const auditLogListSchema = z
  .object({ items: z.array(auditLogSchema), total: z.number(), page: z.number(), limit: z.number() })
  .passthrough();

export const adminProfileSchema = z
  .object({
    id: z.number(),
    email: z.string(),
    full_name: z.string().nullable().optional(),
    role: z.string(),
    is_superadmin: z.boolean(),
  })
  .passthrough();

export const profileUpdateSchema = z.object({
  full_name: z.string().optional(),
});

export const passwordChangeSchema = z
  .object({
    current_password: z.string().min(1, 'กรุณากรอกรหัสผ่านเดิม'),
    new_password: z.string().min(8, 'รหัสผ่านใหม่ต้องยาวอย่างน้อย 8 ตัวอักษร'),
    confirm_password: z.string().min(1, 'กรุณายืนยันรหัสผ่านใหม่'),
  })
  .refine((data) => data.new_password === data.confirm_password, {
    message: 'รหัสผ่านใหม่ไม่ตรงกัน',
    path: ['confirm_password'],
  });

export const adminSessionSchema = z
  .object({
    id: z.string(),
    is_current: z.boolean().default(false),
    user_agent: z.string().nullable().optional(),
    ip_address: z.string().nullable().optional(),
    created_at: datetime,
    last_used_at: datetime,
    expires_at: datetime,
    revoked_at: datetime,
  })
  .passthrough();

export const adminSessionListSchema = z
  .object({ items: z.array(adminSessionSchema), total: z.number() })
  .passthrough();

export const loginSchema = z.object({
  username: z.string().min(1, 'กรุณากรอกอีเมลผู้ดูแล'),
  password: z.string().min(1, 'กรุณากรอกรหัสผ่าน'),
});
