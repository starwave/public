"use client";

import { useRouter } from "next/navigation";
import { FormEvent, useRef, useState } from "react";
import { submitLead } from "@/lib/api";

export default function LeadForm() {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError("");
    setSubmitting(true);

    const form = e.currentTarget;
    const formData = new FormData(form);

    // Client-side PDF validation
    const file = fileRef.current?.files?.[0];
    if (!file) {
      setError("Please upload your resume.");
      setSubmitting(false);
      return;
    }
    if (file.type !== "application/pdf") {
      setError("Only PDF files are accepted.");
      setSubmitting(false);
      return;
    }
    if (file.size > 10 * 1024 * 1024) {
      setError("File size must not exceed 10 MB.");
      setSubmitting(false);
      return;
    }

    try {
      await submitLead(formData);
      router.push("/thank-you");
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Submission failed.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm"
    >
      {error && (
        <div className="mb-4 rounded-md bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="mb-4">
        <label htmlFor="first_name" className="mb-1 block text-sm font-medium">
          First Name
        </label>
        <input
          id="first_name"
          name="first_name"
          type="text"
          required
          maxLength={100}
          className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
        />
      </div>

      <div className="mb-4">
        <label htmlFor="last_name" className="mb-1 block text-sm font-medium">
          Last Name
        </label>
        <input
          id="last_name"
          name="last_name"
          type="text"
          required
          maxLength={100}
          className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
        />
      </div>

      <div className="mb-4">
        <label htmlFor="email" className="mb-1 block text-sm font-medium">
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          required
          className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
        />
      </div>

      <div className="mb-6">
        <label htmlFor="resume" className="mb-1 block text-sm font-medium">
          Resume / CV (PDF, max 10 MB)
        </label>
        <input
          ref={fileRef}
          id="resume"
          name="resume"
          type="file"
          accept=".pdf,application/pdf"
          required
          className="w-full text-sm file:mr-3 file:rounded-md file:border-0 file:bg-indigo-50 file:px-3 file:py-2 file:text-sm file:font-medium file:text-indigo-700 hover:file:bg-indigo-100"
        />
      </div>

      <button
        type="submit"
        disabled={submitting}
        className="w-full rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
      >
        {submitting ? "Submitting..." : "Submit"}
      </button>
    </form>
  );
}
