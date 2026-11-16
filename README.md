# Koel on Railway

A one-click Railway template for [Koel](https://koel.dev), the self-hosted personal music streaming server (web player, playlists, podcasts, Subsonic-compatible API).

- **Koel version:** 9.15.0, from the official image `phanan/koel:9.15.0`, pinned by digest in the [`Dockerfile`](Dockerfile).
- **Services:** `Koel` (built from this repo) and Railway's own `Postgres`.
- **Storage:** one volume on Koel at `/data` holding your music (`/data/music`), artwork (`/data/images`) and the search index (`/data/search-indexes`). The database holds users, playlists and library metadata.

## What this wrapper adds

The official image is used as is. The start script ([`railway-start.sh`](railway-start.sh)):

- makes Apache listen on Railway's `PORT`, keeps only the prefork MPM enabled (Railway's build can bring back the base image's disabled `mpm_event`), and keeps every data directory on the `/data` volume;
- runs Koel's own installer (`koel:init`: migrations, first admin, media path, scheduler) on every start;
- replaces the upstream default admin password (`KoelIsCool`) with `KOEL_ADMIN_PASSWORD` **before** the web server starts ([`railway-admin.php`](railway-admin.php)). It only does this while the default password is still in use, so a password you change later in Koel is never overwritten;
- sets fixed production settings: `APP_DEBUG=false`, `FORCE_HTTPS=true`, `TRUSTED_PROXIES=*`, `DB_CONNECTION=pgsql`, logs to stderr;
- starts cron, so Koel's scheduler rescans `/data/music` daily.

## Variables

| Variable | Default in the template | Notes |
|---|---|---|
| `KOEL_ADMIN_EMAIL` | `admin@koel.dev` | E-mail of the first admin account. Change it at deploy time or later in Koel's profile page. |
| `KOEL_ADMIN_PASSWORD` | generated (`secret(24)`) | First admin's password. Read it in Railway → Koel → Variables, then change it in Koel if you like. |
| `APP_KEY` | generated | Laravel encryption key (`base64:` + 32 random bytes). Don't change it after the first deploy. |
| `APP_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL. Update it if you add a custom domain. |
| `PORT` | `8080` | Port Apache listens on. |
| `DB_*` | references to `Postgres` | Database connection over Railway's private network. |

Optional extras (not in the template, add them on the Koel service when you need them): `LASTFM_API_KEY`/`LASTFM_API_SECRET`, `SPOTIFY_CLIENT_ID`/`SPOTIFY_CLIENT_SECRET`, `MEMORY_LIMIT` (MB, for scanning large libraries), S3/Dropbox storage (`STORAGE_DRIVER`, see Koel's [`.env.example`](https://github.com/koel/koel/blob/master/.env.example)).

## Adding music

- Upload songs in Koel's web UI (admin → Upload). They are stored under `/data/music`.
- Or copy files into the volume and rescan: `railway ssh --service Koel` then `su -s /bin/sh -c "php artisan koel:scan" www-data`.

## Updates

This template builds from this repository. When the pinned Koel version is bumped on `main`, Railway shows deployers an "update available" notice, and they choose when to apply it. Read [`CHANGELOG.md`](CHANGELOG.md) first. Database migrations run automatically on start. Back up the Postgres database before a major Koel upgrade.

## Run it locally

```sh
docker build -t koel-railway .
docker run -p 8080:8080 -e PORT=8080 -e FORCE_HTTPS=false -e APP_URL=http://localhost:8080 \
  -e APP_KEY=base64:$(openssl rand -base64 32) -e KOEL_ADMIN_PASSWORD=change-me-please \
  -e DB_HOST=... -e DB_PORT=5432 -e DB_DATABASE=... -e DB_USERNAME=... -e DB_PASSWORD=... \
  -v koel-data:/data koel-railway
```

Koel is MIT-licensed and made by [Phan An and contributors](https://github.com/koel/koel). This repo only packages it for Railway.
