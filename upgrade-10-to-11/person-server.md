# Updating a Person Server from -10 to -11

For a PS implemented against draft-hardt-oauth-aauth-protocol-10. Section numbers refer to -11.

- -10: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-10
- -11: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-11

Each item has an ID for tracking. Items marked **(optional)** add capability; everything else is required to conform to -11.

## Key changes

1. **Issue person tokens.** Add a `person_token_endpoint` (REQUIRED). A resource now verifies a person token before it issues a resource token, so no three- or four-party flow starts without one.
2. **Require `presented_token`.** The auth token endpoint, renamed `auth_token_endpoint`, takes the token the agent presented to the resource and verifies it against the resource token.
3. **Change the auth token.** Remove `agent`, `act`, and `mission`. Add `ps`. `sub` is REQUIRED.
4. **Replace mission references.** `mission_s256` replaces `{approver, s256}` everywhere. The approval response has a new shape. Completion moves to the mission endpoint. `AAuth-Mission` is gone.
5. **Rework revocation.** The request is `{jti, exp}`, the issuer is the signer, there is no `404`, and you answer only once your cascade is finished. In four-party you revoke the person token at the AS.
6. **Change call chaining.** An intermediary gets a person token from you first. `upstream_token` may be a person token. You record the chain.

## Metadata

- [ ] **PS-01 Rename `token_endpoint` to `auth_token_endpoint`.** (§11.2.2)
- [ ] **PS-02 Publish `person_token_endpoint`.** REQUIRED. The conformance floor is exactly `issuer`, `jwks_uri`, `auth_token_endpoint`, and `person_token_endpoint`. (§11.2.2)
- [ ] **PS-03 Publish `revocation_endpoint`.** Was OPTIONAL, now RECOMMENDED. APs revoke agent tokens there, and resources revoke resource tokens. (§11.2.2, §11.12)
- [ ] **PS-04 Update `mission_endpoint` semantics.** A mission's own URL is `{mission_endpoint}/{mission_s256}`. `mission_control_endpoint` is the control plane for parties other than the owning agent. Its protocol is out of scope. (§11.2.2)
- [ ] **PS-05 (optional) Publish `accept_signature_algs`.** This is the exact list of algorithms your verifier accepts. (§11.2)

## Person token endpoint (new)

- [ ] **PS-10 Accept the request.** The agent signs with its agent token under the `jwt` scheme. Parameters:
  - `resource` (REQUIRED): a server identifier. Validate it.
  - `mission_s256`: verify the mission exists, is active, and belongs to this agent. Reject otherwise.
  - `subagent_token`: the signer MUST be named by its `parent_agent`. Its `iss` MUST equal the signer's `iss`, otherwise return `invalid_subagent_token`. The issued `cnf` is the sub-agent's key.
  - `upstream_token`: call chaining. See PS-60.
  - Also accept the auth token request's optional parameters: `capabilities`, `login_hint`, `tenant`, `domain_hint`, `prompt`, `justification`, `platform`, `device`.

  (§7.1)
