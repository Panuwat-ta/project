import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { LogOut, MonitorSmartphone } from 'lucide-react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import { Input } from '../../components/ui/fields.jsx';
import Badge from '../../components/ui/Badge.jsx';
import StatePanel from '../../components/ui/StatePanel.jsx';
import ConfirmDialog from '../../components/ui/ConfirmDialog.jsx';
import Pagination from '../../components/ui/Pagination.jsx';
import { useToast } from '../../components/ui/Toast.jsx';
import { isAbortError } from '../../lib/api-client.js';
import { formatDateTime } from '../../lib/formatters.js';
import { passwordChangeSchema, profileUpdateSchema } from '../../schemas/admin.js';
import { useAuth } from '../auth/AuthContext.jsx';
import { useMe, useRevokeSession, useSessions, useUpdateProfile } from './profile-queries.js';

function ProfileSection() {
  const toast = useToast();
  const me = useMe();
  const update = useUpdateProfile();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(profileUpdateSchema),
    values: me.data ? { full_name: me.data.full_name ?? '' } : undefined,
  });
  const [announcement, setAnnouncement] = useState('');

  if (me.isPending) return <StatePanel state="loading" title="กำลังโหลดโปรไฟล์" />;
  if (me.isError) {
    return (
      <StatePanel
        state="error"
        title="โหลดโปรไฟล์ไม่สำเร็จ"
        hint={me.error?.message}
        actionLabel="ลองอีกครั้ง"
        onAction={() => me.refetch()}
      />
    );
  }

  const submit = handleSubmit(async (values) => {
    try {
      await update.mutateAsync({ full_name: values.full_name || null });
      setAnnouncement('บันทึกโปรไฟล์แล้ว');
      toast.success('บันทึกโปรไฟล์แล้ว');
    } catch (error) {
      if (!isAbortError(error)) toast.error(error?.message ?? 'บันทึกไม่สำเร็จ');
    }
  });

  return (
    <section aria-label="ข้อมูลโปรไฟล์" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
      <h2 className="mb-1 text-base font-bold">ข้อมูลโปรไฟล์</h2>
      <p className="mb-3 text-[13px] text-ink-2">{me.data.email} · บทบาท {me.data.role}</p>
      <form onSubmit={submit} className="flex max-w-md flex-col gap-3">
        <Input id="profile-name" label="ชื่อ-นามสกุล" error={errors.full_name?.message} {...register('full_name')} />
        <div>
          <Button type="submit" loading={isSubmitting || update.isPending}>
            บันทึก
          </Button>
        </div>
      </form>
      <p aria-live="polite" className="sr-only">{announcement}</p>
    </section>
  );
}

function PasswordSection() {
  const toast = useToast();
  const update = useUpdateProfile();
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm({ resolver: zodResolver(passwordChangeSchema) });
  const [announcement, setAnnouncement] = useState('');

  const submit = handleSubmit(async (values) => {
    try {
      await update.mutateAsync({
        current_password: values.current_password,
        new_password: values.new_password,
      });
      reset();
      setAnnouncement('เปลี่ยนรหัสผ่านแล้ว');
      toast.success('เปลี่ยนรหัสผ่านแล้ว');
    } catch (error) {
      if (!isAbortError(error)) toast.error(error?.message ?? 'เปลี่ยนรหัสผ่านไม่สำเร็จ');
    }
  });

  return (
    <section aria-label="เปลี่ยนรหัสผ่าน" className="rounded-xl border border-line bg-surface p-4 sm:p-5">
      <h2 className="mb-3 text-base font-bold">เปลี่ยนรหัสผ่าน</h2>
      <form onSubmit={submit} className="flex max-w-md flex-col gap-3" noValidate>
        <Input
          id="pw-current"
          label="รหัสผ่านเดิม"
          type="password"
          autoComplete="current-password"
          error={errors.current_password?.message}
          {...register('current_password')}
        />
        <Input
          id="pw-new"
          label="รหัสผ่านใหม่ (อย่างน้อย 8 ตัวอักษร)"
          type="password"
          autoComplete="new-password"
          error={errors.new_password?.message}
          {...register('new_password')}
        />
        <Input
          id="pw-confirm"
          label="ยืนยันรหัสผ่านใหม่"
          type="password"
          autoComplete="new-password"
          error={errors.confirm_password?.message}
          {...register('confirm_password')}
        />
        <div>
          <Button type="submit" loading={isSubmitting || update.isPending}>
            เปลี่ยนรหัสผ่าน
          </Button>
        </div>
      </form>
      <p aria-live="polite" className="sr-only">{announcement}</p>
    </section>
  );
}

