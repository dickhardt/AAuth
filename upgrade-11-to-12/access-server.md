# Updating an Access Server from -11 to -12

For an AS implemented against draft-hardt-oauth-aauth-protocol-11. Sections are cited by their -12 names.

- -11: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-11
- -12: https://dickhardt.github.io/AAuth/draft-hardt-oauth-aauth-protocol.html (editor's copy, not submitted)

Each item has an ID for tracking. Items marked **(optional)** add capability; everything else is required to conform to -12.

## Key changes

1. **Verify `agent_token`.** Apply Agent Token Verification with step 1 replaced, and answer `invalid_agent_token` or `expired_agent_token`. -11 gave no rule and no code.
2. **Verify `subagent_token`.** Check its signature and `exp`, and that it names `agent_token` as its parent under the same `iss`.
3. **Cap `exp` at the `subagent_token`.** The auth token expires no later than the earliest agent token the request carried.
4. **`sub` belongs to `ps`.** Key per-person state by `(ps, sub)`, not by your own `iss`.
5. **End pending requests on a revoked `presented_token`.** Answer polling `revoked`.

## Metadata

- [ ] **AS-1 Check every `_endpoint` value.** Every metadata member whose name ends in `_endpoint` MUST use `https` and MUST NOT contain a query or fragment. -11 named only `auth_token_endpoint` among yours; -12 adds `revocation_endpoint` and any extension member. (Endpoint and Other URLs)
- [ ] **AS-2 Ignore unknown metadata members.** When you read a PS's or an AP's metadata, MUST ignore members you don't recognize. Don't reject the document for carrying one. (Metadata Documents)
- [ ] **AS-3 (optional) Bind your metadata to a Trust Chain.** You MAY bind `aauth-access.json` and your JWKS to an OpenID Federation Trust Chain per OpenID Federation Well-Known Binding 1.0. (Metadata Documents)

## Token request from the PS

- [ ] **AS-4 Verify `agent_token`.** (PS-to-AS Token Request, Agent Token Verification)
  - -11: no verification rule. Step 1 of Agent Token Verification compares `cnf.jwk` with the key that signed the request, which at the AS is the PS's.
  - -12: MUST verify it per Agent Token Verification with step 1 replaced. For a direct request, `cnf.jwk` MUST match the resource token's `agent_jkt`.
  - Errors: `invalid_agent_token`, or `expired_agent_token` when only `exp` fails.
- [ ] **AS-5 Verify `subagent_token`.** When the request carries one, `agent_token` is the parent's. (PS-to-AS Token Request)
  - Don't compare `agent_token`'s `cnf.jwk` with `agent_jkt`. Compare `agent_jkt` with the `subagent_token`'s `cnf.jwk` instead, as in -11.
  - Verify the `subagent_token` per Agent Token Verification without step 1. This covers its signature and `exp`, which -11 did not check.
  - Check that its `parent_agent` equals `agent_token`'s `sub`, and its `iss` equals `agent_token`'s `iss`.
  - Errors: `invalid_subagent_token`, `expired_subagent_token` when only `exp` fails, or `revoked_subagent_token` when you hold a revocation for it.

## Auth tokens you issue

- [ ] **AS-6 Cap `exp` at the earliest agent token.** (Auth Token Structure)
  - -11: no later than "the agent token used to obtain them".
  - -12: no later than the earliest `exp` of `agent_token` and, when present, `subagent_token`.
  - The other caps are unchanged: 1 hour, `presented_token`, and `upstream_token` when present.
- [ ] **AS-7 Treat `sub` as the PS's.** (Auth Token Structure, Auth Token Verification, Directed Identifiers)
  - -11: `sub` was "unique within `iss`". In an auth token you issue, `iss` is you, though the PS minted `sub`.
  - -12: `sub` is unique within `ps`, and the person is `(ps, sub)`. `(ps, tenant)` identifies the organization.
  - Copy `sub` from the resource token, as before. Key any per-person state you keep, such as a person's binding of their PS at your interaction, by `(ps, sub)`, never by your `iss` and `sub`.
  - Resources trust `ps` because you verified that `presented_token`'s issuer is the PS that signed the request. Keep that check. (PS-to-AS Token Request)

## Pending requests

- [ ] **AS-8 End a pending request when its `presented_token` is revoked.** If the request's `presented_token` is revoked while it waits, for example when the PS revokes that person token at you, answer the PS's next poll with polling `revoked`. The same holds for a `subagent_token` you hold a revocation for. -11 listed only the resource token, the upstream token, and the agent token. (Polling Error Codes, Presenting a Revoked Token)

## Interactions you host

- [ ] **AS-9 Record the decision at your interaction URL.** If you host an interaction, record the person's approve or deny decision through an authenticated channel of your own. -11 put that channel at the PS, even for interactions the PS only relays. The code alone MUST NOT authorize the decision. (Interaction Code Format)
- [ ] **AS-10 Accept only known `callback` values.** At your interaction URL, accept `callback` only on the origin of the requesting agent's `callback_endpoint`, or a loopback URL when that agent's `localhost_callback_allowed` is `true`. MUST ignore any other `callback` and display your completion page. (User Interaction)

## Error codes

Token endpoint (Token Endpoint Error Codes):

- **Add:** `invalid_agent_token` and `expired_agent_token`, at the AS token endpoint only, for the `agent_token` parameter.
- **Widened:** `invalid_subagent_token` now covers a `parent_agent` that does not name `agent_token`'s `sub`, or an `iss` that differs from `agent_token`'s.

Polling (Polling Error Codes):

- **Widened:** `revoked` (403) covers a revoked `presented_token` or `subagent_token`.
