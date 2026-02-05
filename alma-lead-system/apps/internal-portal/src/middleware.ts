import { NextRequest, NextResponse } from "next/server";

/*
export function middleware(request: NextRequest) {
  const apiKey = request.cookies.get("api_key")?.value;
  const isLoginPage = request.nextUrl.pathname === "/login";

  if (!apiKey && !isLoginPage) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  if (apiKey && isLoginPage) {
    return NextResponse.redirect(new URL("/leads", request.url));
  }

  return NextResponse.next();
}
*/

export function middleware(request: NextRequest) {
  const apiKey = request.cookies.get("api_key")?.value;
  const isLoginPage = request.nextUrl.pathname === "/login";

  // Detect API calls (adjust path if needed)
  const isApi = request.nextUrl.pathname.startsWith("/api/");

  if (!apiKey) {
    if (isApi) {
      // Return 401 instead of redirect for API
      return new NextResponse(
        JSON.stringify({ error: "Not authenticated" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    if (!isLoginPage) {
      return NextResponse.redirect(new URL("/login", request.url));
    }
  }

  if (apiKey && isLoginPage) {
    return NextResponse.redirect(new URL("/leads", request.url));
  }

  return NextResponse.next();
}


export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.png).*)"],
};