- [ ] **PS-11 Issue `aa-person+jwt`.**
  - Claims: `iss` (you), `dwk` `aauth-person.json`, `aud` (the resource), a directed `sub`, `cnf.jwk` (the agent's key), `jti`, `iat`, `exp`. Optionally `mission_s256` and `tenant`.
  - MUST NOT carry `scope` or `account`.
  - `exp` is at most 1 hour. It is no later than the agent token, the `upstream_token`, or the mission's `expires_at`.
  - Response: `{ "person_token": "...", "expires_in": N }`.

  (§7.1.2)
- [ ] **PS-12 Decide when to ask the person.**
  - You MAY return `202` with `requirement=interaction`.
  - SHOULD treat the first person token for a resource the person has not used as needing approval.
  - SHOULD fetch that resource's metadata and show its `name`, `description`, and `access_mode`.
  - Without `capabilities`, a PS that must reach the person answers `user_unreachable`.

  (§7.1, §13.8)
- [ ] **PS-13 Retain issuance records.** For each person token, record `jti`, `aud`, `exp`, and each AS you later present it to. Keep the record until `exp` plus clock skew. SHOULD rate-limit how many distinct `resource` values one agent may ask for. (§7.1)

## Directed identifiers

- [ ] **PS-20 Make `sub` stable per resource.**
  - `sub` MUST be unique within your issuer.
  - The same value MUST appear in the person token, in the resource token derived from it, and in every auth token for that resource.
  - It MUST NOT vary with the agent or its key. If you derived `sub` per agent, change that.

  (§14.1)

## Auth token endpoint

- [ ] **PS-30 Require `presented_token`.** It is the person token or auth token the agent presented to the resource, named by the resource token's `presented_jti`. It is REQUIRED on the initial request and on `updated_request`. (§7.2.1, §7.5.2.2)
- [ ] **PS-31 Replace the resource token checks.** (§6.7.2)
  - Remove: `agent` equals the requesting agent, and `mission.approver` equals you.
  - Verify `aud` is you (three-party) and `agent_jkt` matches the signing key, or the `subagent_token`'s key.
  - Verify `ps` names you.
  - Verify `presented_token` by `typ`, as a person token or auth token, with two substitutions: `aud` MUST equal the resource token's `iss`, and `cnf.jwk` MUST match `agent_jkt`.
  - Then check that its `jti` equals `presented_jti`, that its `iss` (person token) or `ps` (auth token) equals the resource token's `ps`, and that `sub`, `mission_s256`, and `tenant` match exactly.
  - Errors: `invalid_presented_token`, `expired_presented_token`, or `invalid_resource_token` for a mismatch.
  - With `mission_s256`, verify the mission is active and not past `expires_at`.
- [ ] **PS-32 Check `presented_token` for revocation and expiry.**
  - Reject a revoked one with `revoked_presented_token`.
  - Never present an expired one to an AS: reject the agent's request with `expired_presented_token`.

  (§9.1.1, §11.12.4)
- [ ] **PS-33 Pass `login_hint` through.** The agent now copies a resource token's `login_hint` into the request unchanged. You MAY ignore it. (§7.2.1)
- [ ] **PS-34 Change the auth token you issue (three-party).** (§9.4.1)
  - `typ` `aa-auth+jwt`, `iss` you, `dwk` `aauth-person.json`, `aud` the resource.
  - `ps` = you (REQUIRED).
  - `sub` = the resource token's `sub` (REQUIRED).
  - `scope` is OPTIONAL. Copy `account`, `mission_s256`, and `tenant`.
  - Remove `agent`, `act`, and `mission`.
- [ ] **PS-35 Cap `exp`.** It is at most 1 hour, and no later than the agent token, the `presented_token`, the `upstream_token` when present, or the mission's `expires_at` when the token carries `mission_s256`. (§9.4.1)
- [ ] **PS-36 Apply the updated-request invariants.** (§7.5.2.2)
  - Verify the new resource token and `presented_token` as in PS-31.
  - The new resource token MUST match the original's `iss`, `ps`, `sub`, `agent_jkt`, `mission_s256`, and `tenant`. Previously this was `iss`, `agent`, `agent_jkt`.
  - `presented_jti` MAY differ, and MUST equal the `jti` of the `presented_token` sent with it.

## Consent

- [ ] **PS-40 Separate agent-asserted content from resource-asserted content.** (§7.4)
  - Resource-asserted: the resource's metadata, the resource token's claims, and an R3 `display` section.
  - Agent-asserted: `justification`, `platform`, `device`, and clarification responses.
  - MUST distinguish the two visually and attribute agent-asserted content to the agent.
  - MUST NOT decide on agent-asserted content alone where resource-asserted content covers the same operation.
  - If a supervision server decides, convey the same distinction to it.

## Federation with an AS (four-party)

- [ ] **PS-50 Call the AS's `auth_token_endpoint`.** (Previously `token_endpoint`.) (§9.1.1)
- [ ] **PS-51 Sign as a server.**
  - Use the `jwks_uri` scheme with `id` = your `issuer` and `dwk` = `aauth-person.json`, for example `sig=jwks_uri;id="https://ps.example";dwk="aauth-person.json";kid="key-1"`.
  - Cover `content-digest` and `content-type`.
  - Previously the example was `sig=jwks_uri; jwks_uri="…"`.

  (§11.3.2, §11.3.3)
- [ ] **PS-52 Send `presented_token`.** The body is `resource_token`, `agent_token`, `presented_token` (REQUIRED), and optionally `subagent_token` and `upstream_token`. (§9.1.1)
- [ ] **PS-53 Replace the delivery checks.** Remove the `agent` and `act` checks. Verify:
  - `iss` is the AS.
  - `aud` is the resource token's `iss`.
  - `cnf.jwk` is the agent's key.
  - `sub` is your directed identifier for that resource.
  - `scope` is no broader than the resource token's.
  - `exp` is no later than the `presented_token` you sent.

  (§9.1.3)
- [ ] **PS-54 Relay AS outcomes.**
  - Relay an AS terminal error in your own problem+json body, with the AS's `error` value and status.
  - Return `as_unreachable` (502) when you cannot get a verifiable auth token: the AS is unreachable, times out, sends a malformed response, or its token fails PS-53.

  (§9.1.3, §11.9.3)
- [ ] **PS-55 Leave `sub` out of `requirement=claims` answers.** Previously you provided the claims "including a directed `sub`". Now `sub` MUST NOT be included. (§9.2)

## Call chaining

In -10 an intermediary sent you a resource token and an upstream auth token, and you built `act`. Without a mission, an intermediary could bypass you and go to an AS. In -11 every hop routes to you. An intermediary is a resource that is its own agent provider.

- [ ] **PS-60 Issue person tokens with `upstream_token`.** (§7.1)
  - The intermediary requests a person token for the downstream resource and presents `upstream_token`.
  - Issue it for the person the upstream token identifies, found from your own record for the upstream token's `aud` and `sub`. Reject the request if you hold no such record.
  - Copy the upstream `mission_s256` into the person token. The intermediary sends none of its own.
  - Cap `exp` at the upstream token's.
- [ ] **PS-61 Rewrite upstream token verification.** (§9.4.5)
  - Accept `aa-person+jwt` or `aa-auth+jwt`. Reject any other `typ` with `invalid_upstream_token`.
  - Verify it with these substitutions: `aud` MUST equal the intermediary's identifier; `cnf.jwk` is not compared with the signing key; the resource's record check on `sub` does not apply.
  - Issuer: a person token's `iss` is you. For an auth token, `ps` is you and `iss` is you or an AS you presented a person token to for that `aud` and `sub`.
  - The upstream token's `aud` MUST equal the `iss` of the intermediary's agent token.
  - Identify the calling agent from your records. If you revoked its agent token or its person binding, reject with `revoked_upstream_token`. If you cannot identify it, reject with `invalid_upstream_token`.
  - Errors: `invalid_upstream_token`, `expired_upstream_token`, `revoked_upstream_token`.
- [ ] **PS-62 Stop building `act`.** Never copy the upstream `sub`. The downstream `sub` comes from the downstream resource token, so there is no longer a case where a downstream token omits `sub`. (§10.1.1.2)
- [ ] **PS-63 Don't bind intermediaries to a person.** An intermediary's agent token is not bound to one person. A request carrying `upstream_token` neither uses nor establishes an agent-person binding. (§10.1.1.1, §13.14)
- [ ] **PS-64 End pending downstream requests on upstream expiry.** A pending downstream request whose upstream token expires ends with `expired`. (§10.1.1)

## Sub-agents

- [ ] **PS-70 Issue person tokens for sub-agents.** A parent obtains a person token for its sub-agent (`subagent_token` at the person token endpoint), and the auth token request then carries `presented_token`. The issued auth token is bound to the sub-agent's key and names neither agent. You record the relationship. (§10.2.3)
- [ ] **PS-71 Check the sub-agent issuer.** Reject a `subagent_token` whose `iss` differs from the signing agent's with `invalid_subagent_token`. (§10.2.1)

## Missions

- [ ] **PS-80 Replace the mission reference with `mission_s256`.** Accept `mission_s256` (the unpadded base64url SHA-256 of the blob) as the parameter on the person token, permission (OPTIONAL), audit (REQUIRED), and interaction endpoints, instead of the `mission` object. Mission status errors key on it. (§7.6.1, §7.7.1, §7.8.1, §8.8)
- [ ] **PS-81 Stop returning `AAuth-Mission`.** Remove `approver` from the blob. The approving PS is identified by being the issuer. (§8.2.1)
- [ ] **PS-82 Return the new approval response.** (§8.2, §8.2.1)
  - Members: `s256`; `mission` (the blob bytes, base64url without padding); `capabilities` (outside the blob and not hashed); and `person_tokens`.
  - Compute `s256` over the exact bytes you persist, return those bytes, and serve the same bytes wherever you expose the mission for audit.
- [ ] **PS-83 Update blob members.** (§8.2)
  - REQUIRED: `agent`, `approved_at`, `description`.
  - OPTIONAL: `expires_at`, `approved_tools`, `approved_resources`.
  - `capabilities` is no longer in the blob.
  - Readers MUST ignore unknown members.
- [ ] **PS-84 Move completion.** Completion is now `POST {mission_endpoint}/{mission_s256}` with `action: completion` and `summary`. Remove `type: completion` from the interaction endpoint. Only the person's acceptance terminates the mission, with reason `completed`. (§8.5, §7.6.1)
- [ ] **PS-85 Make terminated final.** A terminated mission MUST NOT return to `active`. (§8.6)
- [ ] **PS-86 Validate `action` and hide mission existence.** (§8.7)
  - `action` is REQUIRED on a mission's URL. Answer `400` when it is missing or unknown.
  - Answer `mission_not_found` (404) with the same status, body, headers, and equivalent timing whether the mission does not exist or belongs to another agent.
- [ ] **PS-87 (optional) Support mission update.** (§8.4, §13.12)
  - `POST {mission_endpoint}/{mission_s256}` with `action: update` and `description`.
  - Accept it yourself or defer to the person.
  - On acceptance, append it to the log and return `{ "s256": … }` over the update's persisted bytes.
  - The blob and `mission_s256` do not change.
  - SHOULD show the person the approved description plus the updates already accepted.
- [ ] **PS-88 (optional) Support `resources` in a proposal.** Record `approved_resources` in the blob and return `person_tokens` for the ones you approve. (§8.1, §8.2)
- [ ] **PS-89 (optional) Support `expires_at`.** If you set it, every decision path MUST treat a mission past it as terminated. Cap person and auth tokens at it. (§8.2)
- [ ] **PS-90 (optional) Report termination reasons.** Add `termination_reason` to `mission_terminated`: `completed`, `revoked`, `expired`, `superseded`, or `administrative`. (§8.6, §8.8)

## Interaction

- [ ] **PS-95 Restrict interaction types.** The interaction endpoint takes `type` of `interaction`, `payment`, or `question`. (§7.6.1)
- [ ] **PS-96 (optional) Complete interactions out of band.** You MAY complete an interaction you host over a channel you already control, such as a notification the person taps. The code is consumed then. See Appendix B for a PS built this way. (§7.3)

## Signatures and token verification

- [ ] **PS-100 Support `Ed25519`.** It is MUST for every party. Previously it was only for agents and resources. (§11.3.1)
- [ ] **PS-101 Require body coverage.** Require `content-digest` and `content-type` coverage on every request with a body to your endpoints. (§11.3.3)
- [ ] **PS-102 Update signature failure codes.** (§11.3.4)
  - Missing signature headers: `invalid_signature` (was `invalid_request`).
  - `created` ahead of your clock by more than the window: `clock_skew`.
  - A revoked token in `Signature-Key`: `revoked_jwt`.
- [ ] **PS-103 Update JWT checks.** (§11.5.2)
  - `exp` has no clock-skew tolerance.
  - `iat` is no longer a validity check. You MAY refuse a future `iat` with `clock_skew`.
  - `exp` minus `iat` MUST NOT exceed 1 hour for person and auth tokens.
  - Check `typ` before acting on any AAuth JWT.
- [ ] **PS-104 Accept uppercase agent identifiers.** The agent identifier `local` part may contain `A-Z`. Compare exactly and don't case-fold. (§5.2)

## Revocation

- [ ] **PS-110 Change what you accept.** (§11.12.1, §11.12.3)
  - The body is `{jti, exp}`. The issuer is the caller's verified identity under the `jwks_uri` scheme. Key your state by `(iss, jti)`.
  - Require `content-digest` and `content-type` coverage.
  - There is no `404`.
  - Errors: `invalid_request`, `unsupported_iss` (403), `rate_limited` (429, `Retry-After` REQUIRED), `server_error`.
- [ ] **PS-111 Cascade agent token revocations.** (§11.12.4)
  - Deny the agent token.
  - Cascade by the agent's `sub`: revoke every person token and auth token you issued to that agent, whichever agent token it presented. In four-party, also revoke the person tokens at the ASes.
  - Answer the AP with an empty `200` once your cascade is terminal, or with `202` and a pending URL. The AP polls with a signed `GET` under the same identity; answer `404` to a poll from anyone else.
  - Don't report downstream outcomes to the AP.
  - The agent-person binding is unchanged.
- [ ] **PS-112 Accept resource token revocations.** Resources revoke resource tokens whose `aud` is you, or, in four-party, whose `ps` is you. (§11.12.4)
  - Record `(iss, jti)` even if you never saw the token.
  - Reject a request naming it with `revoked_resource_token`.
  - SHOULD end a pending request started for it; the agent sees polling error `revoked`.
- [ ] **PS-113 Change what you send.** (§11.12.2, §11.12.4)
  - Sign as a server, with body `{jti, exp}`.
  - Person token: revoke it at the resource in its `aud` and at each AS you presented it to.
  - Auth token you issued (three-party): revoke it at its resource.
  - Four-party: revoke the person token at the AS instead of revoking the AS's auth token at the resource. Previously you revoked the AS-issued auth token at the resource and MAY notify the AS. The AS now cascades.
  - Call chaining: SHOULD also revoke person tokens you issued from a revoked upstream token.
- [ ] **PS-114 Handle downstream outcomes.** (§11.12.3)
  - Read an AS's `downstream` array.
  - Treat an unreachable or `5xx` party as `revocation_unavailable`, and a party with no endpoint or answering `unsupported_iss` as `revocation_unsupported`.
  - Revocation is idempotent; retry later.
  - Absent `Prefer: wait`, SHOULD hold about 20 seconds before answering `202`.
- [ ] **PS-115 Keep revocation records.** Keep each until `exp` plus clock skew:
  - For each agent token you accept: its `(iss, jti)` and `sub`.
  - For each person token: the upstream `(iss, jti)` when it was issued with `upstream_token`.
  - For each auth token issued or federated against a person token: its `jti`, resource, and `exp`.

  (§11.12.4)

## Error codes

Token endpoint (§11.9.3):

- **Remove:** `invalid_agent_token` and `expired_agent_token`. An agent token in `Signature-Key` that fails is `401` with `Signature-Error`.
- **Add:** `revoked_resource_token`; `invalid_presented_token`, `expired_presented_token`, `revoked_presented_token`; `invalid_upstream_token`, `expired_upstream_token`, `revoked_upstream_token`; `invalid_subagent_token`, `expired_subagent_token`, `revoked_subagent_token`; `clock_skew` (400); `as_unreachable` (502).

Polling (§11.9.4):

- **Add:** `revoked` (403). A token the pending request depends on was revoked. `detail` SHOULD say which.

Mission endpoint (§8.7):

- **Add:** `invalid_request` (400) and `mission_not_found` (404).
