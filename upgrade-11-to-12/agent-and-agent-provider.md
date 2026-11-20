# Updating an Agent and Agent Provider from -11 to -12

For an agent or agent provider (AP) implemented against draft-hardt-oauth-aauth-protocol-11. Sections are cited by their -12 names.

- -11: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-11
- -12: https://dickhardt.github.io/AAuth/draft-hardt-oauth-aauth-protocol.html (editor's copy, not submitted)

Each item has an ID for tracking. Items marked **(optional)** add capability; everything else is required to conform to -12.

## Key changes for an agent

1. **Present the token each endpoint asks for.** An auth token does not replace your agent token at an endpoint that answers `requirement=agent-token`.
2. **Change which body components you sign.** Cover `content-digest` and `content-type` on authorization endpoint requests with a body. Don't cover body components on bodyless requests.
3. **Poll with the same credential.** A poll presents the same type of credential as the request that received the `202`.
4. **Sub-agents.** Check a sub-agent's auth token against the sub-agent's key, and expect tokens to expire with the `subagent_token`.
5. **Handle `invalid_agent_token` and `expired_agent_token`.** They return, from the AS through your PS.

## Key changes for an agent provider

1. **Check your `_endpoint` values.** `event_endpoint` must be `https` with no query or fragment.
2. **Accept `self-jwt` at `event_endpoint`.** If you support AAuth Events, the `unsupported_scheme` rule no longer rejects it there.

## Agent: discovery and metadata

- [ ] **AG-1 Ignore unknown metadata members.** When you read a resource's or a PS's metadata, MUST ignore members you don't recognize. Don't reject the document for carrying one. (Metadata Documents)

## Agent: presenting tokens

- [ ] **AG-2 Present the token the endpoint's requirement names.** (Auth Token Usage, Person Token Usage)
  - -11: once you hold an auth token for a resource, present it on every later request to that resource.
  - -12: present it on the requests the resource authorizes on it. An auth token carries no agent identifier, so where an endpoint answers `requirement=agent-token`, present your agent token there.

## Agent: signing

- [ ] **AG-3 Cover the body at the authorization endpoint.** On a request with a body to a resource's `authorization_endpoint`, cover `content-digest` and `content-type`, as on PS and AS requests. -11 did not require them there. (Covered Components)
- [ ] **AG-4 Cover body components only when there is a body.** When a resource lists a body component in `additional_signature_components`, such as `content-digest` or `content-type`, cover it only on requests that carry a body. A bodyless `GET` poll does not cover it. -11 required every listed component on every request. (Resource Metadata)

## Agent: polling

- [ ] **AG-5 Poll with the same credential.** (Pending URL Security, Deferred Delivery)
  - Sign each poll under the same agent identity, and present the same type of credential, as the request that received the `202`.
  - At the PS, that is your agent token. At a resource, it is the type of token you presented on the request that received the `202`.
  - One exception stands: on a deferred `requirement=auth-token`, poll with the auth token once you hold it.
  - -11 said only that the server verifies your identity on every poll.

## Agent: sub-agents

- [ ] **AG-6 Check a sub-agent's auth token against the sub-agent.** (Auth Token Response Verification, Auth Token Delivery)
  - Parent: when your PS returns an auth token for a sub-agent, compare its `cnf.jwk` with the `subagent_token`'s `cnf.jwk`, not with your own key.
  - Sub-agent: verify that `aud` and `cnf` match your own values on the token the parent relays to you.
- [ ] **AG-7 Keep the `subagent_token` fresh.** Person tokens and auth tokens issued for a sub-agent expire no later than its `subagent_token`, as well as your own agent token. -11 said only "the agent token", which read as the parent's. Refresh the sub-agent's agent token within the refresh margin before you request for it. (Person Token Structure, Auth Token Structure, Expiry and the Refresh Margin)

## Agent: responses and errors

- [ ] **AG-8 Handle `invalid_agent_token` and `expired_agent_token`.** -11 removed both. In -12 the AS returns them for the `agent_token` your PS sent, and your PS relays them with the AS's `error` value. (Token Endpoint Error Codes, PS-to-AS Token Request)
  - `expired_agent_token`: get a fresh agent token from your AP, then a fresh person token and resource token, and retry.
  - `invalid_agent_token`: surface it.
- [ ] **AG-9 (optional) Verify a mission update.** The update response now carries `update`, the base64url bytes `s256` was computed over. You MAY decode it and check `s256`. (Mission Update)

## Agent provider

- [ ] **AP-1 Check every `_endpoint` value.** Every metadata member whose name ends in `_endpoint` MUST use `https` and MUST NOT contain a query or fragment. -11 named only `callback_endpoint` among yours; -12 adds `event_endpoint` and any extension member. The loopback `callback` exception for `localhost_callback_allowed` is unchanged. (Endpoint and Other URLs)
- [ ] **AP-2 Ignore unknown metadata members.** When you read a PS's metadata, MUST ignore members you don't recognize. (Metadata Documents)
- [ ] **AP-3 Accept `self-jwt` at your `event_endpoint`.** If you support AAuth Events: (Keying Material, Verification (Server))
  - -11: a server signing in its own right MUST use the `jwks_uri` scheme, and Verification step 4 rejects any scheme the profile does not use with `unsupported_scheme`.
  - -12: that rule covers the requests the protocol defines. A companion specification MAY define the scheme for its own requests, and AAuth Events uses `self-jwt` for event delivery.
  - Step 4's "scheme this profile does not use" applies at the protocol's endpoints, not at `event_endpoint`.
- [ ] **AP-4 (optional) Bind your metadata to a Trust Chain.** You MAY bind `aauth-agent.json` and your JWKS to an OpenID Federation Trust Chain per OpenID Federation Well-Known Binding 1.0. (Metadata Documents)
