/**
 * Cloudflare Worker — Security Headers for peteksapp.com
 *
 * Deploy: Cloudflare Dashboard → Workers & Pages → Create Worker → paste this → Deploy
 * Then: Workers & Pages → your worker → Triggers → Add Route → peteksapp.com/*
 */

const SECURITY_HEADERS = {
  // Enforce HTTPS for 1 year, include subdomains
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',

  // Browsers must not sniff content-type (prevents MIME-type confusion attacks)
  'X-Content-Type-Options': 'nosniff',

  // Only send origin as referrer when crossing to another site
  'Referrer-Policy': 'strict-origin-when-cross-origin',

  // Disable browser features not needed by this static site
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), interest-cohort=()',

  // Content Security Policy — tuned for peteksapp.com
  // Sources allowed:
  //   style-src  → self + inline styles (layout) + Google Fonts CSS
  //   font-src   → Google Fonts files
  //   img-src    → self + GitHub Pages (og:image) + data URIs
  //   script-src → none (no JS on this site)
  'Content-Security-Policy': [
    "default-src 'self'",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src https://fonts.gstatic.com",
    "img-src 'self' https://tomercio.github.io data:",
    "script-src 'none'",
    "object-src 'none'",
    "frame-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
  ].join('; '),
};

export default {
  async fetch(request, env, ctx) {
    // Forward the request to GitHub Pages as-is
    const response = await fetch(request);

    // Clone response so we can modify headers (Response is immutable)
    const newResponse = new Response(response.body, response);

    // Inject all security headers
    for (const [name, value] of Object.entries(SECURITY_HEADERS)) {
      newResponse.headers.set(name, value);
    }

    return newResponse;
  },
};
