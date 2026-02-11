import Link from "next/link";

export default function ThankYouPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-4">
      <div className="text-center">
        <div className="mb-4 text-5xl">&#10003;</div>
        <h1 className="text-2xl font-bold text-gray-900">Thank You!</h1>
        <p className="mt-2 text-gray-600">
          Your information has been submitted. An attorney will be in touch
          with you shortly.
        </p>
        <Link
          href="/"
          className="mt-6 inline-block rounded-md bg-indigo-600 px-6 py-2 text-sm font-medium text-white hover:bg-indigo-700"
        >
          Submit Another
        </Link>
      </div>
    </main>
  );
}
