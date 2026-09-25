# Updating a Resource from -10 to -11

For a resource implemented against draft-hardt-oauth-aauth-protocol-10. Section numbers refer to -11.

- -10: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-10
- -11: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-11

Each item has an ID for tracking. Items marked **(optional)** add capability; everything else is required to conform to -11.

A resource that uses only agent identity access or resource-managed access needs only RS-01 to RS-04 and RS-50 to RS-52. Everything else applies to a resource that issues resource tokens.

## Key changes

1. **Verify a person token before issuing a resource token.** Accept an auth token too. With neither, answer `401` with `requirement=person-token`. Your authorization endpoint requires a person token.
2. **Change resource token claims.** Add `ps`, `sub`, and `presented_jti`. Copy `mission_s256` and `tenant`. Drop `agent` and `mission`. In three-party, `aud` is the PS that issued the person token, not the agent token's `ps`.
3. **Change auth token checks.** Auth tokens have no `agent` or `act`, and `sub` is REQUIRED. Identify the person by `(iss, sub)`.
4. **Read the mission from the person token.** `AAuth-Mission` is gone. The mission arrives as `mission_s256` in the person token.
5. **Update revocation.** Accept the new request format. You may receive person token revocations and send resource token revocations. Answer a revoked token with `revoked_jwt`.
6. **Chain downstream calls through the PS.** If you call downstream resources, be your own agent provider, get a person token first, and route to the PS the upstream token names.

## Metadata

- [ ] **RS-01 Update `access_mode` values.** (§11.2.4)
  - The values are `agent-token`, `person-token`, `session-token` (was `aauth-access-token`), and `auth-token`.
  - Under `auth-token`, the agent's first call presents a person token.
- [ ] **RS-02 Remove `login_endpoint`.** Third-Party Login is gone. (-10 §Third-Party Login)
- [ ] **RS-03 Publish `revocation_endpoint` if you accept person tokens.** It is RECOMMENDED for a resource that accepts person tokens. A resource that accepts only agent tokens receives no revocations and need not publish one. -10 said the opposite: a resource accepting agent tokens SHOULD have one. (§11.2.4, §11.12)
- [ ] **RS-04 (optional) Publish `accept_signature_algs`.** Also, SHOULD add an `aauth-resource` link pointing at `{issuer}/.well-known/aauth-resource.json` on the page at your `documentation_uri`. (§11.2, §11.2.5)

## Person tokens (new)

- [ ] **RS-10 Verify person tokens.** (§7.1.4, §11.5.2)
  - `typ` is `aa-person+jwt` and `dwk` is `aauth-person.json`. Keys come from `{iss}/.well-known/aauth-person.json`.
  - `exp` is in the future, with no tolerance, and `exp` minus `iat` is at most 1 hour.
  - `aud` is your identifier.
  - `cnf.jwk` is present, structurally complete, and matches the key that signed the request.
  - Identify the person by `(iss, sub)`. Treat `sub` as opaque, and never match a `sub` from one issuer against a record from another.
  - `tenant` is organization context, not part of the identifier.
  - A person token is not evidence of identity proofing.
- [ ] **RS-11 Challenge for a person token.** When you need the person and the request carries no person token, answer `401` with `AAuth-Requirement: requirement=person-token`. The header takes no parameters. (§6.4)
- [ ] **RS-12 Keep person tokens and auth tokens apart.** Check `typ` first, and reject `aa-person+jwt` wherever an auth token is required. The two differ only in `typ`, and this check fails open if missed. (§13.11)
- [ ] **RS-13 (optional) Serve on person identity.** You MAY serve requests on a person token alone (person identity access), and challenge with `requirement=auth-token` only where you need consent or policy. Declare `access_mode: person-token`. (§4.2.3)

## Authorization endpoint

- [ ] **RS-20 Require a person token.** (§6.6)
  - -10: the agent signed with its agent token, plus `AAuth-Mission`.
  - -11: the agent MUST present a person token and you MUST verify it (RS-10).
  - With no person token, answer `requirement=person-token`.
- [ ] **RS-21 Update the error table.** (§6.6.3)
  - Remove `invalid_signature`. A failing person token is `401` with `Signature-Error`.
  - Add `invalid_account` (400): the `account` is not held by the person the person token identifies.

## Resource tokens

- [ ] **RS-30 Issue a resource token only after verifying a token.** You MUST verify a person token or an auth token on the request first. On the authorization endpoint that is the person token; elsewhere it is whichever the request carried. With neither, answer `requirement=person-token`. (§6.7)
- [ ] **RS-31 Set `aud` from the PS or your AS.** (§6.7)
  - Four-party: your AS.
  - Three-party: the PS in `ps`, which is the `iss` of the person token you verified.
  - -10 took the three-party `aud` from the agent token's `ps` claim. Don't.
