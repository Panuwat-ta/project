import React, { useEffect, useState } from "react";
import { Shield, Search } from "lucide-react";

interface SplashProps {
  onNext: () => void;
}

export default function Splash({ onNext }: SplashProps) {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(interval);
          setTimeout(onNext, 500);
          return 100;
        }
        return prev + 5;
      });
    }, 100);

    return () => clearInterval(interval);
  }, [onNext]);

  return (
    <div
      onClick={onNext}
      id="splash-screen"
      className="fixed inset-0 bg-[#014258] bg-[radial-gradient(#025a77_1px,transparent_1px)] [background-size:24px_24px] text-white flex flex-col items-center justify-between py-16 px-6 select-none cursor-pointer transition-all duration-500"
    >
      <div className="flex-1 flex flex-col items-center justify-center text-center">
        {/* Animated Brand Icon */}
        <div className="relative mb-8 p-10 bg-white/10 rounded-[32px] backdrop-blur-md border border-white/20 shadow-2xl animate-pulse">
          <Shield className="w-24 h-24 text-[#00a6d6]" strokeWidth={1.5} />
          <div className="absolute bottom-6 right-6 p-2 bg-[#00a6d6] rounded-full shadow-lg border-2 border-[#014258]">
            <Search className="w-6 h-6 text-white" />
          </div>
        </div>

        {/* Title Group */}
        <h1 className="text-3xl font-bold tracking-tight mb-2 font-sans text-white">
          Scam Image Detection
        </h1>
        <p className="text-xl text-[#bfe9ff] font-sans mb-1">
          ตรวจจับรูปภาพหลอกลวง
        </p>
        <div className="px-3 py-1 bg-white/10 rounded-full inline-block text-[11px] font-semibold tracking-wider text-[#6cd2ff]">
          SECURE & RELIABLE
        </div>
      </div>

      {/* Progress & Bottom Tagline */}
      <div className="w-full max-w-xs flex flex-col items-center gap-4">
        {/* Spinning indicator */}
        <div className="flex items-center gap-3">
          <div className="w-5 h-5 border-2 border-t-transparent border-[#00a6d6] rounded-full animate-spin" />
          <span className="text-sm text-[#bfe9ff] font-sans">
            ตรวจสอบความปลอดภัย... {progress}%
          </span>
        </div>

        {/* Progress bar */}
        <div className="w-full bg-white/10 h-1 rounded-full overflow-hidden">
          <div
            className="bg-[#00a6d6] h-full transition-all duration-100 ease-out"
            style={{ width: `${progress}%` }}
          />
        </div>

        <div className="text-xs text-[#bfe9ff]/60 font-mono mt-2">
          ScamGuard v1.0.0
        </div>
      </div>
    </div>
  );
}
