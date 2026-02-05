const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:4002";

function getApiKey(): string {
  if (typeof document === "undefined") return "";
  const match = document.cookie.match(/(?:^|; )api_key=([^;]*)/);
  return match ? decodeURIComponent(match[1]) : "";
}

export interface Lead {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  resume_path: string;
  status: "PENDING" | "REACHED_OUT";
  created_at: string;
  updated_at: string;
}

export interface LeadListResponse {
  items: Lead[];
  total: number;
  page: number;
  page_size: number;
}

export async function fetchLeads(
  page = 1,
  pageSize = 20,
  status?: string
): Promise<LeadListResponse> {
  const params = new URLSearchParams({
    page: String(page),
    page_size: String(pageSize),
  });
  if (status) params.set("status", status);

  const res = await fetch(`${API_URL}:4002/internal/leads?${params}`, {
    headers: { "X-API-Key": getApiKey() },
  });

  if (res.status === 401) {
    // Clear invalid cookie and redirect
    document.cookie = "api_key=; path=/; max-age=0";
    window.location.href = "/login";
    throw new Error("Unauthorized");
  }

  if (!res.ok) throw new Error("Failed to fetch leads.");
  return res.json();
}

export async function updateLeadStatus(
  leadId: string,
  status: "PENDING" | "REACHED_OUT"
): Promise<Lead> {
  const res = await fetch(`${API_URL}:4002/internal/leads/${leadId}`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      "X-API-Key": getApiKey(),
    },
    body: JSON.stringify({ status }),
  });

  if (res.status === 401) {
    document.cookie = "api_key=; path=/; max-age=0";
    window.location.href = "/login";
    throw new Error("Unauthorized");
  }

  if (!res.ok) throw new Error("Failed to update lead.");
  return res.json();
}