function SessionsSection() {
  const toast = useToast();
  const { logout } = useAuth();
  const sessions = useSessions();
  const revoke = useRevokeSession();
  const [target, setTarget] = useState(null);
  const [revoking, setRevoking] = useState(false);
  const [page, setPage] = useState(1);
  const PAGE_LIMIT = 10;
  // Backend keeps revoked rows as history: show only sessions still in use so a
  // page reload (which rotates the session) does not grow the visible list.
  const activeItems = (sessions.data?.items ?? []).filter((s) => !s.revoked_at);

  const confirmRevoke = async () => {
    if (!target) return;
    setRevoking(true);
    try {
      await revoke.mutateAsync({ id: target.id });
      toast.success('เพิกถอน session แล้ว');
      setTarget(null);
    } catch (error) {
      if (isAbortError(error)) {
        setTarget(null);
        return;
      }
      throw error;
    } finally {
      setRevoking(false);
    }
  };

  return (
    <section aria-label="Sessions ที่ใช้งาน" className="h-full rounded-xl border border-line bg-surface p-4 sm:p-5">
      <h2 className="mb-3 text-base font-bold">
        Sessions ที่ใช้งาน
        {sessions.data && (
          <span className="ml-2 text-sm font-normal text-ink-2">({activeItems.length})</span>
        )}
      </h2>
      {sessions.isPending ? (
        <StatePanel state="loading" title="กำลังโหลด sessions" className="border-0" />
      ) : sessions.isError ? (
        <StatePanel
          state="error"
          title="โหลด sessions ไม่สำเร็จ"
          hint={sessions.error?.message}
          actionLabel="ลองอีกครั้ง"
          onAction={() => sessions.refetch()}
          className="border-0"
        />
      ) : activeItems.length === 0 ? (
        <p className="text-sm text-ink-muted">ไม่มี session</p>
      ) : (
        <SessionList
          items={activeItems}
          page={page}
          limit={PAGE_LIMIT}
          onPageChange={setPage}
          onRevoke={setTarget}
          onLogout={logout}
        />
      )}
      <ConfirmDialog
        open={target !== null}
        onClose={() => setTarget(null)}
        onConfirm={confirmRevoke}
        title="เพิกถอน session"
        description="ยืนยันเพิกถอน session นี้ อุปกรณ์นั้นจะถูกออกจากระบบทันที"
        confirmLabel="เพิกถอน"
        danger
        confirming={revoking}
      />
    </section>
  );
}

function SessionList({ items, page, limit, onPageChange, onRevoke, onLogout }) {
  const maxPage = Math.max(1, Math.ceil(items.length / limit));
  const safePage = Math.min(page, maxPage);
  const visible = items.slice((safePage - 1) * limit, safePage * limit);
  return (
    <>
      <ul className="flex flex-col gap-2.5">
        {visible.map((session) => (
          <li key={session.id} className="flex flex-wrap items-center gap-2.5 rounded-lg border border-line/60 bg-elevated px-3 py-2.5 text-[13px]">
            <MonitorSmartphone size={16} aria-hidden="true" className="shrink-0 text-ink-muted" />
            <span className="min-w-0 flex-1">
              <span className="block truncate">{session.user_agent ?? 'อุปกรณ์ไม่ทราบ'}</span>
              <span className="block text-xs text-ink-muted">
                {session.ip_address ?? 'IP ไม่ทราบ'} · ใช้ล่าสุด {session.last_used_at ? formatDateTime(session.last_used_at) : '—'}
                {session.expires_at ? ` · หมดอายุ ${formatDateTime(session.expires_at)}` : ''}
              </span>
            </span>
            {session.is_current ? (
              <span className="flex items-center gap-2">
                <Badge tone="info">Session ปัจจุบัน</Badge>
                <Button variant="secondary" size="sm" onClick={() => onLogout()}>
                  <LogOut size={14} aria-hidden="true" />
                  ออกจากระบบ
                </Button>
              </span>
            ) : (
              <Button variant="secondary" size="sm" onClick={() => onRevoke(session)}>
                เพิกถอน
              </Button>
            )}
          </li>
        ))}
      </ul>
      <div className="mt-3 flex justify-center">
        <Pagination page={safePage} total={items.length} limit={limit} onChange={onPageChange} />
      </div>
    </>
  );
}

export default function ProfilePage() {
  return (
    <>
      <PageHeader eyebrow="กำกับดูแล" title="โปรไฟล์" description="ข้อมูลส่วนตัว รหัสผ่าน และ sessions" />
      <div className="grid grid-cols-12 gap-6">
        <div className="col-span-12 flex min-w-0 flex-col gap-6 xl:col-span-6">
          <ProfileSection />
          <PasswordSection />
        </div>
        <div className="col-span-12 min-w-0 xl:col-span-6">
          <SessionsSection />
        </div>
      </div>
    </>
  );
}
