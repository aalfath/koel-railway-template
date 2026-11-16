# Changelog

Breaking changes are listed first in each entry. Read the entry before you apply an update on Railway.

## 9.15.0 (2026-11-16)

- First release of the Railway template: Koel 9.15.0 (`phanan/koel:9.15.0@sha256:af1ec7daf06d22f6781d9e79716e52048108c21b05adfebccec2e474a29f6fde`) with Railway's Postgres.
- Data on one volume at `/data` (music, artwork, search index).
- The first admin's password comes from `KOEL_ADMIN_PASSWORD` instead of the upstream default.
