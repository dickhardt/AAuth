# Updating an Agent and Agent Provider from -10 to -11

For an agent or agent provider (AP) implemented against draft-hardt-oauth-aauth-protocol-10. Section numbers refer to -11.

- -10: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-10
- -11: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-11

Each item has an ID for tracking. Items marked **(optional)** add capability; everything else is required to conform to -11.

Agent identity access and resource-managed access are unchanged: the agent presents its agent token, and a session token when the resource issues one. The changes below concern the flows that involve a PS.

## Key changes for an agent

1. **Get a person token before asking for authorization.** Request one from your PS's `person_token_endpoint` for the resource. Present it in `Signature-Key`, in place of your agent token, at the resource's authorization endpoint and wherever the resource answers `requirement=person-token`.
2. **Send `presented_token` with every resource token.** This is the token you presented to the resource that issued it. Send it to your PS's `auth_token_endpoint`, which was renamed from `token_endpoint`.
3. **Replace the mission header.** `mission_s256` replaces `AAuth-Mission` and `{approver, s256}`. You name the mission when you request a person token, and it reaches the resource from there. The approval response has a new shape, and completion moves to the mission endpoint.
4. **Handle the new responses.** These are `requirement=person-token`, `requirement=auth-token` delivered as a `202`, `revoked_jwt`, `clock_skew`, `as_unreachable`, and polling `revoked`.
5. **Refresh with five minutes left.** Refresh top down: agent token, then person token, then resource and auth tokens.

## Key changes for an agent provider

1. **Accept uppercase in agent identifiers.** The `local` part may contain `A-Z`.
2. **Issue sub-agent tokens under the parent's issuer.** A sub-agent token's `iss` MUST equal its parent's.
3. **Send revocations in the new format.** The request is `{jti, exp}`, signed with the `jwks_uri` scheme. The PS cascades by the agent's identifier.

## Agent: discovery and metadata

- [ ] **AG-01 Read the PS's new endpoint fields.** Read `auth_token_endpoint` instead of `token_endpoint`, and read `person_token_endpoint`. (§11.2.2)
- [ ] **AG-02 Handle the new `access_mode` values.** (§11.2.4)
  - The values are `agent-token`, `person-token`, `session-token` (was `aauth-access-token`), and `auth-token`.
  - Under `auth-token`, your first call presents a person token.
  - Treat an unrecognized value as no declaration.
- [ ] **AG-03 (optional) Follow `aauth-resource` links.** (§11.2.5, §13.6)
  - A `Link` header or HTML `link` with `rel="aauth-resource"` names a resource's metadata document.
  - Fetch only a target of the form `{server identifier}/.well-known/aauth-resource.json`, and verify `issuer` as for any metadata document.
  - SHOULD record where you found the link.

## Agent: person tokens (new)

- [ ] **AG-10 Request a person token.** (§7.1)
  - `POST {person_token_endpoint}`, signed with your agent token under the `jwt` scheme.
  - The body has `resource` (REQUIRED) and, when you have one, `mission_s256`.
  - It also takes the auth token request's optional parameters: `capabilities`, `login_hint`, `tenant`, `domain_hint`, `prompt`, `justification`, `platform`, `device`. Send `capabilities`: without it, a PS that must reach the person answers `user_unreachable`.
  - The response is `{ "person_token": "...", "expires_in": N }`, or a `202` deferred response.
- [ ] **AG-11 Cache person tokens.** Cache one per resource, and per mission when you have one, until it expires. Rotating your signing key invalidates all of them; re-request each one the next time you use that resource. (§7.1)
- [ ] **AG-12 Present it where the resource asks.** (§6.4, §6.6, §7.1.3)
  - Present it in `Signature-Key` (`sig=jwt;jwt="<person token>"`) at the authorization endpoint, and on any request the resource answers with `401` and `requirement=person-token`.
  - Once you hold an auth token for the resource, present that instead.
  - An agent without a PS cannot meet `requirement=person-token`; surface it as an error.

## Agent: authorization

- [ ] **AG-20 Update the three- and four-party flow.** (§4.2.4, §4.2.5)
  - -10: agent token at the resource, then a resource token, then `token_endpoint`, then an auth token.
  - -11: a person token at the resource, then a resource token, then `auth_token_endpoint` with `resource_token` and `presented_token`, then an auth token.
