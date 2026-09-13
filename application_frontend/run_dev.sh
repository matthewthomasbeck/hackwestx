#!/usr/bin/env bash
# Fill AUTH0_DOMAIN + AUTH0_CLIENT_ID below, then: ./run_dev.sh
# Domain = Auth0 Dashboard → Applications → your Native app → Domain (no https://)
# Client ID = same page → Client ID (Native app, not M2M)

set -euo pipefail
cd "$(dirname "$0")"

AUTH0_DOMAIN="${AUTH0_DOMAIN:-PASTE_DOMAIN_HERE}"
AUTH0_CLIENT_ID="${AUTH0_CLIENT_ID:-PASTE_CLIENT_ID_HERE}"

if [[ "$AUTH0_DOMAIN" == "PASTE_DOMAIN_HERE" || "$AUTH0_CLIENT_ID" == "PASTE_CLIENT_ID_HERE" ]]; then
  echo "Edit run_dev.sh (or export AUTH0_DOMAIN / AUTH0_CLIENT_ID) before running."
  exit 1
fi

if [[ "$AUTH0_DOMAIN" == *"://"* ]]; then
  echo "AUTH0_DOMAIN must be host only (e.g. your-tenant.us.auth0.com), no https://"
  exit 1
fi

# Android intent-filter host MUST match Dart AUTH0_DOMAIN or login hangs after browser.
LOCAL_PROPS="android/local.properties"
touch "$LOCAL_PROPS"
if grep -q '^auth0Domain=' "$LOCAL_PROPS"; then
  sed -i.bak "s|^auth0Domain=.*|auth0Domain=${AUTH0_DOMAIN}|" "$LOCAL_PROPS"
  rm -f "${LOCAL_PROPS}.bak"
else
  printf '\nauth0Domain=%s\n' "$AUTH0_DOMAIN" >> "$LOCAL_PROPS"
fi
if grep -q '^auth0Scheme=' "$LOCAL_PROPS"; then
  sed -i.bak "s|^auth0Scheme=.*|auth0Scheme=soothsayer|" "$LOCAL_PROPS"
  rm -f "${LOCAL_PROPS}.bak"
else
  printf 'auth0Scheme=soothsayer\n' >> "$LOCAL_PROPS"
fi

echo "Using AUTH0_DOMAIN=$AUTH0_DOMAIN (also wrote android/local.properties)"
echo "Expected callback: soothsayer://${AUTH0_DOMAIN}/android/com.hackwestx.soothsayer/callback"

exec flutter run \
  --dart-define="AUTH0_DOMAIN=${AUTH0_DOMAIN}" \
  --dart-define="AUTH0_CLIENT_ID=${AUTH0_CLIENT_ID}" \
  "$@"
