# Security notes

This export was checked for common credential patterns and personal build
metadata. That check is not a guarantee of security and does not replace a
full security review.

- Do not commit API tokens, Spotify secrets, signing keys, provisioning
  profiles, device databases, `.env` files or local build logs.
- The app currently stores music preferences as JSON in its private app
  directory. It does not add application-level encryption.
- Network requests go to the music and artwork providers described in the app.
- Use a private communication channel to report vulnerabilities; do not post
  credentials or personal data in public issues.
