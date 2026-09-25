# Updating an Access Server from -10 to -11

For an AS implemented against draft-hardt-oauth-aauth-protocol-10. Section numbers refer to -11.

- -10: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-10
- -11: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-11

Each item has an ID for tracking. Items marked **(optional)** add capability; everything else is required to conform to -11.

## Key changes

1. **Verify `presented_token`.** The endpoint is renamed `auth_token_endpoint`. PS requests carry a REQUIRED `presented_token`, and you verify it against the resource token.
2. **Change the auth token.** Drop `agent`, `act`, and `mission`. Add `ps` and `mission_s256`. Take `sub` from the resource token. `exp` is capped at the presented token's.
3. **Stop asking for identity.** It arrives in the resource token and the presented token, so don't request `sub` through `requirement=claims`.
4. **Cascade person token revocations.** A PS revokes a person token at you, and you revoke the auth tokens you issued against it. Revocation has a new request format and reports `downstream` outcomes.
5. **Verify the PS's new signing identity.** The PS signs with the `jwks_uri` scheme using `id` and `dwk`, and requests cover `content-digest` and `content-type`.

## Metadata

- [ ] **AS-01 Rename `token_endpoint` to `auth_token_endpoint`.** (§11.2.3)
- [ ] **AS-02 Publish `revocation_endpoint`.** Was OPTIONAL, now RECOMMENDED. PSes revoke person tokens there, and resources revoke resource tokens whose `aud` is you. (§11.2.3, §11.12)
- [ ] **AS-03 (optional) Publish `accept_signature_algs`.** (§11.2)

## Token request from the PS

- [ ] **AS-10 Verify the PS signature.** (§11.3.2, §11.3.3)
  - The PS uses the `jwks_uri` scheme with `id` = its `issuer` and `dwk` = `aauth-person.json`. Resolve `id` to the PS's identity.
  - Require `content-digest` and `content-type` coverage.
  - The -10 example used `sig=jwks_uri; jwks_uri="…"`.
- [ ] **AS-11 Accept the new body.** The body is `resource_token`, `agent_token`, `presented_token` (REQUIRED, new), and optionally `subagent_token` and `upstream_token`. `agent_token` stays REQUIRED: it carries posture claims for your decision. For a sub-agent, it is the parent's token. (§9.1.1)
- [ ] **AS-12 Replace the resource token checks.** (§6.7.2, §9.1.1)
  - Remove: `agent` equals the requesting agent, and `mission.approver` equals the PS.
  - Verify `aud` is you, and that `agent_jkt` matches the agent's key, or the `subagent_token`'s key.
  - Verify `presented_token` by `typ`, as `aa-person+jwt` or `aa-auth+jwt`, with two substitutions: `aud` MUST equal the resource token's `iss`, and `cnf.jwk` MUST match `agent_jkt`.
  - Then check that its `jti` equals `presented_jti`, and that its `iss` (person token) or `ps` (auth token) equals the resource token's `ps` and is the PS that signed this request. Check that `sub`, `mission_s256`, and `tenant` match exactly.
  - Errors: `invalid_presented_token`, `expired_presented_token`, or `invalid_resource_token` for a mismatch.
  - On a four-party step-up, the presented token can be an auth token you issued.
- [ ] **AS-13 Bind `subagent_token` requests to the sub-agent.** Bind the auth token to the sub-agent's key. Stop recording the parent in `act`. (§9.1.1)
- [ ] **AS-14 Verify `upstream_token`.** (§9.4.5)
  - It may be a person token or an auth token; reject any other `typ` with `invalid_upstream_token`.
  - Its `aud` MUST equal the `iss` of `agent_token`, the intermediary's agent token.
  - `cnf.jwk` is not compared.
  - Its `iss` (person token) or `ps` (auth token) MUST be the PS that signed the request. Don't check an auth token's `iss` beyond its signature.
  - Errors: `invalid_upstream_token`, `expired_upstream_token`, `revoked_upstream_token`.
  - -10 accepted an auth token only and built `act`. Stop building `act`.
- [ ] **AS-15 Expect every chained request through a PS.** -10 let an intermediary with no mission send a downstream request directly to you. That path is gone: the PS is the only caller. (§10.1.1)
- [ ] **AS-16 Verify updated requests.** A PS answering your clarification with `action: updated_request` sends `resource_token` and `presented_token`. Verify the pair as in AS-12. The new resource token MUST match the original's `iss`, `ps`, `sub`, `agent_jkt`, `mission_s256`, and `tenant`. (§7.5.2.2)
- [ ] **AS-17 Don't request `sub`.** It is a claim of every person and auth token, so an AS MUST NOT request it with `requirement=claims`. Use claims only for what goes beyond identity. (§9.2)

## Auth tokens you issue

