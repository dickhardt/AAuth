# Updating a Resource from -11 to -12

For a resource implemented against draft-hardt-oauth-aauth-protocol-11. Sections are cited by their -12 names.

- -11: https://datatracker.ietf.org/doc/html/draft-hardt-oauth-aauth-protocol-11
- -12: https://dickhardt.github.io/AAuth/draft-hardt-oauth-aauth-protocol.html (editor's copy, not submitted)

Each item has an ID for tracking. Items marked **(optional)** add capability; everything else is required to conform to -12.

A resource that uses only agent identity access or resource-managed access needs only RS-1 to RS-3, RS-7, and RS-9 to RS-11. RS-4 to RS-6 and RS-8 apply to a resource that accepts person tokens or auth tokens.

## Key changes

1. **Key the person on `(ps, sub)`.** In four-party, an auth token's `iss` is the AS, which did not mint `sub`. Never key on `(iss, sub)` for an AS-issued token.
2. **Require body coverage at the authorization endpoint.** A request with a body there covers `content-digest` and `content-type`.
3. **Don't require body components on bodyless requests.** What you list in `additional_signature_components` applies to a body only when there is one.
4. **Tighten interactions you host.** Record the decision through an authenticated channel, and accept only known `callback` values.
5. **Answer `revoked_jwt` after `exp`.** A revoked token is reported revoked even once it has expired.

## Metadata

- [ ] **RS-1 Check every `_endpoint` value.** Every metadata member whose name ends in `_endpoint` MUST use `https` and MUST NOT contain a query or fragment. -11 named only `authorization_endpoint` among yours; -12 adds `revocation_endpoint` and any extension member, such as Budgets' `usage_endpoint`. (Endpoint and Other URLs)
- [ ] **RS-2 Ignore unknown metadata members.** When you read a PS's, an AS's, or an AP's metadata, MUST ignore members you don't recognize. Don't reject the document for carrying one. (Metadata Documents)
- [ ] **RS-3 (optional) Bind your metadata to a Trust Chain.** You MAY bind `aauth-resource.json` and your JWKS to an OpenID Federation Trust Chain per OpenID Federation Well-Known Binding 1.0. (Metadata Documents)

## Person identity

- [ ] **RS-4 Key the person on `(ps, sub)`.** (Auth Token Verification, Trust Posture in PS Authorization Access, Organization Identification, Directed Identifiers)
  - -11: verify that `(iss, sub)` matches or establishes your record for the person.
  - -12: use `(ps, sub)`. The PS named in `ps` minted `sub`. MUST NOT key on `(iss, sub)` for an auth token an AS issued.
  - You can rely on `ps` because the AS verified that the presented token's issuer is the PS that signed the token request.
  - Person tokens and PS-issued auth tokens are unaffected: there `iss` equals `ps`.
  - Re-key records you created from AS-issued auth tokens under `(iss, sub)`. Under -11 the same person had two keys: `(PS, sub)` from the person token and `(AS, sub)` from the auth token. Under -12 both are `(ps, sub)`.
  - `(ps, tenant)` identifies the organization, not `(iss, tenant)`. `tenant` is still not part of the person's identifier.

## Authorization endpoint

- [ ] **RS-5 Require body coverage.** On a request with a body to your `authorization_endpoint`, require `content-digest` and `content-type` in the covered components, as at your revocation endpoint. Answer a request without them with `invalid_input` and `required_input`. -11 required only the base components there. (Covered Components, Verification (Server))
- [ ] **RS-6 Accept a request without `scope` when a companion replaces it.** `scope` is REQUIRED unless a companion specification defines a replacement request parameter. If you support R3, accept a request that carries `r3_operations` and no `scope`. (Authorization Endpoint)

## Signatures and token verification

- [ ] **RS-7 Require body components only on requests with a body.** A component you list in `additional_signature_components` that describes a body, such as `content-digest` or `content-type`, applies only to requests that carry a body. Don't reject a bodyless poll for omitting it. -11 applied the list to every request. (Resource Metadata)
- [ ] **RS-8 Prefer `revoked_jwt` over `expired_jwt`.** When a person token or auth token in `Signature-Key` has expired and you still hold a revocation for it, answer `revoked_jwt`. -11 limited `revoked_jwt` to unexpired tokens. (Verification (Server), Presenting a Revoked Token)

## Pending requests

- [ ] **RS-9 Require the same credential on polls.** A poll of your pending URL is signed under the same agent identity, and presents the same type of credential, as the request that received the `202`: the agent token, person token, or auth token it carried. On a deferred `requirement=auth-token`, the poll presents the auth token instead, as before. (Pending URL Security, Deferred Delivery)

## Interactions you host

- [ ] **RS-10 Record the decision at your interaction URL.** If you host an interaction, record the person's approve or deny decision through an authenticated channel of your own. -11 put that channel at the PS, even for interactions the PS only relays. The code alone MUST NOT authorize the decision. (Interaction Code Format)
- [ ] **RS-11 Accept only known `callback` values.** At your interaction URL, accept `callback` only when it is one of: (User Interaction)
  - a URL on the origin of the requesting agent's `callback_endpoint`;
  - a loopback URL, when that agent's `localhost_callback_allowed` is `true`;
  - for an interaction reached through a PS (Resource-Initiated Interaction), a URL on that PS's origin.

  MUST ignore any other `callback` and display your completion page.

## If you call downstream resources (call chaining)

- [ ] **RS-12 Apply the agent changes to your downstream requests.** You act as an agent there, so AG-2 to AG-5 of [agent-and-agent-provider.md](agent-and-agent-provider.md) apply: present the token each endpoint asks for, cover the body at the downstream authorization endpoint, cover body components only when there is a body, and poll with the same credential. (Call Chaining)