- [ ] **RS-32 Change the claims.** (§6.7.1)
  - Remove: `agent` and `mission`.
  - Add, REQUIRED: `ps` (the person token's `iss`, or the auth token's `ps`), `sub` (copied from that token), and `presented_jti` (that token's `jti`).
  - Add, OPTIONAL: `mission_s256` (REQUIRED when the token carried one; copy it unchanged), `tenant` (copied), and `login_hint`.
  - Unchanged: `iss`, `dwk`, `jti`, `iat`, `exp`, `agent_jkt`, `scope`, `account`, `interaction`.
- [ ] **RS-33 Stop reading `AAuth-Mission`.** Remove the header handling and the `aauth-mission` covered component. The mission comes from the person token's `mission_s256`. (§4.5)
- [ ] **RS-34 Point step-ups at the auth token.** When you challenge a request that carries an auth token, `presented_jti` is that auth token's `jti`, and `ps` and `sub` come from it. (§6.5, §6.7.1)
- [ ] **RS-35 (optional) Set `login_hint`.** When you know who the authorization is for, set `login_hint`. The PS MAY ignore it, so check the auth token's claims rather than assuming it was honored. (§6.7.1)
- [ ] **RS-36 (optional) Deliver `requirement=auth-token` as `202`.** (§6.5.1, §13.2)
  - Answer `202` with a pending URL and hold the invocation.
  - Execute it on the first poll that presents a valid auth token, and return its response.
  - Retain the result, keyed by the auth token's `jti`, until that token's `exp`. Answer a repeated presentation from the stored result instead of executing again.
  - You MAY put a fresh resource token in a later poll response if the first expires.

## Auth tokens

- [ ] **RS-40 Change auth token verification.** (§9.4.3)
  - Remove the `agent` check, the `act` check, and the "at least one of `sub` or `scope`" check.
  - Verify that `sub` is present, and that `(iss, sub)` matches or establishes your record for the person.
  - `ps` names the person's PS.
  - Use `(iss, sub)` as the identifier, not `(iss, tenant, sub)`.
- [ ] **RS-41 Stop checking the agent token behind an auth token.** -10 said a resource MUST reject an auth token whose agent token had expired. You can't see the agent token now, and the issuer caps `exp`. (§7.9)
- [ ] **RS-42 Check the new claims.** Expect `mission_s256` in place of `mission`. There is no `act`. (§9.4.1)
- [ ] **RS-43 Answer a revoked token with `revoked_jwt`.** (§11.12.5)
  - A revoked person token or auth token in `Signature-Key` gets `401` with `Signature-Error: error=revoked_jwt`.
  - For a revoked auth token, SHOULD add `AAuth-Requirement: requirement=person-token`.
  - MUST NOT answer with `requirement=auth-token` and a resource token.

## Signatures and token verification

- [ ] **RS-50 Update signature failure codes.** (§11.3.4)
  - Missing signature headers: `invalid_signature` (was `invalid_request`).
  - `created` ahead of your clock by more than the window: `clock_skew`.
  - A revoked token: `revoked_jwt`.
- [ ] **RS-51 Update JWT checks.** (§11.5.2)
  - `exp` has no clock-skew tolerance.
  - `iat` is no longer a validity check. You MAY refuse a future `iat` with `clock_skew`.
  - `exp` minus `iat` MUST NOT exceed 1 hour for person and auth tokens.
- [ ] **RS-52 Accept uppercase agent identifiers.** The agent identifier `local` part may contain `A-Z`. Compare exactly and don't case-fold. This matters in agent identity access, where you key on it. (§5.2)

## Revocation

- [ ] **RS-60 Accept the new request.** (§11.12.1, §11.12.3)
  - The body is `{jti, exp}`. The issuer is the caller's verified identity under the `jwks_uri` scheme. Key state by `(iss, jti)`, and drop it after `exp` plus clock skew.
  - Require `content-digest` and `content-type` coverage.
  - Answer `200` with an empty body at once. You have nothing downstream, so never answer `202`.
  - There is no `404`. Errors are `invalid_request`, `unsupported_iss` (403), `rate_limited` (429, `Retry-After` REQUIRED), and `server_error`.
- [ ] **RS-61 Know who revokes what at you.** (§11.12.2, §11.12.4)
  - A PS revokes the person tokens it issued for you, and the auth tokens it issued (three-party).
  - An AS revokes the auth tokens it issued.
  - After a person token revocation, refuse requests presenting it and MUST NOT issue a resource token naming it.
- [ ] **RS-62 (optional) Revoke resource tokens.** (§11.12.4)
  - Send `{jti, exp}` to the revocation endpoint of the token's `aud`, and in four-party to the `ps` as well.
  - Sign with the `jwks_uri` scheme (`id` = your `issuer`, `dwk` = `aauth-resource.json`), covering `content-digest` and `content-type`.

## If you call downstream resources (call chaining)

In -10 you published agent metadata and sent the downstream resource token, with the upstream auth token, to `mission.approver` or to the upstream `iss`, which could be an AS. In -11:

- [ ] **RS-70 Be your own agent provider.** (§10.1.1.1)
  - Publish `/.well-known/aauth-agent.json` on your origin with `issuer` equal to your resource `issuer`.
  - Sign downstream requests with an agent token you issued to yourself. Its `iss` is your resource identifier, and its `sub` has your host as `domain`.
  - An agent token from any other AP is rejected with `invalid_upstream_token`.
- [ ] **RS-71 Know what counts as the upstream token.** It is the person token or auth token the calling agent presented on a request you served. A person token you answered with a challenge does not count. (§10.1.1)
- [ ] **RS-72 Route to the upstream token's PS.** Send downstream requests to the PS the upstream token names: the `iss` of a person token, or the `ps` of an auth token. Not `mission.approver`, and never directly to an AS. (§10.1.1)
- [ ] **RS-73 Follow the new flow.** (§10.1.1, §7.1, §7.2.1)
  - `POST person_token_endpoint` with `resource` (the downstream resource) and `upstream_token`.
  - Present that person token downstream and receive a resource token.
  - `POST auth_token_endpoint` with `resource_token`, `presented_token` (the person token), and `upstream_token`.
  - Sign each request with your own agent token under the `jwt` scheme, and cover `content-digest` and `content-type`.
- [ ] **RS-74 Expect downstream tokens to expire with the upstream token.** Downstream person and auth tokens expire no later than the upstream token. After that, use a later token from the calling agent. A pending downstream request whose upstream token expires ends with `expired`. (§10.1.1)
- [ ] **RS-75 Stop expecting `act`.** No token carries a delegation chain now. (§9.4.1)
