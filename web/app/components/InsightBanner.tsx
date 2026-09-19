'use client';

import React from 'react';
import { AIInsight } from '@/lib/api';
import { Compass } from 'lucide-react';

interface InsightBannerProps {
  insight: AIInsight | null;
}

export const InsightBanner: React.FC<InsightBannerProps> = ({ insight }) => {
  if (!insight) return null;

  return (
    <div className="mb-6 p-4 rounded-lg bg-alur-surface border border-alur-border/80 flex items-start gap-3">
      <div className="p-1.5 rounded bg-alur-bg border border-alur-border text-alur-charcoal mt-0.5">
        <Compass size={16} />
      </div>
      <div className="flex-1 min-w-0">
        <h4 className="text-xs font-bold uppercase tracking-wider text-alur-warmgray mb-1 font-title">
          Refleksi Mingguan ALUR
        </h4>
        <p className="text-sm font-normal text-alur-charcoal leading-relaxed">
          {insight.content}
        </p>
      </div>
    </div>
  );
};
