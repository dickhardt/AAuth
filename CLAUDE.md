# AAuth Project Instructions

## Archive

The `archive/` folder contains historical and superseded documents. Do NOT modify archived files. Contents:

- `aauth-monolith.md` — original monolithic AAuth specification
- `appendixes.md` — orphaned appendix content
- `draft-hardt-aauth-mission.md` — superseded; mission content merged into protocol spec
- `aauth-explainer.md` — superseded; content moving to aauth.dev website
- `comparison-klrc-aauth.md` — comparison document
- `mission-centric-architecture.md` — architectural design notes (superseded; implemented in protocol spec)
- `draft-hardt-aauth-headers.md` — obsolete; content split between HTTP Signature Keys spec and AAuth Protocol spec

## Specifications

All new work happens in these documents:

- `draft-hardt-oauth-aauth-protocol.md` — AAuth Protocol specification (four-party protocol: Agent, Resource, PS, AS; includes missions, authorization endpoint, PS-AS federation). Filename includes `oauth` to signal targeting the IETF OAuth WG; previously named `draft-hardt-aauth-protocol`.
- `draft-hardt-aauth-r3.md` — R3 (Rich Resource Requests) specification

## Building

HTML and TXT outputs are generated from the markdown sources using `mmark` or similar tooling. The `.html` and `.txt` files are generated artifacts.

## Publishing — push tags one at a time

This repo holds multiple drafts. The `publish.yml` workflow uploads **every** draft in the repo on each tag push, not just the tagged one. If two `draft-*` tags are pushed in the same `git push`, both workflow runs race: the first uploads everything successfully, the second fails with datatracker "submission with same name and revision is currently being processed" on every draft. The submissions still go through (from the first run), but the second run is flagged as failed and the surface error is misleading.

Push tags sequentially, waiting for each workflow to finish before pushing the next:

```bash
git push origin draft-hardt-oauth-aauth-protocol-NN
gh run watch  # wait for completion
git push origin draft-hardt-aauth-bootstrap-NN
```
