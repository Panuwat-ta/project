import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { ShieldCheck } from 'lucide-react';
import Button from '../../components/ui/Button.jsx';
import { Input } from '../../components/ui/fields.jsx';
import { ApiError, isAbortError } from '../../lib/api-client.js';
import { DEV_DEFAULT_PASSWORD, DEV_DEFAULT_USERNAME } from '../../lib/env.js';
import { loginSchema } from '../../schemas/admin.js';
import { useAuth } from './AuthContext.jsx';
import { RequireAnonymous } from './RequireAuth.jsx';

function LoginForm() {
  const { login } = useAuth();
  const [formError, setFormError] = useState(null);
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(loginSchema),
    defaultValues: { username: DEV_DEFAULT_USERNAME, password: DEV_DEFAULT_PASSWORD },
  });

  const submit = handleSubmit(async (values) => {
    setFormError(null);
    try {
      await login(values);
    } catch (error) {
      if (isAbortError(error)) return;
      // Generic authentication error: never reveal whether the account exists.
      if (error instanceof ApiError && (error.status === 401 || error.status === 400)) {
        setFormError('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
      } else if (error instanceof ApiError && error.status === 403) {
        setFormError('บัญชีนี้ถูกปิดใช้งาน ติดต่อผู้ดูแลระบบ');
      } else {
        setFormError(error?.message ?? 'เข้าสู่ระบบไม่สำเร็จ กรุณาลองอีกครั้ง');
      }
    }
  });

  return (
    <form onSubmit={submit} className="flex flex-col gap-4" noValidate>
      <Input
        id="login-username"
        label="อีเมลผู้ดูแล"
        type="email"
        autoComplete="username"
        error={errors.username?.message}
        {...register('username')}
      />
      <Input
        id="login-password"
        label="รหัสผ่าน"
        type="password"
        autoComplete="current-password"
        error={errors.password?.message}
        {...register('password')}
      />
      {formError && (
        <p role="alert" className="rounded-lg border border-bad bg-surface px-3 py-2 text-sm font-medium text-bad">
          {formError}
        </p>
      )}
      <Button type="submit" loading={isSubmitting}>
        เข้าสู่ระบบ
      </Button>
    </form>
  );
}

export default function LoginPage() {
  return (
    <RequireAnonymous>
      <main className="flex min-h-screen items-center justify-center bg-app px-4">
        <div className="w-full max-w-md rounded-xl border border-line bg-surface p-6 sm:p-8">
          <div className="mb-6 flex items-center gap-3">
            <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-action text-white" aria-hidden="true">
              <ShieldCheck size={22} />
            </span>
            <div>
              <h1 className="text-xl font-bold">ScamGuard Admin</h1>
              <p className="text-[13px] text-ink-2">เข้าสู่ระบบผู้ดูแล</p>
            </div>
          </div>
          <LoginForm />
        </div>
      </main>
    </RequireAnonymous>
  );
}