- [ ] **AG-21 Always send `presented_token`.** (§7.2.1)
  - It is REQUIRED. It is the token whose `jti` the resource token's `presented_jti` names.
  - That is the person token on the first challenge. On a step-up or per-call challenge, it is the auth token you presented.
- [ ] **AG-22 Change resource challenge verification.** (§6.7.3)
  - Remove the check that `agent` matches your identifier.
  - Check `iss` (the resource you called), `agent_jkt` (your key), `ps` (your PS), `sub` (the value in the token you presented), `presented_jti` (that token's `jti`), and `exp`.
- [ ] **AG-23 Change auth token response verification.** (§9.4.4, §9.1.3)
  - Remove the `agent` and `act` checks.
  - Check `iss` (the resource token's `aud`), `aud` (the resource), `cnf.jwk` (your key), and `sub` (the value in the token you presented).
- [ ] **AG-24 Pass `login_hint` through.** If the resource token carries `login_hint`, send that value unchanged as the `login_hint` parameter. (§6.7.1, §7.2.1)
- [ ] **AG-25 Send `presented_token` with an updated request.** When you answer a clarification with `action: updated_request`, include the `presented_token` you used to get the new resource token. It is REQUIRED. (§7.5.2.2)
- [ ] **AG-26 Support `requirement=auth-token` delivered as `202`.** (§6.5.1)
  - The resource holds your invocation.
  - Get an auth token as for a `401`, then poll the pending URL with signed `GET` requests that present the auth token. The result comes back there.
  - Repeating the same auth token at that URL returns the stored result, so a lost response is safe to retry.
  - You MUST support both the `401` and the `202` delivery.

## Agent: missions

- [ ] **AG-30 Stop sending `AAuth-Mission`.** Also drop `aauth-mission` from covered components. Name the mission with `mission_s256` when you request a person token; the PS puts it in the token and the resource copies it from there. (§4.5, §8.3)
- [ ] **AG-31 Use `mission_s256` everywhere.** Replace the `mission` object `{approver, s256}` with `mission_s256` on the permission (OPTIONAL), audit (REQUIRED), and interaction endpoints. (§7.6.1, §7.7.1, §7.8.1)
- [ ] **AG-32 Parse the new approval response.** (§8.2)
  - -10: the body was the blob and `AAuth-Mission` carried `s256`.
  - -11: read `s256`, decode `mission` (base64url) to the blob bytes, and SHOULD verify `s256` over them before first use.
  - `capabilities` is now top-level and is no longer in the blob.
  - `person_tokens` maps resources to person tokens.
  - The blob has no `approver`.
- [ ] **AG-33 Propose completion at the mission endpoint.** Use `POST {mission_endpoint}/{mission_s256}` with `{ "action": "completion", "summary": "..." }`, not `type: completion` on the interaction endpoint. (§8.5)
- [ ] **AG-34 Read mission termination details.** `mission_terminated` may carry `termination_reason`. `expired` invites a new proposal; `revoked` does not. A mission URL can also answer `mission_not_found` (404). (§8.7, §8.8)
- [ ] **AG-35 (optional) Record changes with mission update.** Use `POST {mission_endpoint}/{mission_s256}` with `{ "action": "update", "description": "..." }`. `mission_s256` does not change. (§8.4)
- [ ] **AG-36 (optional) List resources in a proposal.** Add `resources` to the proposal to receive `person_tokens` in the approval. (§8.1)

## Agent: sub-agents

- [ ] **AG-40 Change the parent-mediated flow.** (§10.2.3)
  - -10: the sub-agent got a resource token with its agent token, and the parent sent it with `subagent_token`.
  - -11, step 1: the parent requests a person token with `resource` and `subagent_token`. It is bound to the sub-agent's key. Hand it to the sub-agent.
  - Step 2: the sub-agent presents it at the resource and gets a resource token.
  - Step 3: the parent sends `resource_token`, `presented_token`, and `subagent_token` to `auth_token_endpoint`.
  - The auth token names neither agent.

## Agent: signing

- [ ] **AG-50 Cover the body on PS and AS requests.** Cover `content-digest` and `content-type` on every request with a body to a PS or AS endpoint. (§11.3.3)
- [ ] **AG-51 Present the right token to each party.** (§11.3.2)
  - Agent token: to the PS and the AP, always. To a resource for agent identity and resource-managed access.
  - Person token: to a resource at its authorization endpoint or where it requires the person's identity.
  - Auth token: to a resource once it has authorized you.
- [ ] **AG-52 Support `Ed25519`.** No change for agents. (§11.3.1)

## Agent: responses and errors

- [ ] **AG-60 Handle `401` signature errors.** (§11.3.4, §11.12.5)
  - `revoked_jwt` on an auth token: get a fresh person token. The resource may say so with `requirement=person-token`.
  - `revoked_jwt` on a person token: get a new one.
  - `revoked_jwt` on your agent token: get a fresh one from your AP.
  - `clock_skew`: your `created`, or a token's `iat`, is ahead of the server's clock. A fresh token from the same issuer has the same skew, so don't refresh. Retry once you are within the window, judged from `Date`, or surface the error.
- [ ] **AG-61 Update token endpoint error handling.** (§11.9.3)
  - `invalid_agent_token` and `expired_agent_token` no longer exist. A bad agent token is `401` with `Signature-Error`.
  - `expired_presented_token` or `revoked_presented_token`: get a fresh person token, then a fresh resource token.
  - `revoked_resource_token`: don't resubmit it; call the resource again.
  - `as_unreachable` (502): retry with a fresh resource token after a backoff.
  - An AS denial arrives with the AS's `error` value.
- [ ] **AG-62 Handle polling `revoked`.** It is `403`: a token the pending request depends on was revoked, and `detail` says which. (§11.9.4)
- [ ] **AG-63 Handle out-of-band completion.** A server may complete an interaction without the person visiting `url`. Keep polling. (§7.3)
- [ ] **AG-64 Restrict interaction types.** Interaction endpoint `type` is `interaction`, `payment`, or `question`. (§7.6.1)

## Agent: refresh

- [ ] **AG-70 Refresh inside a five-minute margin.** (§7.9.1, §7.1.3)
  - SHOULD refresh an agent, person, or auth token when fewer than five minutes remain, and SHOULD NOT present one inside that margin.
  - Refresh top down: agent token, then person token, then resource and auth tokens.
  - A person token is refreshed through the resource's authorization endpoint, presenting the new one.
  - A token presented late gets a short-lived token back: an auth token expires no later than the presented token.

## Agent provider

- [ ] **AP-01 Accept uppercase in agent identifiers.** The `local` part may contain `A-Z`. Comparison is exact and case-sensitive; don't case-fold. (§5.2)
- [ ] **AP-02 Issue sub-agent tokens under the parent's `iss`.** A sub-agent token's `iss` MUST equal its parent's; a PS rejects any other with `invalid_subagent_token`. (§10.2.1)
- [ ] **AP-03 Include `ps` for any agent that has a PS.** It tells a resource a person token can be requested. The PS behind an authorization is the person token's `iss`, not this claim. (§4.5, §5.3.1)
- [ ] **AP-04 Remove `login_endpoint`.** Third-Party Login is gone. (-10 §Third-Party Login)
- [ ] **AP-05 Support `Ed25519`.** It is MUST for every party. (§11.3.1)
- [ ] **AP-06 (optional) Publish `accept_signature_algs`.** (§11.2)
- [ ] **AP-07 Send revocations in the new format.** (§11.12)
  - -10: `{iss, jti}` to the PS.
  - -11: `{jti, exp}` to the PS's `revocation_endpoint`, signed with the `jwks_uri` scheme (`id` = your `issuer`, `dwk` = `aauth-agent.json`), covering `content-digest` and `content-type`.
  - The PS answers an empty `200` once its cascade is finished, or `202`; if `202`, poll with a signed `GET` under the same identity.
  - There is no `404`. Errors are `unsupported_iss` and `rate_limited` (with `Retry-After`).
  - Resending is safe.
  - The PS cascades by the agent's `sub`, so revoking one agent token ends everything the PS issued to that agent. You get no downstream report.
  - A resource that accepted the agent token directly gets no revocation. That access ends when the agent token expires, so keep agent tokens at or under 24 hours.
