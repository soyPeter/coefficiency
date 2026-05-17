'use client';

import * as React from 'react';

type IdleState = 'active' | 'countdown' | 'expired';

interface UseIdleTimerOptions {
  idleTimeout?: number;
  countdownDuration?: number;
  onExpired?: () => void;
  enabled?: boolean;
}

interface UseIdleTimerResult {
  idleState: IdleState;
  timeLeft: number;
  resetTimer: () => void;
}

const EVENTS = [
  'mousemove', 'mousedown', 'click',
  'keydown', 'keyup',
  'touchstart', 'touchmove',
  'scroll', 'wheel',
] as const;

// REQ-AUTO-001: idle detection
// REQ-AUTO-002: activity reset
export function useIdleTimer({
  idleTimeout = 900000,
  countdownDuration = 60000,
  onExpired,
  enabled = true,
}: UseIdleTimerOptions = {}): UseIdleTimerResult {
  const [idleState, setIdleState] = React.useState<IdleState>('active');
  const [timeLeft, setTimeLeft] = React.useState(Math.floor(countdownDuration / 1000));

  const idleTimeoutRef = React.useRef(idleTimeout);
  const countdownDurationRef = React.useRef(countdownDuration);
  const onExpiredRef = React.useRef(onExpired);
  const idleStateRef = React.useRef(idleState);
  const timerRef = React.useRef<ReturnType<typeof setTimeout>>();
  const intervalRef = React.useRef<ReturnType<typeof setInterval>>();
  const lastActivityRef = React.useRef(Date.now());

  React.useEffect(() => { idleTimeoutRef.current = idleTimeout; }, [idleTimeout]);
  React.useEffect(() => { countdownDurationRef.current = countdownDuration; }, [countdownDuration]);
  React.useEffect(() => { onExpiredRef.current = onExpired; }, [onExpired]);
  React.useEffect(() => { idleStateRef.current = idleState; }, [idleState]);

  const clearTimers = React.useCallback(() => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = undefined;
    }
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = undefined;
    }
  }, []);

  const goActive = React.useCallback(() => {
    clearTimers();
    setIdleState('active');
    setTimeLeft(Math.floor(countdownDurationRef.current / 1000));
  }, [clearTimers]);

  const handleExpired = React.useCallback(() => {
    setIdleState('expired');
    onExpiredRef.current?.();
  }, []);

  const handleActivity = React.useCallback(() => {
    if (idleStateRef.current === 'active') {
      lastActivityRef.current = Date.now();
    } else if (idleStateRef.current === 'countdown') {
      goActive();
    }
  }, [goActive]);

  React.useEffect(() => {
    if (!enabled) return;

    if (idleState === 'active') {
      const elapsed = Date.now() - lastActivityRef.current;
      const remaining = Math.max(0, idleTimeoutRef.current - elapsed);

      timerRef.current = setTimeout(() => {
        setIdleState('countdown');
      }, remaining);
    }

    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [idleState, enabled, idleTimeout]);

  React.useEffect(() => {
    if (!enabled || idleState !== 'countdown') return;

    setTimeLeft(Math.floor(countdownDurationRef.current / 1000));

    intervalRef.current = setInterval(() => {
      setTimeLeft(prev => {
        const next = prev - 1;
        if (next <= 0) {
          clearInterval(intervalRef.current);
          intervalRef.current = undefined;
          handleExpired();
          return 0;
        }
        return next;
      });
    }, 1000);

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [idleState, enabled, handleExpired]);

  React.useEffect(() => {
    if (!enabled) return;

    for (const event of EVENTS) {
      window.addEventListener(event, handleActivity, { passive: true });
    }

    return () => {
      for (const event of EVENTS) {
        window.removeEventListener(event, handleActivity);
      }
    };
  }, [enabled, handleActivity]);

  const resetTimer = React.useCallback(() => {
    lastActivityRef.current = Date.now();
    goActive();
  }, [goActive]);

  return { idleState, timeLeft, resetTimer };
}