- [ ] **AS-20 Change the claims.** (§9.4.1)
  - `typ` `aa-auth+jwt`, `iss` you, `dwk` `aauth-access.json`, `aud` the resource.
  - `ps` = the PS (REQUIRED).
  - `sub` = the resource token's `sub` (REQUIRED).
  - `scope` is OPTIONAL. Copy `account`, `mission_s256`, and `tenant`.
  - `cnf.jwk` is the agent's key, or the sub-agent's.
  - Remove `agent`, `act`, and `mission`.
- [ ] **AS-21 Cap `exp`.** It is at most 1 hour, and no later than `agent_token`, `presented_token`, or `upstream_token` when present. The PS rejects a token that fails this check. (§9.4.1, §9.1.3)
- [ ] **AS-22 Rely on the PS to relay your errors.** The PS relays your terminal errors to the agent with your `error` value and status. It reports an unreachable AS, or a token that fails its checks, as `as_unreachable`. (§9.1.3)

## Signatures and token verification

- [ ] **AS-30 Support `Ed25519`.** It is MUST for every party. Previously it was only for agents and resources. (§11.3.1)
- [ ] **AS-31 Update signature failure codes.** (§11.3.4)
  - Missing signature headers: `invalid_signature` (was `invalid_request`).
  - `created` ahead of your clock by more than the window: `clock_skew`.
- [ ] **AS-32 Update JWT checks.** (§11.5.2)
  - `exp` has no clock-skew tolerance.
  - `iat` is no longer a validity check. You MAY refuse a future `iat` with `clock_skew`.
  - `exp` minus `iat` MUST NOT exceed 1 hour for person and auth tokens.
  - Check `typ` before acting on any AAuth JWT.

## Revocation

- [ ] **AS-40 Accept the new request.** (§11.12.1, §11.12.3)
  - The body is `{jti, exp}`. The issuer is the caller's verified identity under the `jwks_uri` scheme. Key state by `(iss, jti)`.
  - Require `content-digest` and `content-type` coverage.
  - There is no `404`. Errors are `invalid_request`, `unsupported_iss` (403), `rate_limited` (429, `Retry-After` REQUIRED), and `server_error`.
- [ ] **AS-41 Cascade person token revocations.** (§11.12.4, §11.12.3)
  - A PS revokes a person token it presented to you. -10 had the PS revoke your auth tokens at the resource directly.
  - MUST NOT issue further auth tokens against the revoked person token.
  - MUST revoke the auth tokens you issued against it at each resource in their `aud`.
  - Answer `200` once each downstream revocation is terminal, with a `downstream` array: one entry per resource, with `recipient`, and `error` set to `revocation_unsupported` or `revocation_unavailable` when that revocation did not succeed.
  - If the cascade takes longer, answer `202` with a pending URL. The PS polls with a signed `GET`; answer `404` to a poll from anyone else. Absent `Prefer: wait`, SHOULD hold about 20 seconds.
  - A repeated revocation re-attempts the resources that failed.
- [ ] **AS-42 Accept resource token revocations.** A resource revokes a resource token whose `aud` is you. (§11.12.4)
  - Record `(iss, jti)` even if you never saw the token.
  - Reject a request naming it with `revoked_resource_token`.
  - SHOULD end a pending request started for it.
- [ ] **AS-43 Send revocations in the new format.** Send `{jti, exp}` to the resource, signed with the `jwks_uri` scheme (`id` = your `issuer`, `dwk` = `aauth-access.json`), covering `content-digest` and `content-type`. (§11.12.1)
- [ ] **AS-44 Keep issuance records.** For each auth token you issue, record `jti`, resource, `exp`, and the `presented_jti` it was issued against, until `exp` plus clock skew. Record nothing about call chains. (§11.12.4)

## Error codes

Token endpoint (§11.9.3):

- **Add:** `revoked_resource_token`; `invalid_presented_token`, `expired_presented_token`, `revoked_presented_token`; `invalid_upstream_token`, `expired_upstream_token`, `revoked_upstream_token`; `invalid_subagent_token`, `expired_subagent_token`, `revoked_subagent_token`; `clock_skew` (400).
- **Remove:** `invalid_agent_token` and `expired_agent_token`.

**Open in -11 ([#199](https://github.com/dickhardt/AAuth/issues/199)):** at the AS, `agent_token` is a request parameter. The -11 rule is that typed codes exist for tokens carried as parameters, as `<invalid|expired|revoked>_<parameter>_token`. That rule gives `invalid_agent_token` and `expired_agent_token`, yet the -11 table removed them and lists no code for a failing `agent_token`. -11 also never says how the AS verifies `agent_token`: step 1 of Agent Token Verification compares against the signing key, which at the AS is the PS's. The proposal for -12 restores the two codes, and has the AS compare `agent_token`'s `cnf.jwk` with the resource token's `agent_jkt`.
