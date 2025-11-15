import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  serverExternalPackages: ['mongoose', 'mongodb'],
  turbopack: {
    resolveAlias: {
      '@yaacovcr/transform': './lib/empty.js',
    },
  },
};

export default nextConfig;
