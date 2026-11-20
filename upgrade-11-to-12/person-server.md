# Updating a Person Server from -11 to -12

For a PS implemented against draft-hardt-oauth-aauth-protocol-11. Sections are cited by their -12 names.

- -11: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-11
- -12: https://dickhardt.github.io/AAuth/draft-hardt-oauth-aauth-protocol.html (editor's copy, not submitted)

Each item has an ID for tracking. Items marked **(optional)** add capability; everything else is required to conform to -12.

## Key changes

1. **Verify `subagent_token` without step 1.** The parent signs, so the `cnf.jwk` check of Agent Token Verification does not apply to the sub-agent's token. This holds at both token endpoints.
2. **Handle sub-agents end to end.** Cap `exp` at the `subagent_token`'s, and check a federated auth token's `cnf.jwk` against the sub-agent's key.
3. **Tighten interactions.** Accept only known `callback` values, don't redirect the person to loopback or private hosts, and in four-party resolve a resource's interaction before you federate.
4. **Polls and revocation.** A poll carries an agent token for the same agent. End a pending request with `revoked` when its `presented_token`, `subagent_token`, or agent-person binding is revoked.
5. **Return mission update bytes.** An accepted update returns `update` alongside `s256`.

## Metadata

- [ ] **PS-1 Check every `_endpoint` value.** Every metadata member whose name ends in `_endpoint` MUST use `https` and MUST NOT contain a query or fragment. -11 named only `auth_token_endpoint`, `person_token_endpoint`, and `mission_endpoint` among yours; -12 adds `revocation_endpoint`, `interaction_endpoint`, `permission_endpoint`, `audit_endpoint`, `mission_control_endpoint`, and any extension member. (Endpoint and Other URLs)
- [ ] **PS-2 Ignore unknown metadata members.** When you read a resource's, an AS's, or an AP's metadata, MUST ignore members you don't recognize. Don't reject the document for carrying one. (Metadata Documents)
- [ ] **PS-3 (optional) Bind your metadata to a Trust Chain.** You MAY bind `aauth-person.json` and your JWKS to an OpenID Federation Trust Chain per OpenID Federation Well-Known Binding 1.0. (Metadata Documents)

## Sub-agents

- [ ] **PS-4 Verify `subagent_token` without step 1.** (Person Token Endpoint, Parent-Mediated Authorization)
  - -11: verify it per Agent Token Verification. Step 1 compares its `cnf.jwk` with the signing key, which is the parent's, so a valid request fails.
  - -12: verify it per Agent Token Verification without step 1, at the person token endpoint and the auth token endpoint.
  - Still check that its `parent_agent` names the signing agent and its `iss` equals the signing agent's. Otherwise answer `invalid_subagent_token`.
  - At the auth token endpoint, the `agent_jkt` check against the `subagent_token`'s `cnf.jwk` ties its key to the request.
- [ ] **PS-5 Cap `exp` at the earliest agent token.** (Person Token Structure, Auth Token Structure)
  - -11: no later than "the agent token" used to obtain it.
  - -12: no later than the earliest `exp` of the agent tokens the request carried: the one in `Signature-Key` and, when present, the `subagent_token`.
  - Applies to person tokens and to the auth tokens you issue.
- [ ] **PS-6 Check a federated sub-agent auth token against the sub-agent.** At Auth Token Delivery step 4, compare the auth token's `cnf.jwk` with the `subagent_token`'s `cnf.jwk` in a parent-mediated authorization, not with the parent's signing key. A PS that compared with the parent's key rejected valid tokens as `as_unreachable`. (Auth Token Delivery)

## Interaction

- [ ] **PS-7 Accept only known `callback` values.** At an interaction URL you host, accept `callback` only when it is on the origin of the requesting agent's `callback_endpoint`, or a loopback URL when that agent's `localhost_callback_allowed` is `true`. MUST ignore any other `callback` and display your completion page. (User Interaction)
- [ ] **PS-8 Replace egress admission on `interaction.url`.** (Resource-Initiated Interaction)
  - -11: validate it is `https` and apply your egress admission policy to it.
  - -12: validate it is `https`, and MUST NOT redirect the person to a URL whose host is a loopback, private, or link-local address unless your deployment allows it.
  - You don't fetch this URL, so don't apply fetch limits to it.
- [ ] **PS-9 Resolve a resource's interaction before federating.** When a resource token whose `aud` is an AS carries `interaction`, run the resource's interaction first, then make the PS-to-AS token request. The AS issues the auth token. (Resource-Initiated Interaction)

## Pending requests

- [ ] **PS-10 Require the same credential on polls.** A poll of your pending URL is signed under the same agent identity, and presents the same type of credential, as the request that received the `202`. At the endpoints agents call, that is an agent token for the same agent. (Pending URL Security)
- [ ] **PS-11 End pending requests on more revocations.** (Polling Error Codes, Presenting a Revoked Token)
  - -11: answer polling `revoked` when the resource token, the upstream token, or the agent's agent token is revoked while the request waits.
  - -12: also when the token it carried as `presented_token` or `subagent_token` is revoked, or the agent's binding to the person is revoked.
  - Don't issue, and don't answer `revoked_presented_token`, on a poll. `detail` SHOULD say which.

## Signatures

- [ ] **PS-12 Prefer `revoked_jwt` over `expired_jwt`.** When a token in `Signature-Key` has expired and you still hold a revocation for it, answer `revoked_jwt`. -11 limited `revoked_jwt` to unexpired tokens. (Verification (Server), Presenting a Revoked Token)

## Missions

- [ ] **PS-13 Return the update's bytes.** If you support mission update: (Mission Update)
  - -11: on acceptance, return `{ "s256": … }` over the update's persisted bytes.
  - -12: return `{ "s256": …, "update": … }`, where `update` is those exact bytes, base64url-encoded without padding.
  - MUST serve the same bytes wherever you later expose the update, as for the mission blob.
- [ ] **PS-14 (optional) Distinguish identical approvals.** `approved_at` does not make `s256` unique: two approvals with the same members and the same `approved_at` hash the same. You MAY add a member to the blob to tell them apart. (Mission Approval)

## Error codes

Token endpoint (Token Endpoint Error Codes):

- **Relay:** an AS may now answer `invalid_agent_token` or `expired_agent_token` for the `agent_token` you sent. Relay them like any AS terminal error. They are never your own codes: an agent token in `Signature-Key` that fails is `401` with `Signature-Error`.

Polling (Polling Error Codes):

- **Widened:** `revoked` (403) covers the cases in PS-11.
