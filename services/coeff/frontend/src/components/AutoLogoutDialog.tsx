'use client';

import * as React from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';

// REQ-AUTO-003: countdown modal
// REQ-AUTO-004: stay logged in button
// REQ-AUTO-008: i18n support
interface AutoLogoutDialogProps {
  open: boolean;
  timeLeft: number;
  onStayLoggedIn: () => void;
}

export default function AutoLogoutDialog({ open, timeLeft, onStayLoggedIn }: AutoLogoutDialogProps) {
  const intl = useIntl();

  return (
    <Dialog open={open} onOpenChange={(open) => { if (!open) onStayLoggedIn(); }}>
      <DialogContent showCloseButton={false} className="max-w-sm">
        <DialogHeader>
          <DialogTitle>
            <FormattedMessage id="auth.autoLogout.title" />
          </DialogTitle>
          <DialogDescription className="pt-1">
            <FormattedMessage id="auth.autoLogout.message" values={{ seconds: timeLeft }} />
          </DialogDescription>
        </DialogHeader>
        <div className="flex flex-col items-center py-4">
          <span className="text-4xl font-bold text-foreground tabular-nums">{timeLeft}</span>
          <span className="text-xs text-muted-foreground mt-1">
            <FormattedMessage id="auth.autoLogout.warning" />
          </span>
        </div>
        <DialogFooter>
          <Button variant="default" className="w-full" onClick={onStayLoggedIn} autoFocus>
            <FormattedMessage id="auth.autoLogout.stayLoggedIn" />
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
