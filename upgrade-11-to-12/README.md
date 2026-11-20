# Updating from AAuth Protocol -11 to -12

These guides are for implementations written against draft-hardt-oauth-aauth-protocol-11. Each one lists what that role must change to conform to -12. Read the one for your role:

| Role | Guide |
|---|---|
| Person Server | [person-server.md](person-server.md) |
| Agent and Agent Provider | [agent-and-agent-provider.md](agent-and-agent-provider.md) |
| Resource, including a resource that calls downstream | [resource.md](resource.md) |
| Access Server | [access-server.md](access-server.md) |

Each item is a checklist entry. It has an ID (for example `PS-3`), states what to change, gives the -11 rule where it differs, and cites the -12 section by name. Items marked **(optional)** add capability; the rest are required. The guides are written so a coding agent can work through them item by item.

-12 is an editor's copy. It has not been submitted to the datatracker.

## What changed in -12

- **The person is `(ps, sub)`.** A resource keys the person on `(ps, sub)` in every token, and never on `(iss, sub)` for an auth token an AS issued.
- **The AS verifies `agent_token`.** Step 1 of Agent Token Verification is replaced. `invalid_agent_token` and `expired_agent_token` return, at the AS only.
- **`subagent_token` skips step 1.** The PS and the AS verify it without step 1, since the parent signs. The AS checks its `parent_agent` and `iss` against `agent_token`.
- **Sub-agent expiry.** Person tokens and auth tokens expire no later than the earliest agent token the request carried, `subagent_token` included.
- **Sub-agent `cnf`.** In parent-mediated authorization, the auth token's `cnf.jwk` is checked against the `subagent_token`'s.
- **Per-endpoint tokens.** An agent presents its agent token where an endpoint answers `requirement=agent-token`, even when it holds an auth token.
- **Authorization endpoint body.** A request with a body to a resource's authorization endpoint covers `content-digest` and `content-type`.
- **Authorization endpoint `scope`.** It is REQUIRED unless a companion parameter, such as R3's `r3_operations`, replaces it.
- **Body components need a body.** Body components named in `additional_signature_components` apply only to requests that carry a body.
- **Polls.** A poll presents the same agent identity and credential type as the request that received the `202`.
- **Polling `revoked`.** It also covers `presented_token`, `subagent_token`, and the agent-person binding.
- **`revoked_jwt`.** A server holding a revocation answers `revoked_jwt` even after the token's `exp`.
- **Interaction hosts.** The host of the interaction URL records the decision and accepts only known `callback` values.
- **Interaction redirects.** The PS does not redirect the person to a loopback, private, or link-local host.
- **Four-party resource interaction.** The PS resolves a resource's interaction before its PS-to-AS token request.
- **Mission update.** The response carries `update`, the bytes `s256` covers.
- **`approved_at`.** It does not make `s256` unique. A PS MAY add a member to tell identical approvals apart.
- **Metadata.** Readers ignore unrecognized members. Every `_endpoint` member is `https` with no query or fragment.
- **OpenID Federation.** A deployment MAY bind its metadata and JWKS to an OpenID Federation Trust Chain.
- **Companion schemes.** The server `jwks_uri` rule covers the requests the protocol defines. AAuth Events uses `self-jwt` at the `event_endpoint`.
