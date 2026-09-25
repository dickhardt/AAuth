# Updating from AAuth Protocol -10 to -11

These guides are for implementations written against draft-hardt-oauth-aauth-protocol-10. Each one lists what that role must change to conform to -11. Read the one for your role:

| Role | Guide |
|---|---|
| Person Server | [person-server.md](person-server.md) |
| Agent and Agent Provider | [agent-and-agent-provider.md](agent-and-agent-provider.md) |
| Resource, including a resource that calls downstream | [resource.md](resource.md) |
| Access Server | [access-server.md](access-server.md) |

Each item is a checklist entry. It has an ID (for example `PS-31`), states what to change, gives the -10 rule where it differs, and cites the -11 section. Items marked **(optional)** add capability; the rest are required. The guides are written so a coding agent can work through them item by item.

## What changed in -11

- **Person token.** The PS issues a person token (`aa-person+jwt`) that identifies the person to one resource. A resource verifies one before it issues a resource token.
- **`presented_token`.** The agent sends the token it presented to the resource along with the resource token. The PS and the AS verify the two against each other.
- **No agent identifier in resource-facing tokens.** `agent` and `act` are gone from resource tokens and auth tokens.
- **Missions.** `mission_s256` replaces `AAuth-Mission` and `{approver, s256}`. The approval response has a new shape. Update and completion happen at `{mission_endpoint}/{mission_s256}`.
- **Revocation.** The request is `{jti, exp}`, signed by the issuer. Recipients cascade, and there is no `404`.
- **Call chaining.** Every hop routes to the person's PS, and the intermediary is its own agent provider.
- **Renames.** `token_endpoint` is `auth_token_endpoint`. The `access_mode` value `aauth-access-token` is `session-token`.

The -11 Document History lists these changes with issue numbers.
