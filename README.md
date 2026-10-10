# AAuth

AAuth gives every agent its own cryptographic identity and signs every request it makes, so no credential is a bearer token and nothing needs pre-registration. A person server represents the person the agent acts for, and access servers apply resource policy across trust domains. Each party adopts independently.

## Specifications

| Draft | Scope | Editor's copy |
|---|---|---|
| [AAuth Protocol](https://datatracker.ietf.org/doc/draft-hardt-oauth-aauth-protocol/) | Agent, person, resource, and auth tokens; five access modes; missions; PS–AS federation | [html](https://dickhardt.github.io/AAuth/draft-hardt-oauth-aauth-protocol.html) |
| [HTTP Signature Keys](https://datatracker.ietf.org/doc/draft-hardt-httpbis-signature-key/) | The `Signature-Key` header and key discovery that AAuth signs with | [html](https://dickhardt.github.io/signature-key/draft-hardt-httpbis-signature-key.html) |
| [AAuth Bootstrap](https://datatracker.ietf.org/doc/draft-hardt-aauth-bootstrap/) | Informational: how an agent provider enrolls agents and issues agent tokens | [html](https://dickhardt.github.io/AAuth/draft-hardt-aauth-bootstrap.html) |
| [AAuth R3](https://datatracker.ietf.org/doc/draft-hardt-aauth-r3/) | Authorization in the vocabularies agents already use: MCP, OpenAPI, gRPC, GraphQL | [html](https://dickhardt.github.io/AAuth/draft-hardt-aauth-r3.html) |
| [AAuth Budgets](https://datatracker.ietf.org/doc/draft-hardt-aauth-budgets/) | Spending ceilings for metered resources | [html](https://dickhardt.github.io/AAuth/draft-hardt-aauth-budgets.html) |
| [AAuth Events](https://datatracker.ietf.org/doc/draft-hardt-aauth-events/) | Event delivery to agents through their agent provider | [html](https://dickhardt.github.io/AAuth/draft-hardt-aauth-events.html) |

Exploration, not yet submitted: [AAuth Supervision](https://dickhardt.github.io/AAuth/draft-hardt-aauth-supervision.html), the PS–SS interface where a supervision server decides on the person's behalf.

Implementing against an earlier revision? See [Updating from -10 to -11](upgrade-10-to-11/). For the minimum live pieces needed to show interoperability, see the [Interoperability Demo Profile](interop-demo-profile.md).

## Get Involved

- [aauth.dev](https://www.aauth.dev): explainers, diagrams, and the AAuth Explorer
- [Office hours](https://lu.ma/aauth): drop in to ask questions or show what you're building
- Slack: [IETF `#aauth`](https://www.aauth.dev/ietf-slack) for the specifications, [AAuth community](https://www.aauth.dev/slack) for implementations
- [Issues](https://github.com/dickhardt/AAuth/issues) and [CONTRIBUTING.md](CONTRIBUTING.md)

## Implementations

| Project | Kind |
|---|---|
| [packages-js](https://github.com/aauth-dev/packages-js) | TypeScript SDK for agents and MCP servers |
| [dotnet-samples](https://github.com/aauth-dev/dotnet-samples) | .NET SDK and samples |
| [aauth-python-library](https://github.com/christian-posta/aauth-python-library) | Python request signing and verification |
| [aauth-go-library](https://github.com/christian-posta/aauth-go-library) | Go request signing and verification |
| [regent-httpsig](https://github.com/regent-protocol/regent-httpsig) | Python resource-side verification and budgets metering |
| [keycloak-aauth-extension](https://github.com/christian-posta/keycloak-aauth-extension) | Keycloak SPI (26.2.5) |
| [aauth-person-server](https://github.com/christian-posta/aauth-person-server) | Person server with missions |
| [extauth-aauth-resource](https://github.com/christian-posta/extauth-aauth-resource) | Envoy / agentgateway ext-authz that makes an HTTP, MCP, or A2A service an AAuth resource |
| [whoami](https://github.com/aauth-dev/whoami) | Identity claims resource |
| [proxy](https://github.com/aauth-dev/proxy) | The user's AAuth agent as an MCP server |
| [AAuth Web Agent](https://web-agent.aauth.dev) | Protocol playground |
| [AAuth Explorer](https://explorer.aauth.dev) | Walkthrough of the protocol flows |
| [aauth-full-demo](https://github.com/christian-posta/aauth-full-demo) | A2A multi-agent flow with Keycloak and user consent |
| [aauth-supervision-server](https://github.com/xmuruaga/aauth-supervision-server) | Python supervision server for AAuth Supervision |

## Building

`make` builds each `draft-*.md` into HTML and text.

---

Author: Dick Hardt (dick.hardt@gmail.com). Founding sponsor: [Geffen Posner](https://www.linkedin.com/in/geffenpo/).
