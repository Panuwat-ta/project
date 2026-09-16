import { useState } from 'react';
import { useForm } from 'react-hook-form';
import Button from './Button.jsx';
import Dialog from './Dialog.jsx';
import { Textarea } from './fields.jsx';

export default function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  description,
  confirmLabel = 'ยืนยัน',
  danger = false,
  reasonRequired = false,
  reasonLabel = 'เหตุผล',
  confirming = false,
}) {
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm({ defaultValues: { reason: '' } });
  const [formError, setFormError] = useState(null);

  const close = () => {
    reset();
    setFormError(null);
    onClose?.();
  };

  const submit = handleSubmit(async (values) => {
    setFormError(null);
    try {
      await onConfirm(reasonRequired ? values.reason : undefined);
      reset();
    } catch (error) {
      setFormError(error?.message ?? 'ดำเนินการไม่สำเร็จ');
    }
  });

  return (
    <Dialog
      open={open}
      onClose={close}
      title={title}
      description={description}
      danger={danger}
      footer={
        <>
          <Button variant="secondary" onClick={close} disabled={confirming}>
            ยกเลิก
          </Button>
          <Button variant={danger ? 'danger' : 'primary'} onClick={submit} loading={confirming}>
            {confirmLabel}
          </Button>
        </>
      }
    >
      <form onSubmit={submit}>
        {reasonRequired && (
          <Textarea
            id="confirm-reason"
            label={reasonLabel}
            error={errors.reason?.message}
            disabled={confirming}
            {...register('reason', { required: reasonRequired ? 'กรุณาระบุเหตุผล' : false })}
          />
        )}
        {formError && (
          <p role="alert" className="mt-2 text-[13px] font-medium text-bad">
            {formError}
          </p>
        )}
      </form>
    </Dialog>
  );
}
