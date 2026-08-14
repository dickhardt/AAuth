# AAuth Interoperability Demo Profile

This document describes the minimum set of live pieces required to demonstrate end-to-end AAuth interoperability. It is informational — it defines no normative requirements. For the normative protocol, see the [AAuth Protocol specification](draft-hardt-oauth-aauth-protocol.md).

## Overview

A minimal interop demo consists of five verifiable surfaces. Each surface can be built and verified independently; later surfaces build on earlier ones.

## Surface 1 — PS mission approval and blob response

The PS exposes a `mission_endpoint`, accepts a mission proposal from the agent, applies any human-in-the-loop review, and returns the approval response:

```json
{
  "s256": "<hash>",
  "mission": "<base64url of the mission blob>",
  "capabilities": ["interaction", "payment"],
  "person_tokens": { "https://resource.example": "<person token>" }
}
```

The agent decodes `mission`, computes SHA-256 over the decoded bytes, and compares the result (base64url-encoded, unpadded) to `s256`. Verification is a SHOULD, not a requirement, and the agent is free to store the mission however it likes — the encoded member exists so that the digest covers an unambiguous byte sequence.

`person_tokens` is present when the proposal named `resources`; it carries one mission-scoped person token per approved resource, sparing the agent a request each.

**What to verify:** the `mission` member decodes to valid JSON; `s256` matches the SHA-256 of the decoded bytes.

## Surface 2 — Person-token issuance and presentation

The agent obtains a person token from the PS's `person_token_endpoint`, naming the resource and, when operating under a mission, the mission:

```json
{ "resource": "https://resource.example", "mission_s256": "<hash>" }
```

The PS validates that the mission exists, is active, and belongs to this agent, and issues an `aa-person+jwt` with `aud` set to the resource, a directed `sub`, `cnf.jwk` bound to the agent's signing key, and `mission_s256` when one was named.

The agent presents it to the resource via `Signature-Key: sig=jwt;jwt="<person token>"` in place of its agent token, with an HTTP Message Signature covering at minimum `@method`, `@authority`, `@path`, and `signature-key`.

A resource MUST have verified a person token before it issues a resource token, and copies `ps`, `sub`, `mission_s256`, and the person token's `jti` into the resource token it issues.

**What to verify:** the person token's `cnf.jwk` matches the key that signed the request; the resource token's `ps`, `sub`, and `mission_s256` match the person token, and `presented_jti` names it. This can be confirmed locally by decoding both JWTs — no live AS required.

## Surface 3 — Resource-token issuance and issuer discovery

The resource signs a resource token as `aa-resource+jwt` with `iss` set to its own identifier and publishes its JWKS at `{iss}/.well-known/aauth-resource.json`.

**What to verify:** fetch `{iss}/.well-known/aauth-resource.json`; confirm `issuer` in the document matches `iss` in the token; locate the key matching the JWT header `kid`; verify the resource-token signature. No PS or AS is required for this surface.

## Surface 4 — Auth-token issuance and presentation

The agent sends the resource token to the PS's `auth_token_endpoint`. The PS resolves the person token named by `presented_jti`, confirms the resource token's claims match what it issued, and either issues the auth token itself (three-party) or federates with the resource's AS (four-party).

The issued `aa-auth+jwt` carries:

- `cnf.jwk` matching the agent's request signing key
- `aud` matching the resource's identifier
- `ps` naming the person's PS, and `sub` the directed identifier
- `mission_s256` echoing the resource token's, when present

The agent presents the auth token via `Signature-Key: sig=jwt;jwt="<auth token>"` on subsequent requests. The resource verifies:

1. Auth-token signature (from issuer JWKS at `{iss}/.well-known/{dwk}`)
2. `cnf.jwk` matches the key that signed the HTTP request
3. `aud` matches its own identifier
4. `sub` is present, and `(iss, sub)` matches or establishes its record for this person

Note that no token a resource reads carries an agent identifier. `agent_jkt` in the resource token and `cnf` in every token are the binding.

## Surface 5 — Parent-mediated sub-agent token handling

1. The parent POSTs to the PS's `person_token_endpoint` with `subagent_token` (the sub-agent's agent token); the issued person token's `cnf` is the sub-agent's key. The parent passes it to the sub-agent out of band.
2. The sub-agent presents that person token to a resource and receives a resource token bound to its own key (`agent_jkt` = thumbprint of the sub-agent's key).
3. The sub-agent passes the resource token to the parent out of band.
4. The parent POSTs to the PS's `auth_token_endpoint` with `resource_token` (the sub-agent's) and `subagent_token`.
5. The PS verifies `resource_token.agent_jkt` equals the thumbprint of `subagent_token.cnf.jwk`, and `subagent_token.parent_agent` names the parent.
6. The issued auth token has `cnf.jwk` = the sub-agent's key.

The sub-agent relationship is recorded by the PS, which issued both tokens and holds the `parent_agent` binding. It does not appear in any token the resource sees.

**What to verify:** the resource confirms the auth token is signed with the sub-agent's key; the PS's log records the parent as the requesting agent.

## Deployment Configurations

| Surfaces | What's live |
|----------|-------------|
| 1–3 | Agent + PS + Resource only; no AS needed; can run entirely on localhost |
| 1–4 | Three-party: Agent + PS + Resource; PS issues the auth token |
| 1–4 | Four-party: Agent + PS + Resource + AS; AS issues the auth token |
| 1–5 | Full with sub-agents: all of the above plus sub-agent token flow |

Surfaces 1–3 can be verified with local tools (JWT decoders, `curl`) without any networked third-party dependencies.
