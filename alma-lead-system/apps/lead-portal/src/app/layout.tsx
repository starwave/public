import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Alma – Submit Your Information",
  description: "Submit your information to connect with an immigration attorney.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-gray-50 text-gray-900 antialiased">{children}</body>
    </html>
  );
}
