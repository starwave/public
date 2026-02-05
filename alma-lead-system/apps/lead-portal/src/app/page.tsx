import LeadForm from "@/components/LeadForm";

export default function HomePage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-12">
      <div className="w-full max-w-lg">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-gray-900">Alma</h1>
          <p className="mt-2 text-gray-600">
            Get the help you need. Submit your information below and an
            attorney will reach out to you.
          </p>
        </div>
        <LeadForm />
      </div>
    </main>
  );
}
