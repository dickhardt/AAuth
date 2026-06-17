# AAuth Interoperability Demo Profile

This document describes the minimum set of live pieces required to demonstrate end-to-end AAuth interoperability. It is informational — it defines no normative requirements. For the normative protocol, see the [AAuth Protocol specification](draft-hardt-oauth-aauth-protocol.md).

## Overview

A minimal interop demo consists of five verifiable surfaces. Each surface can be built and verified independently; later surfaces build on earlier ones.

## Surface 1 — PS mission approval and blob response

The PS exposes a `mission_endpoint`, accepts a mission proposal from the agent, applies any human-in-the-loop review, and returns the approved mission blob with the `AAuth-Mission` response header.

The agent verifies the `s256` by computing SHA-256 over the exact response body bytes and comparing the result (base64url-encoded, unpadded) to the `s256` value in the `AAuth-Mission` header. The agent MUST store those exact bytes — no re-serialization.

**What to verify:** the PS returns a valid JSON mission blob; the `s256` in the `AAuth-Mission` header matches the SHA-256 of the response body bytes.

## Surface 2 — `AAuth-Mission` presentation and resource-token echo

The agent sends a request to a resource including:
- `AAuth-Mission: approver="<ps-url>"; s256="<hash>"`
- An HTTP Message Signature covering at minimum `@method`, `@authority`, `@path`, and `signature-key`, plus `aauth-mission` when the mission header is present

A mission-aware resource echoes the `{approver, s256}` pair into the `mission` claim of the resource token it issues.

**What to verify:** resource token `mission.approver` matches the `AAuth-Mission` `approver`; `mission.s256` matches the `AAuth-Mission` `s256`. This can be confirmed locally by decoding the resource-token JWT — no live AS required.

## Surface 3 — Resource-token issuance and issuer discovery

The resource signs a resource token as `aa-resource+jwt` with `iss` set to its own identifier and publishes its JWKS at `{iss}/.well-known/aauth-resource.json`.

**What to verify:** fetch `{iss}/.well-known/aauth-resource.json`; confirm `issuer` in the document matches `iss` in the token; locate the key matching the JWT header `kid`; verify the resource-token signature. No PS or AS is required for this surface.

## Surface 4 — Auth-token issuance and presentation

The PS (three-party) or AS (four-party) issues an `aa-auth+jwt` bound to the agent's signing key:
- `cnf.jwk` matches the agent's request signing key
- `aud` matches the resource's identifier
- `mission` echoes the resource-token's `mission` claim (when present)

The agent presents the auth token via `Signature-Key: sig=jwt;jwt="<auth-token>"` on subsequent requests. The resource verifies:
1. Auth-token signature (from issuer JWKS at `{iss}/.well-known/{dwk}`)
2. `cnf.jwk` matches the key that signed the HTTP request
3. `aud` matches its own identifier

## Surface 5 — Parent-mediated sub-agent token handling

1. A sub-agent calls a resource and receives a resource token bound to its own key (`agent_jkt` = thumbprint of sub-agent's key).
2. The sub-agent passes the resource token to the parent out of band.
3. The parent POSTs to the PS with `resource_token` (sub-agent's) and `subagent_token` (sub-agent's agent token).
4. The PS verifies `resource_token.agent_jkt` equals the thumbprint of `subagent_token.cnf.jwk`, and `subagent_token.parent_agent` equals the parent.
5. The issued auth token has `agent` = sub-agent identifier, `cnf.jwk` = sub-agent's key, and `act.agent` = parent agent identifier.

**What to verify:** the resource confirms the auth token is signed with the sub-agent's key and `act.agent` names the parent.

## Deployment Configurations

| Surfaces | What's live |
|----------|-------------|
| 1–3 | Agent + PS + Resource only; no AS needed; can run entirely on localhost |
| 1–4 | Three-party: Agent + PS + Resource; PS issues the auth token |
| 1–4 | Four-party: Agent + PS + Resource + AS; AS issues the auth token |
| 1–5 | Full with sub-agents: all of the above plus sub-agent token flow |

Surfaces 1–3 can be verified with local tools (JWT decoders, `curl`) without any networked third-party dependencies.
