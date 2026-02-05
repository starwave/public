const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:4002";

export async function submitLead(formData: FormData) {
  const res = await fetch(`${API_URL}:4002/leads`, {
    method: "POST",
    body: formData,
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: "Submission failed." }));
    throw new Error(err.detail || "Submission failed.");
  }

  return res.json();
}
