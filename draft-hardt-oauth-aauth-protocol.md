%%%
title = "AAuth Protocol"
abbrev = "AAuth-Protocol"
ipr = "trust200902"
area = "Security"
workgroup = "TBD"
keyword = ["agent", "authentication", "authorization", "http", "signatures"]

[seriesInfo]
status = "standard"
name = "Internet-Draft"
value = "draft-hardt-oauth-aauth-protocol-latest"
stream = "IETF"

date = 2026-06-17T00:00:00Z

[[author]]
initials = "D."
surname = "Hardt"
fullname = "Dick Hardt"
organization = "Hellō"
  [author.address]
  email = "dick.hardt@gmail.com"

%%%

<reference anchor="OpenID.Core" target="https://openid.net/specs/openid-connect-core-1_0.html">
  <front>
    <title>OpenID Connect Core 1.0</title>
    <author initials="N." surname="Sakimura" fullname="Nat Sakimura">
      <organization>NRI</organization>
    </author>
    <author initials="J." surname="Bradley" fullname="John Bradley">
      <organization>Ping Identity</organization>
    </author>
    <author initials="M." surname="Jones" fullname="Michael B. Jones">
      <organization>Microsoft</organization>
    </author>
    <author initials="B." surname="de Medeiros" fullname="Breno de Medeiros">
      <organization>Google</organization>
    </author>
    <author initials="C." surname="Mortimore" fullname="Chuck Mortimore">
      <organization>Salesforce</organization>
    </author>
    <date year="2014" month="November"/>
  </front>
</reference>

<reference anchor="OpenID.Enterprise" target="https://openid.net/specs/openid-connect-enterprise-extensions-1_0.html">
  <front>
    <title>OpenID Connect Enterprise Extensions 1.0</title>
    <author initials="D." surname="Hardt" fullname="Dick Hardt">
      <organization>Hellō</organization>
    </author>
    <author initials="K." surname="McGuinness" fullname="Karl McGuinness">
      <organization>Okta</organization>
    </author>
    <date year="2025"/>
  </front>
</reference>

<reference anchor="I-D.hardt-httpbis-signature-key" target="https://datatracker.ietf.org/doc/draft-hardt-httpbis-signature-key">
  <front>
    <title>HTTP Signature Keys</title>
    <author initials="D." surname="Hardt" fullname="Dick Hardt">
      <organization>Hellō</organization>
    </author>
    <author initials="T." surname="Meunier" fullname="Thibault Meunier">
      <organization>Cloudflare</organization>
    </author>
    <date year="2026"/>
  </front>
</reference>

<reference anchor="I-D.hardt-aauth-bootstrap" target="https://datatracker.ietf.org/doc/draft-hardt-aauth-bootstrap">
  <front>
    <title>AAuth Bootstrap Guidance</title>
    <author initials="D." surname="Hardt" fullname="Dick Hardt">
      <organization>Hellō</organization>
    </author>
    <date year="2026"/>
  </front>
</reference>

<reference anchor="I-D.hardt-aauth-r3" target="https://github.com/dickhardt/AAuth">
  <front>
    <title>AAuth Rich Resource Requests (R3)</title>
    <author initials="D." surname="Hardt" fullname="Dick Hardt">
      <organization>Hellō</organization>
    </author>
    <date year="2026"/>
  </front>
</reference>

<reference anchor="IANA.JOSE.Algorithms" target="https://www.iana.org/assignments/jose/jose.xhtml#web-signature-encryption-algorithms">
  <front>
    <title>JSON Web Signature and Encryption Algorithms</title>
    <author>
      <organization>IANA</organization>
    </author>
  </front>
</reference>

<reference anchor="CommonMark" target="https://spec.commonmark.org/0.31.2/">
  <front>
    <title>CommonMark Spec</title>
    <author initials="J." surname="MacFarlane" fullname="John MacFarlane"/>
    <date year="2024"/>
  </front>
</reference>

<reference anchor="x402" target="https://docs.x402.org">
  <front>
    <title>x402: HTTP 402 Payment Protocol</title>
    <author>
      <organization>x402 Foundation</organization>
    </author>
    <date year="2025"/>
  </front>
</reference>

<reference anchor="I-D.hardt-aauth-events" target="https://github.com/dickhardt/AAuth">
  <front>
    <title>AAuth Events</title>
    <author initials="D." surname="Hardt" fullname="Dick Hardt">
      <organization>Hellō</organization>
    </author>
    <date year="2026"/>
  </front>
</reference>


.# Abstract

This document defines the AAuth authorization protocol for agent-to-resource authorization and identity claim retrieval. The protocol supports five resource access modes — agent identity, resource-managed (two-party), person identity, PS authorization (three-party), and federated authorization (four-party) — with agent governance as an orthogonal layer. It builds on the HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]) for HTTP Message Signatures and key discovery.

.# Discussion Venues

*Note: This section is to be removed before publishing as an RFC.*


This document is part of the AAuth specification family.
Related documents and open issues can be found at https://github.com/dickhardt/AAuth.
Raw markdown source is at https://raw.githubusercontent.com/dickhardt/AAuth/refs/heads/main/draft-hardt-oauth-aauth-protocol.md

{mainmatter}

# Introduction

## HTTP Clients Need Their Own Identity

In OAuth 2.0 [@!RFC6749] and OpenID Connect [@OpenID.Core], the client has no independent identity. Client identifiers are issued by each authorization server or OpenID provider — a `client_id` at Google is meaningless at GitHub. The client's identity exists only in the context of each server it has pre-registered with. This made sense when the web had a manageable number of integrations and a human developer could visit each portal to register.

API keys are the same model pushed further: a shared secret issued by a service, copied to the client, and used as a bearer credential. The problem is that any secret that must be copied to where the workload runs will eventually be copied somewhere it shouldn't be.

SPIFFE and WIMSE brought workload identity to enterprise infrastructure — a workload can prove who it is without shared secrets. But these operate within a single enterprise's trust domain. They don't help an agent that needs to access resources across organizational boundaries, or a developer's tool that runs outside any enterprise platform.

AAuth starts from this premise: every agent has its own cryptographic identity. An agent identifier (`aauth:local@domain`) is bound to a signing key, published at a well-known URL, and verifiable by any party — no pre-registration, no shared secrets, no dependency on a particular server. At its simplest, an agent signs a request and a resource decides what to do based on who the agent is. This identity-based access replaces API keys and is the foundation that authorization, governance, and federation build on incrementally.

## Agents Are Different

Traditional software knows at build time what services it will call and what permissions it needs. Registration, key provisioning, and scope configuration happen before the first request. This works when the set of integrations is fixed and known in advance.

Agents don't work this way. They discover resources at runtime. They execute long-running tasks that span multiple services across trust domains. They need to explain what they're doing and why. They need authorization decisions mid-task, long after the user set them in motion. A protocol designed for pre-registered clients with fixed integrations cannot serve agents that discover their needs as they go.

## What AAuth Provides

- **Agent identity without pre-registration**: A domain, static metadata, and a JWKS establish identity with no portal, no bilateral agreement, no shared secret.
- **Per-instance identity**: Each agent instance gets its own identifier (`aauth:local@domain`) and signing key.
- **Proof-of-possession on every request**: HTTP Message Signatures ([@!RFC9421]) bind every request the agent makes to the agent's key — a stolen token is useless without the private key.
- **Two-party mode with first-call registration**: An agent calls a resource it has never contacted before; the resource returns `AAuth-Requirement`; a browser interaction handles account creation, payment, and consent. The first API call is the registration.
- **Tool-call governance**: A person server (PS) represents the user and manages what tools the agent can call, providing permission and audit for tool use — no resource involved.
- **Missions**: Optional scoped authorization contexts that span multiple resources. The agent proposes what it intends to do in natural language; the person server provides full context — mission, history, justification — to the appropriate decision-maker (human or AI); every resource access is evaluated in context. Missions enable governance over decisions that cannot be reduced to predefined machine-evaluable rules.
- **Cross-domain federation**: The PS federates with access servers (AS) — the policy engines that guard resources — to enable access across trust domains without the agent needing to know about each one.
- **Clarification chat**: Users can ask questions during consent; agents can explain or adjust their requests.
- **Progressive adoption**: Each party can adopt independently; modes build on each other.
- **Asynchronous event delivery**: Agents receive events from resources through the AP, without requiring a public endpoint. Resources post event tokens to the AP's event endpoint; the AP routes them to the agent. Defined in AAuth Events ([@?I-D.hardt-aauth-events]).

## What AAuth Does Not Do

- Does not require centralized identity providers — agents publish their own identity
- Does not use shared secrets or bearer tokens — every credential is bound to a signing key and useless without it
- Does not require coordination to adopt — each party adds support independently

## Relationship to Existing Standards

AAuth builds on existing standards and design patterns:

- **OpenID Connect vocabulary**: AAuth reuses OpenID Connect scope values, identity claims, and enterprise extensions ([@OpenID.Enterprise]), lowering the adoption barrier for identity-aware resources.
- **Well-known metadata and key discovery**: Servers publish metadata at well-known URLs ([@!RFC8615]) and signing keys via JWKS endpoints, following the pattern established by OAuth Authorization Server Metadata ([@RFC8414]) and OpenID Connect Discovery ([@OpenID.Core]).
- **HTTP Message Signatures**: All requests are signed with HTTP Message Signatures ([@!RFC9421]) using keys bound to tokens conveyed via the Signature-Key header ([@!I-D.hardt-httpbis-signature-key]), providing proof-of-possession, identity, and message integrity on every call.

The HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]) defines how signing keys are bound to JWTs and discovered via well-known metadata, and how agents present cryptographic identity using HTTP Message Signatures ([@!RFC9421]). This specification defines the `AAuth-Requirement`, `AAuth-Access`, and `AAuth-Capabilities` headers, and the authorization protocol across five resource access modes.

Because agent identity is independent and self-contained, AAuth is designed for incremental adoption: each party can add support independently, and rollout does not need to be coordinated. A resource that verifies an agent's signature can manage access by identity alone, with no other infrastructure; adding a person server and an access server is additive. The five resource access modes and the orthogonal agent-governance layer are introduced in (#protocol-overview) and detailed in (#incremental-adoption).

# Conventions and Definitions

{::boilerplate bcp14-tagged}

In HTTP examples throughout this document, line breaks and indentation are added for readability. Actual HTTP messages do not contain these extra line breaks.

# Terminology

Parties:

- **Person**: A user or organization — the legal person — on whose behalf an agent acts and who is accountable for the agent's actions.
- **Agent**: An HTTP client ([@!RFC9110], Section 3.5) acting on behalf of a person. Identified by an agent identifier URI using the `aauth` scheme, of the form `aauth:local@domain` (#agent-identifiers). An agent MAY have a person server, declared via the `ps` claim in the agent token.
- **Agent Provider (AP)**: A server that manages agent identity and issues agent tokens to agents. Trusted by the person to issue agent tokens only to authorized agents. Identified by an HTTPS URL (#server-identifiers) and publishes metadata at `/.well-known/aauth-agent.json`.
- **Resource**: A server that requires authentication and/or authorization to protect access to its APIs and data. A resource MAY enforce access policy itself or delegate policy evaluation to an access server. Identified by an HTTPS URL (#server-identifiers) and publishes metadata at `/.well-known/aauth-resource.json`.
- **Person Server (PS)**: A server that represents the person to the rest of the protocol. The person chooses their PS; it is not imposed by any other party. The PS manages missions, handles consent, asserts user identity, and brokers authorization on behalf of agents. Identified by an HTTPS URL (#server-identifiers) and publishes metadata at `/.well-known/aauth-person.json`.
- **Access Server (AS)**: A policy engine that evaluates token requests, applies resource policy, and issues auth tokens on behalf of a resource. Identified by an HTTPS URL (#server-identifiers) and publishes metadata at `/.well-known/aauth-access.json`.

Tokens:

- **Agent Token**: Issued by an agent provider to establish the agent's identity. MAY declare the agent's person server (#agent-tokens).
- **Person Token**: Issued by a PS to identify the person an agent acts for, to one resource, before any authorization exists. Carries identity and no authorization (#person-tokens).
- **Resource Token**: Issued by a resource to describe the access the agent needs (#resource-tokens).
- **Auth Token**: Issued by a PS or AS to grant an agent access to a resource, containing identity claims and/or authorized scopes (#auth-tokens).
- **Session Token**: Issued by a resource to an agent when the resource manages authorization itself. Opaque to the agent, carried in the `AAuth-Access` header and presented back via `Authorization: AAuth` (#aauth-access).

Protocol concepts:

- **Mission**: A scoped authorization context for agent governance (#missions). Required when the person's PS requires governance over the agent's actions. A mission is a JSON object containing structured fields (approver, agent, approved_at, approved tools) and a Markdown description. Identified by the PS and SHA-256 hash of the mission JSON (`s256`). Missions are proposed by agents and approved by the PS and person.
- **Mission Log**: The ordered record of all agent↔PS interactions within a mission — token requests, permission requests, audit records, interaction requests, and clarification chats. The PS maintains the log and uses it to evaluate whether each new request is consistent with the mission's intent (#mission-log).
- **HTTP Sig**: An HTTP Message Signature ([@!RFC9421]) created per the AAuth HTTP Message Signatures profile defined in this specification (#http-message-signatures-profile), using a key conveyed via the `Signature-Key` header ([@!I-D.hardt-httpbis-signature-key]).
- **Markdown**: AAuth uses Markdown ([@CommonMark]) as the human-readable content format for mission descriptions, justifications, clarifications, and scope descriptions. Implementations MUST sanitize Markdown before rendering to users.
- **Interaction**: User authentication, consent, or other action at an interaction endpoint (#user-interaction). Triggered when a server returns `202 Accepted` with `requirement=interaction`.
- **Justification**: A Markdown string provided by the agent declaring why access is needed, presented to the user by the PS during consent (#ps-token-endpoint).
- **Clarification**: A Markdown string containing a question posed to the agent by the user during consent via the PS (#clarification-chat). The agent may respond with an explanation or an updated request.

# Protocol Overview

All AAuth tokens are JWTs verified using a JWK retrieved from the `jwks_uri` in the issuer's well-known metadata, binding each token to the server that issued it.

AAuth has two dimensions: **resource access modes** and **agent governance**. Resource access modes define how an agent gets authorized at a resource. Agent governance — missions, plus per-action permission, audit, and interaction relay through a person server — is an orthogonal layer that any agent with a person server can add, independent of which access mode the resource supports.

## Resource Access Modes

AAuth supports five resource access modes. They differ in what the resource ends up knowing and which party established it — not in how much of the protocol they use. The protocol works in every mode, and adoption does not require coordination between parties. A resource MAY apply different modes to different endpoints, and one advertising an R3 vocabulary states the mode for an individual operation there ([@?I-D.hardt-aauth-r3]).

| Mode | Resource knows | Established by | Parties |
|------|----------------|----------------|---------|
| Agent identity | which agent | the agent provider | Agent <br/> Resource |
| Resource-managed <br/>(two-party) | which person | the resource's own flow | Agent <br/> Resource |
| Person identity | which person | the person server | Agent <br/> Resource <br/> PS |
| PS authorization <br/>(three-party) | person and consented scope | the person server | Agent <br/> Resource <br/> PS |
| Federated authorization <br/>(four-party) | person and policy verdict | the access server | Agent <br/> Resource <br/> PS <br/> AS |

Resource-managed and person-identity access reach the same destination by different routes: in the first the resource runs its own login, in the second it accepts one the person server ran. The rest of the ladder adds what the resource is told beyond who the person is.

The following diagram shows all parties and their relationships. Not all parties or relationships are present in every mode.

~~~ ascii-art
                     +--------------+
                     |    Person    |
                     +--------------+
                      ^           ^
              mission |           | consent
                      v           v
                     +--------------+    federation    +--------------+
                     |              |----------------->|              |
                     |   Person     |                  |   Access     |
                     |   Server     |<-----------------|   Server     |
                     |              |    auth token    |              |
                     +--------------+                  +--------------+
                      ^          ^ |
            mission   | resource | | auth
                      |    token | | token
                      |          | v
              agent  +--------------+  signed request  +--------------+
+-----------+ token  |              |----------------->|              |
|  Agent    |------->|    Agent     |                  |   Resource   |
|  Provider |        |              |<-----------------|              |
+-----------+        +--------------+     resource     +--------------+

~~~
Figure: Protocol Parties and Relationships {#fig-parties}

- **Agent Provider → Agent**: Issues an agent token binding the agent's signing key to its identity.
- **Agent ↔ Resource**: Agent sends signed requests; resource returns responses. In the authorization modes, the resource also returns resource tokens at its authorization endpoint.
- **Agent ↔ PS**: Agent sends resource tokens to obtain auth tokens. With governance, agent also creates missions and requests permissions.
- **PS ↔ AS**: Federation (four-party only). The PS sends the resource token to the AS; the AS returns an auth token.
- **Person ↔ PS**: Mission approval and consent for resource access.

Detailed end-to-end flows are in (#detailed-flows). The following subsections describe each mode.

### Agent Identity Access {#overview-identity-access}

The agent signs requests with its agent token (#agent-tokens). The resource verifies the agent's identity via HTTP signatures and applies its own access control policy — granting or denying based on who the agent is. This replaces API keys with cryptographic identity. No authorization flow, no tokens beyond the agent token.

~~~ ascii-art
Agent                                        Resource
  |                                             |
  | HTTPSig w/ agent_token                      |
  |-------------------------------------------->|
  |                                             |
  | 200 OK                                      |
  |<--------------------------------------------|
~~~
Figure: Identity-Based Access {#fig-identity-access}

### Resource-Managed Access (Two-Party) {#overview-resource-managed}

The resource handles authorization itself — via interaction (#user-interaction), existing OAuth/OIDC infrastructure, or internal policy. After authorization, the resource MAY return an `AAuth-Access` header (#aauth-access) with a session token for subsequent calls.

~~~ ascii-art
Agent                                        Resource
  |                                             |
  | HTTPSig w/ agent_token                      |
  |-------------------------------------------->|
  |                                             |
  | 202 (interaction required)                  |
  |<--------------------------------------------|
  |                                             |
  | [user completes interaction]                |
  |                                             |
  | GET pending URL                             |
  |-------------------------------------------->|
  |                                             |
  | 200 OK                                      |
  | AAuth-Access: session-token                 |
  |<--------------------------------------------|
  |                                             |
  | HTTPSig w/ agent_token                      |
  | Authorization: AAuth session-token          |
  |-------------------------------------------->|
  |                                             |
  | 200 OK                                      |
  |<--------------------------------------------|
~~~
Figure: Resource-Managed Access (Two-Party) {#fig-resource-managed}

### Person Identity Access {#overview-person-identity}

The agent obtains a person token from its PS for this resource (#person-token-endpoint) and signs requests with it in place of its agent token. The resource verifies the token, learns which person the agent acts for — and, when the token carries one, which mission — and applies its own access control on that identity; the PS is not in the path of any call. This is federated login for agents: the resource decides what identity alone entitles the person to, exactly as it would after a login it ran itself.

~~~ ascii-art
Agent                                        Resource
  |                                             |
  | HTTPSig w/ person_token                     |
  |-------------------------------------------->|
  |                                             |
  | 200 OK                                      |
  |<--------------------------------------------|
~~~
Figure: Person Identity Access {#fig-person-identity}

A resource that needs more than identity for a particular operation challenges for it there with `requirement=auth-token` (#requirement-auth-token), while continuing to serve the rest on the person token.

### PS Authorization Access (Three-Party)

The resource has no separate access server: it accepts identity claims from whichever PS issued the person token it verified, namespacing them by that PS — the same `sub` from a different PS is a different subject — with no bilateral setup. (The agent token's `ps` claim is what tells the resource the agent has a person server at all.) The resource issues a resource token with `aud` = PS URL (#resource-tokens); the agent presents it at the PS's auth token endpoint (#ps-token-endpoint) and receives an auth token asserting identity claims and confirming user consent for the requested scope (#auth-tokens). The resource applies its own policy on the resulting claims; as in many OIDC deployments, registration and login share a single flow (#trust-posture-in-ps-asserted-access).

~~~ ascii-art
Agent                                 Resource       PS
  |                                      |            |
  | HTTPSig w/ agent_token               |            |
  | POST authorization_endpoint          |            |
  |------------------------------------->|            |
  |                                      |            |
  | resource_token (aud = PS URL)        |            |
  |<-------------------------------------|            |
  |                                      |            |
  | HTTPSig w/ agent_token               |            |
  | POST auth_token_endpoint             |            |
  | w/ resource_token                    |            |
  |-------------------------------------------------->|
  |                                      |            |
  | auth_token                           |            |
  |<--------------------------------------------------|
  |                                      |            |
  | HTTPSig w/ auth_token                |            |
  | GET /api/documents                   |            |
  |------------------------------------->|            |
  |                                      |            |
  | 200 OK                               |            |
  |<-------------------------------------|            |
~~~
Figure: PS Authorization Access (Three-Party) {#fig-ps-asserted}

### Federated Authorization Access (Four-Party)

The resource has its own access server and issues its resource token with `aud` = AS URL. The agent still presents the resource token to its own PS, and the PS federates with the AS (#ps-as-federation) to obtain the auth token.

~~~ ascii-art
Agent                                Resource   PS                    AS
  |                                     |       |                      |
  | HTTPSig w/ agent_token              |       |                      |
  | POST authorization_endpoint         |       |                      |
  |------------------------------------>|       |                      |
  |                                     |       |                      |
  | resource_token (aud = AS URL)       |       |                      |
  |<------------------------------------|       |                      |
  |                                     |       |                      |
  | HTTPSig w/ agent_token              |       |                      |
  | POST auth_token_endpoint            |       |                      |
  | w/ resource_token                   |       |                      |
  |-------------------------------------------->|                      |
  |                                     |       |                      |
  |                                     |       | HTTPSig w/ jwks_uri  |
  |                                     |       | POST                 |
  |                                     |       | auth_token_endpoint  |
  |                                     |       | w/ resource_token    |
  |                                     |       |--------------------->|
  |                                     |       |                      |
  |                                     |       | auth_token           |
  |                                     |       |<---------------------|
  |                                     |       |                      |
  | auth_token                          |       |                      |
  |<--------------------------------------------|                      |
  |                                     |       |                      |
  | HTTPSig w/ auth_token               |       |                      |
  | GET /api/documents                  |       |                      |
  |------------------------------------>|       |                      |
  |                                     |       |                      |
  | 200 OK                              |       |                      |
  |<------------------------------------|       |                      |
~~~
Figure: Federated Access (Four-Party) {#fig-federated}

## Roles {#roles}

Agent, AP, Resource, PS, and AS are **roles**, not deployment units. Each role has its own protocol identity — the Agent by an `aauth:local@domain` URI attested by an agent token, and AP, Resource, PS, and AS each by a distinct HTTPS URL with metadata published at a distinct well-known path. A single deployment unit MAY fill multiple roles, by hosting metadata for multiple server roles under a shared origin and/or by holding an agent token in addition to acting as a server. The protocol treats each role independently regardless of collocation — every interaction is a normal protocol exchange between role identifiers, even when the underlying servers are the same.

Common collocations:

- **PS + AS**: One server brokers user consent and evaluates resource policy. Federation collapses to a single internal evaluation. See (#ps-as-collapse).
- **Resource + Agent**: A resource acts as an agent for downstream calls, publishing agent metadata at `/.well-known/aauth-agent.json` so downstream parties can verify its identity. See (#call-chaining).
- **AP + Resource**: An agent provider exposes its own services to the agents it issues tokens to — publishing metadata at `/.well-known/aauth-resource.json` and issuing resource tokens. This enables the agent to obtain auth tokens from its PS for the agent provider's own services or infrastructure, using the standard resource token flow. How the agent obtains the resource token from the agent provider is out of scope of this specification. No mission is required.
- **Agent + AP**: A self-hosted agent is its own agent provider, self-issuing agent tokens signed by a JWKS-published key the user controls. See [@?I-D.hardt-aauth-bootstrap].
- **Org-wide bundle**: A single organizational server may operate AP + PS + AS for employees and internal resources, with federation incurred only at the boundary when an internal agent accesses an external resource.

An AP that supports AAuth Events ([@?I-D.hardt-aauth-events]) additionally acts as an event router — it receives event tokens from resources on behalf of agents and routes them to the appropriate agent instance. This is an extension of the AP role, not a new party.

These are deployment choices that do not change the wire protocol. A receiver verifies each role's tokens and metadata identically whether the role is on its own server or collocated with others.

## Policy Evaluation Points {#policy-evaluation-points}

Policy decisions in AAuth evaluate what the agent is doing. The Agent is the subject of every decision; the four server roles (AP, PS, AS, Resource) each evaluate the agent's activity from their own vantage point, in their own scope. No single party is the policy decision point — and token lifetimes give every server role a natural re-evaluation cadence.

- **Agent Provider** decides whether to continue treating the agent as authorized — based on device posture, attestation freshness, network location, account status, or any other AP-internal criteria — and enforces that decision by issuing or refusing fresh agent tokens.
- **Person Server** decides whether to issue an auth token for a given resource and scope — based on user consent and, when the agent is operating under a mission, the mission's intent and prior log entries against the PS's governance policy.
- **Access Server** decides whether to issue an auth token on behalf of the resource — based on resource policy, the claims the PS has provided, and any further requirements (interaction, payment, claims) gathered via deferred responses.
- **Resource** plays two roles in policy: it *decides what is required* to access the resource at the moment it issues a resource token (audience, scope, mission requirement), and it *enforces* the resulting auth token at the moment of access (signature verification, proof-of-possession, access rules).

All AAuth tokens have limited lifetimes, so each issuance is a natural re-evaluation point. An auth token that lives for an hour means every party that contributed to its issuance gets a fresh decision opportunity every hour — combined with real-time revocation (#token-revocation), this produces layered control without any single party needing to coordinate with the others.

## Agent Governance {#agent-governance}

Agent governance is orthogonal to resource access modes: any agent whose agent token carries a `ps` claim can use its person server for governance, whatever modes the resources it accesses support.

### Missions {#missions-overview}

When the person's PS requires governance over the agent's actions, the agent proposes a **mission** — a Markdown description of what it intends to accomplish — which the PS and person review, clarify, and approve (#missions). The approved mission is immutable, bound by its `s256` hash, and evolves through the **mission log** (#mission-log), the ordered record of agent–PS interactions within it. Missions are not required for every PS interaction — an agent can obtain auth tokens without one.

~~~ ascii-art
Agent                                     PS                        User
  |                                        |                          |
  | HTTPSig w/ agent_token                 |                          |
  | POST mission_endpoint                  |                          |
  | proposal                               |                          |
  |--------------------------------------->|                          |
  |                                        |                          |
  | [clarification chat]                   | review, clarify, approve |
  |<-------------------------------------->|<------------------------>|
  |                                        |                          |
  | 200 OK                                 |                          |
  | {s256, mission, person_tokens}         |                          |
  |<---------------------------------------|                          |
~~~
Figure: Mission Creation and Approval {#fig-mission}

The agent names the mission when it obtains a person token, and the resource copies `mission_s256` from that token into the resource token it issues, so mission context follows the authorization chain:

~~~ ascii-art
Agent                                        Resource
  |                                             |
  | HTTPSig w/ person_token (mission_s256)      |
  | POST authorization_endpoint                 |
  |-------------------------------------------->|
  |                                             |
  | resource_token                              |
  | (mission_s256 included)                     |
  |<--------------------------------------------|
~~~
Figure: Mission Context at Resource {#fig-mission-context}

When the agent believes the mission is complete, it proposes completion at the mission's own URL with a summary (#mission-completion). The person either accepts — the mission terminates — or responds with follow-up questions and the mission continues.

~~~ ascii-art
Agent                                     PS                        User
  |                                        |                          |
  | HTTPSig w/ agent_token                 |                          |
  | POST mission_endpoint/{s256}           |                          |
  | action=completion, summary             |                          |
  |--------------------------------------->|                          |
  |                                        |                          |
  |                                        | present summary          |
  |                                        |------------------------->|
  |                                        |                          |
  |                                        | accept / follow-up       |
  |                                        |<-------------------------|
  |                                        |                          |
  | 200 OK (terminated)                    |                          |
  | or clarification (continues)           |                          |
  |<---------------------------------------|                          |
~~~
Figure: Mission Completion {#fig-mission-completion}

### PS Governance Endpoints

The PS also provides three governance endpoints. The **permission endpoint** (#permission-endpoint) asks permission for actions no remote resource governs — tool calls, file writes, sending messages. The **audit endpoint** (#audit-endpoint) logs actions performed, completing the mission log; it requires a mission. The **interaction endpoint** (#interaction-endpoint) reaches the person through the PS — relaying interactions, questions, and payment approvals. A PS MAY additionally maintain a direct channel to the person (email, push notification, or messaging) for out-of-band approvals, notifications, and revocation alerts.

## Obtaining an Agent Token

The agent obtains an agent token from its agent provider. The agent generates a signing key pair, proves its identity to the agent provider through a platform-specific mechanism, and receives an agent token binding the signing key to the agent's identifier. The agent token MAY include a `ps` claim identifying the agent's person server. Agent token structure and normative requirements are defined in (#agent-tokens). Acquisition is platform-dependent; see [@?I-D.hardt-aauth-bootstrap] for common patterns.

# Agent Identity {#agent-identity}

This section defines agent identity — how agents are identified and how that identity is bound to signing keys via agent tokens. Agent identity is the foundation of AAuth: the agent token binds the agent's identifier to its signing key, and every other token the agent obtains (resource tokens, auth tokens) is issued in response to a request signed by that key. When an agent presents an auth token to a resource, the auth token's `cnf` claim binds it to the same key — so the agent's identity, established by the agent token, ultimately authorizes every signed request whether the `Signature-Key` header carries the agent token or an auth token.

## Agent Identifiers

Agent identifiers are URIs using the `aauth` scheme, of the form `aauth:local@domain` where `domain` is the agent provider's domain. The `local` part MUST consist of lowercase ASCII letters (`a-z`), digits (`0-9`), hyphen (`-`), underscore (`_`), plus (`+`), and period (`.`). The `local` part MUST NOT be empty and MUST NOT exceed 255 characters. The `domain` part MUST be a valid domain name conforming to the server identifier requirements (#server-identifiers) (without scheme).

The plus character (`+`) is RESERVED as the sub-agent delimiter (#sub-agents). A top-level agent's `local` part MUST NOT contain `+`. A sub-agent's `local` part MUST be its parent's `local` part, followed by `+`, followed by a non-empty discriminator (for example, `planner.7f3c+search1`). This naming is for operational readability only — a sub-agent's identifier shows its parent at a glance in logs. Parties MUST NOT parse the `local` part for protocol decisions; the `parent_agent` claim (#sub-agents) is the authoritative sub-agent marker and names the parent.

Valid agent identifiers:

- `aauth:assistant-v2@agent.example`
- `aauth:planner.7f3c@vendor.example` (top-level)
- `aauth:planner.7f3c+search1@vendor.example` (sub-agent of `planner.7f3c`)

Invalid agent identifiers:

- `My Agent@agent.example` (uppercase letters and space in local part)
- `@agent.example` (empty local part)
- `agent@http://agent.example` (domain includes scheme)

Implementations MUST perform exact string comparison on agent identifiers (case-sensitive).

## Agent Token {#agent-tokens}

### Agent Token Acquisition {#agent-token-acquisition-overview}

An agent MUST obtain an agent token from its agent provider before participating in the AAuth protocol. The acquisition process follows these steps:

1. The agent generates a signing key pair (Ed25519 is RECOMMENDED).
2. The agent proves its identity to the agent provider through a platform-specific mechanism.
3. The agent provider verifies the agent's identity and issues an agent token binding the agent's public key to the agent's identifier.

The mechanism for proving identity is platform-dependent. See [@?I-D.hardt-aauth-bootstrap] for common patterns including self-hosted agents, browser-based applications, and mobile applications.

### Agent Token Structure

An agent token is a JWT with `typ: aa-agent+jwt` containing:

Header:
- `alg`: Signing algorithm. A fully-specified identifier is REQUIRED; `Ed25519` is RECOMMENDED. Implementations MUST NOT accept `none`, the polymorphic `EdDSA` identifier, or any symmetric algorithm (#signature-algorithms).
- `typ`: `aa-agent+jwt`
- `kid`: Key identifier

Required payload claims:
- `iss`: Agent provider URL
- `dwk`: `aauth-agent.json` — the well-known metadata document name for key discovery ([@!I-D.hardt-httpbis-signature-key])
- `sub`: Agent identifier (stable across key rotations)
- `jti`: Unique token identifier for replay detection, audit, and revocation
- `cnf`: Confirmation claim ([@!RFC7800]) with `jwk` containing the agent's public key. The JWK MUST carry a fully-specified `alg` member (#signature-algorithms).
- `iat`: Issued at timestamp
- `exp`: Expiration timestamp. Agent tokens SHOULD NOT have a lifetime exceeding 24 hours.

Optional payload claims:
- `ps`: The HTTPS URL of the agent's person server. Configured per agent instance. When present, it tells a resource that the agent has a person server and which one, before the resource has verified a person token — enough to decide whether to challenge for one. The PS of an issued authorization is the `iss` of the person token the resource verified (#person-token-structure), not this claim. This claim is distinct from `iss` (which identifies the agent provider that issued the token).
- `parent_agent`: Sub-agent marker (#sub-agents). When present, the agent is a sub-agent and the value is the identifier of its parent agent. A sub-agent MUST NOT request authorization directly; its parent obtains auth tokens on its behalf (#sub-agents).

Agent providers MAY include additional claims in the agent token. Companion specifications may define additional claims for use by PSes or ASes in policy evaluation — for example, software attestation, platform integrity, secure enclave status, workload identity assertions, or software publisher identity. PSes and ASes MUST ignore unrecognized claims.

### Agent Token Usage

Agents present agent tokens via the `Signature-Key` header ([@!I-D.hardt-httpbis-signature-key]) using `scheme=jwt`:

```http
Signature-Key: sig=jwt;
    jwt="eyJhbGciOiJFZERTQSIsInR5cCI6Im..."
```

### Agent Token Verification

Verify the agent token per [@!RFC7515] and [@!RFC7519]:

1. Decode the JWT header. Verify `typ` is `aa-agent+jwt`.
2. Verify `dwk` is `aauth-agent.json`. Discover the issuer's JWKS via `{iss}/.well-known/{dwk}` per the HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]). Locate the key matching the JWT header `kid` and verify the JWT signature.
3. Verify `exp` is in the future and `iat` is not in the future.
4. Verify `iss` is a valid HTTPS URL conforming to the Server Identifier requirements.
5. Verify `cnf.jwk` matches the key used to sign the HTTP request.
6. If `ps` is present, verify it is a valid HTTPS URL conforming to the Server Identifier requirements.
7. If `parent_agent` is present, verify it is a valid agent identifier — the parent agent. Its presence marks this as a sub-agent's token (#sub-agents); the PS additionally enforces the single-level rule (#sub-agents) when such a token signs a request.

# Person Token {#person-tokens}

A person token is a PS-issued JWT that identifies the person an agent acts for to a single resource. It is not a bearer credential — `cnf` binds it to the agent's signing key — its `aud` is one resource, and it lives at most one hour. It carries no authorization from the PS: no scope, no account, no permission. Whether identity alone is sufficient to serve a request is the resource's decision, and a resource that decides it is (#overview-person-identity) serves whatever it serves on identity — so holding a person token is, at such a resource, effectively access. What a person token MUST NOT do is stand in for an auth token where one is required (#person-token-not-authorization).

A person token asserts that its issuer recognizes this person and that this agent acts for them. It carries no statement about how the person server established the person's identity, and a resource MUST NOT treat it as evidence of identity proofing, of legal identity, or of any assurance level. What it guarantees is continuity: the same `(iss, sub)` is the same person at this resource over time (#continuity-not-proofing).

The agent presents it via the `Signature-Key` header in place of its agent token (#keying-material). A resource MUST have verified a person token before it issues a resource token (#resource-tokens), so the identity and mission a resource records are PS-asserted rather than agent-asserted.

## Person Token Endpoint {#person-token-endpoint}

Every PS MUST publish a `person_token_endpoint` in its metadata (#ps-metadata) and MUST issue person tokens from it.

The agent MUST make a signed POST with an HTTP Sig (#http-message-signatures-profile), presenting its agent token via the `Signature-Key` header using `scheme=jwt`.

**Request parameters:**

- `resource` (REQUIRED): The HTTPS URL of the resource the person token is for, conforming to the Server Identifier requirements (#server-identifiers). Becomes the `aud` of the issued token. The PS MUST validate it against those requirements.
- `mission_s256` (OPTIONAL): The mission the agent is operating under (#missions). The PS MUST verify the mission exists, is active, and belongs to this agent, and MUST reject the request otherwise. When present, the PS includes it in the issued token.
- `subagent_token` (OPTIONAL): A sub-agent's agent token, present when a parent agent obtains a person token on behalf of one of its sub-agents (#sub-agents). The signing agent MUST be named by the `subagent_token`'s `parent_agent`. The issued token's `cnf` is the sub-agent's key.
- `upstream_token` (OPTIONAL): An auth token issued to the requester for an upstream resource, present when a resource acting as an agent needs a person token for a downstream resource (#call-chaining). The PS MUST verify it per (#upstream-token-verification).

Without `upstream_token` the PS issues for the person bound to the requesting agent (#agent-person-binding). With it, the PS issues for the person the upstream token was issued for, determined from the upstream token's `sub`, which this PS MUST have issued. A PS that cannot determine the person MUST reject the request.

A PS SHOULD rate-limit the number of distinct `resource` values it accepts from one agent; each obliges it to derive and retain a directed `sub` (#directed-identifiers).

```http
POST /person HTTP/1.1
Host: ps.example
Content-Type: application/json
Content-Digest: sha-256=:...:
Signature-Input: sig=("@method" "@authority" "@path"
    "content-type" "content-digest"
    "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "resource": "https://resource.example",
  "mission_s256": "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
}
```

**Response** (`200`):

```json
{
  "person_token": "eyJhbGc...",
  "expires_in": 3600
}
```

The PS MAY require user interaction before issuing and return a `202 Accepted` deferred response with `requirement=interaction` (#requirement-responses). Because a resource MAY serve requests on identity alone, the question put to the person is whether this agent may act at the resource as them, not merely whether it may name them. A PS SHOULD fetch the resource's metadata (#resource-metadata) before issuing for a resource the person has not used, and present its `name`, `description`, and `access_mode` so that the person is answering the question the resource will actually apply.

Errors use the token endpoint error codes (#token-endpoint-error-codes); `invalid_request` covers a missing or malformed `resource` or `mission_s256` value.

Issuing a person token creates a retention obligation. A PS MUST retain a record of each person token it issues — `jti`, `ps`, `sub`, `mission_s256`, `tenant`, and `exp` — sufficient to answer resource token verification (#resource-token-verification). Because a resource token may name a person token that was valid when the resource token was issued, the record MUST be retained beyond the person token's `exp` by at least the longest resource token lifetime the PS accepts (#resource-tokens). A resource token naming a `jti` the PS has no record of is rejected with `unknown_person_token` (#token-endpoint-error-codes).

An agent SHOULD cache a person token for a resource until it expires rather than requesting one per call. A person token is scoped to one resource and, when it carries `mission_s256`, to one mission, so an agent working across several resources or several concurrent missions holds one per combination. All of them bind the same key through `cnf`, so an agent that rotates its signing key invalidates all of them at once; the agent SHOULD re-request lazily, on next use of each resource, rather than re-minting the whole set.

## Person Token Structure {#person-token-structure}

A person token is a JWT with `typ: aa-person+jwt` containing:

Header:

- `alg`: Signing algorithm. A fully-specified identifier is REQUIRED; `Ed25519` is RECOMMENDED. Implementations MUST NOT accept `none`, the polymorphic `EdDSA` identifier, or any symmetric algorithm (#signature-algorithms).
- `typ`: `aa-person+jwt`
- `kid`: Key identifier

Required payload claims:

- `iss`: PS URL
- `dwk`: `aauth-person.json` — the well-known metadata document name for key discovery ([@!I-D.hardt-httpbis-signature-key])
- `aud`: The URL of the resource this token identifies the person to
- `sub`: Directed user identifier, with the same value the PS uses in the `sub` claim of auth tokens it issues for this `aud` (#auth-token-structure)
- `cnf`: Confirmation claim ([@!RFC7800]) with `jwk` containing the agent's public key. The JWK MUST carry a fully-specified `alg` member (#signature-algorithms).
- `jti`: Unique token identifier for audit and revocation
- `iat`: Issued at timestamp
- `exp`: Expiration timestamp. Person tokens MUST NOT have a lifetime exceeding 1 hour, and MUST NOT outlive the agent token presented when the token was requested or, when `mission_s256` is present, the mission's `expires_at` (#mission-approval).

Optional payload claims:

- `mission_s256`: The mission the agent is operating under (#missions), when the request named one. The base64url-encoded SHA-256 hash of the approved mission JSON, without padding.
- `tenant`: Tenant identifier per OpenID Connect Enterprise Extensions 1.0 [@OpenID.Enterprise], declaring the organization the person belongs to. It lets a resource apply organizational policy before it issues anything (#person-token-org-policy). It is not part of the identifier; see (#directed-identifiers).

```json
{
  "typ": "aa-person+jwt",
  "alg": "Ed25519",
  "kid": "ps-key-1"
}
```

```json
{
  "iss": "https://ps.example",
  "dwk": "aauth-person.json",
  "aud": "https://resource.example",
  "sub": "8f14e45fceea167a5a36dedd4bea2543",
  "cnf": { "jwk": { "kty": "OKP", "crv": "Ed25519",
                    "x": "NzbLsXh8uDCcd...", "alg": "Ed25519" } },
  "mission_s256": "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk",
  "jti": "pt-3ab910",
  "iat": 1730217600,
  "exp": 1730221200
}
```

A person token MUST NOT contain `scope` or `account`.

## Person Token Usage {#person-token-usage}

Agents present person tokens via the `Signature-Key` header ([@!I-D.hardt-httpbis-signature-key]) using `scheme=jwt`, in place of the agent token:

```http
Signature-Key: sig=jwt;
    jwt="eyJhbGciOiJFZDI1NTE5IiwidHlwIjoiYWEtcGVyc29uK2p3dCJ9..."
```

The person token's `cnf.jwk` is the same key that signed the request, so HTTP Message Signature verification proceeds identically to the agent-token case. Once an auth token has been issued for a resource, the agent presents the auth token on subsequent requests to that resource (#auth-token-usage).

## Person Token Verification {#person-token-verification}

Verify the person token per [@!RFC7515] and [@!RFC7519]:

1. Decode the JWT header. Verify `typ` is `aa-person+jwt`.
2. Verify `dwk` is `aauth-person.json`. Discover the issuer's JWKS via `{iss}/.well-known/{dwk}` per the HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]). Locate the key matching the JWT header `kid` and verify the JWT signature.
3. Verify `exp` is in the future and `iat` is not in the future.
4. Verify `iss` is a valid HTTPS URL conforming to the Server Identifier requirements (#server-identifiers).
5. Verify `aud` matches the resource's own identifier.
6. `cnf.jwk` is REQUIRED. Verify it matches the key used to sign the HTTP request, applying the same structural checks as auth token verification (#request-context-binding).

A recipient MUST reject an `aa-person+jwt` wherever an auth token is required. Only `typ` distinguishes the two (#person-token-not-authorization).

`sub` is unique within the issuer, not globally. A resource MUST treat `(iss, sub)` as the identifier, MUST treat the value as opaque, and MUST NOT match a `sub` received from one issuer against a record established under another, however the values compare.

# Resource Access and Resource Tokens {#resource-tokens}

This section defines how agents request access to resources and how resources issue resource tokens.

A resource token can be returned in two ways:

1. **Authorization endpoint**: The agent proactively requests access at the resource's `authorization_endpoint`. The resource responds with a resource token.
2. **AAuth-Requirement challenge**: The agent calls a resource endpoint directly. If the agent lacks sufficient authorization, the resource returns `401` with an `AAuth-Requirement` header containing a resource token (#requirement-auth-token).

A resource MAY return a `401` with `AAuth-Requirement` even when the agent presents a valid auth token — for example, when the endpoint requires additional scopes or a different authorization context beyond what the current auth token grants (nested authorization).

A resource MUST have verified a person token (#person-tokens) before it issues a resource token, and MUST challenge with `requirement=person-token` (#requirement-person-token) when it has not. Only a person server can act on a resource token — in three-party it is the audience, and in four-party it is the only party that may call the AS token endpoint — so a resource token issued to an agent that cannot name a person is one nobody can redeem.

A resource token is a signed JWT that cryptographically binds the resource's identity, the person's identity, the agent's signing key, and the requested scope. The resource sets the token's audience based on its configuration:

- If the resource has its own AS: `aud` = AS URL (four-party)
- If the resource has no AS but the agent has a PS (`ps` claim in agent token): `aud` = PS URL (three-party)
- If neither: the resource handles authorization itself — via an interaction response (#user-interaction) or internal policy — and MAY return an `AAuth-Access` header (#aauth-access)

A resource MAY always handle authorization itself, regardless of whether the agent has a PS.

## Authorization Endpoint Request

A resource MAY publish an `authorization_endpoint` in its metadata. The agent sends a signed POST to the authorization endpoint. The resource reads the person token from the `Signature-Key` header and determines how to respond — it may return a resource token, handle authorization itself, or both.

The agent MUST present a person token (#person-tokens) via the `Signature-Key` header on requests to the authorization endpoint, and the resource MUST verify it per (#person-token-verification). A resource that receives a request without one responds per (#requirement-person-token).

An agent with no person server cannot obtain a person token and so cannot use the authorization endpoint. It calls the resource's endpoints directly and takes whatever the resource challenges with — identity-based access (#requirement-agent-token) or resource-managed authorization (#resource-managed-auth). The `401` path (#requirement-auth-token) is reached with an agent token as before.

**Request parameters:**

- `scope` (REQUIRED): A space-separated string of scope values the agent is requesting.
- `account` (OPTIONAL): A string identifying which account at the resource the authorization is for, drawn from the resource's own account namespace (#account-binding).

```http
POST /authorize HTTP/1.1
Host: resource.example
Content-Type: application/json
Signature-Input: sig=("@method" "@authority"
    "@path" "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "scope": "data.read data.write"
}
```

## Authorization Endpoint Responses

The resource can handle authorization itself, or it can issue a resource token when the resource has an AS or the agent token includes a `ps` claim.

### Response without Resource Token

The resource handles authorization itself. It evaluates the request and returns a deferred response if user interaction is needed:

```http
HTTP/1.1 202 Accepted
Location: https://resource.example/authorize/pending/abc123
Retry-After: 0
Cache-Control: no-store
AAuth-Requirement: requirement=interaction;
    url="https://resource.example/interaction"; code="A1B2-C3D4"
Content-Type: application/json

{
  "status": "pending"
}
```

The user completes interaction at the resource's own consent page. The agent polls the `Location` URL. When authorization is complete, the resource returns `200 OK` and MAY include an `AAuth-Access` header (#aauth-access) containing a session token for subsequent calls.

```http
HTTP/1.1 200 OK
AAuth-Access: wrapped-session-token-value
Content-Type: application/json

{
  "status": "authorized",
  "scope": "data.read data.write"
}
```

If the resource can authorize immediately (e.g., the agent's key is already authorized), it returns `200 OK` directly with the optional `AAuth-Access` header.

### Response with Resource Token

Alternatively, the resource MAY return a resource token. The resource sets the `aud` claim based on its configuration:

- If the resource has its own AS: `aud` = AS URL (four-party)
- If the resource has no AS but the agent has a PS (`ps` claim): `aud` = PS URL (three-party)

When the person token carries `mission_s256`, the resource copies it into the resource token.

```json
{
  "resource_token": "eyJhbGc..."
}
```

The agent sends the resource token to its PS's token endpoint.

### Authorization Endpoint Error Responses

| Error | Status | Meaning |
|-------|--------|---------|
| `invalid_request` | 400 | Missing or invalid parameters |
| `invalid_signature` | 401 | HTTP signature verification failed |
| `invalid_person_token` | 400 | Person token malformed, expired, wrong `aud`, or signature verification failed |
| `invalid_scope` | 400 | Requested scope not recognized by the resource |
| `invalid_account` | 400 | The `account` named is not held by the person the person token identifies |
| `server_error` | 500 | Internal error |

Error responses use the error response format (#error-response-format).

## Agent Token Required {#requirement-agent-token}

A resource that requires only the agent's identity — agent identity access, with no user auth token — uses `requirement=agent-token` with a `401 Unauthorized` response when the request did not present an AAuth agent token. This signals that the resource specifically requires an AAuth agent token (`typ: aa-agent+jwt`), as distinct from any other URI-identified signing key.

```http
HTTP/1.1 401 Unauthorized
AAuth-Requirement: requirement=agent-token
```

The header carries no additional parameters: the agent already holds its agent token and need only present it. The agent retries the request, signing it per (#http-message-signatures-profile) and presenting its agent token via the `Signature-Key` header using `sig=jwt;jwt="<agent-token>"`.

`requirement=agent-token` is distinct from `requirement=auth-token`: the former asks for the agent's own identity token, with no PS or AS involved; the latter asks the agent to obtain an auth token from its PS using the enclosed resource token. It is also more specific than an `Accept-Signature-Scheme` challenge ([@!I-D.hardt-httpbis-signature-key]), which names schemes and so would accept any key those schemes can convey — `requirement=agent-token` tells the agent that an AAuth agent token in particular is required.

## Person Token Required {#requirement-person-token}

A resource that receives an authorization endpoint request carrying no person token (#person-tokens) uses `requirement=person-token` with a `401 Unauthorized` response. A resource MAY also use it on any other endpoint where it requires the person's identity before serving a request.


```http
HTTP/1.1 401 Unauthorized
AAuth-Requirement: requirement=person-token
```

The header carries no additional parameters. The agent obtains a person token for this resource from its PS's person token endpoint (#person-token-endpoint) and retries. An agent with no person server cannot satisfy this requirement and surfaces it as an error per (#requirement-values).

## AAuth-Access Response Header {#aauth-access}

The `AAuth-Access` response header carries a **session token** from a resource to an agent. The token is opaque to the agent — the resource wraps its internal authorization state (which MAY be an existing OAuth access token or other credential). It is the one AAuth credential a resource issues for its own consumption, and it names the continuing relationship the resource has established with this agent for this person. The agent passes the token back to the resource via the `Authorization` header on subsequent requests:

```http
GET /api/data HTTP/1.1
Host: resource.example
Authorization: AAuth wrapped-session-token-value
Signature-Input: sig=("@method" "@authority" "@path" \
    "authorization" "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."
```

The agent MUST include `authorization` in the covered components of its HTTP signature, binding the session token to the signed request. This prevents the token from being stolen and replayed as a standalone bearer token — the token is useless without a valid AAuth signature from the agent.

A resource MAY return a new `AAuth-Access` header on any response, replacing the agent's current session token. This enables rolling refresh without an explicit refresh flow. When the agent receives a new `AAuth-Access` value, it MUST use the new value on subsequent requests.

The `AAuth-Access` value, and the credential carried in `Authorization: AAuth`, is a `token68` ([@!RFC9110], Section 11.2). Recipients MUST reject empty values, values containing embedded whitespace or control characters, and responses carrying more than one credential.

## Resource-Managed Authorization {#resource-managed-auth}

When a resource manages authorization itself and requires user interaction, it returns a `202 Accepted` response with an interaction requirement:

```http
HTTP/1.1 202 Accepted
Location: https://resource.example/pending/abc123
Retry-After: 0
Cache-Control: no-store
AAuth-Requirement: requirement=interaction;
    url="https://resource.example/interaction"; code="A1B2-C3D4"
Content-Type: application/json

{
  "status": "pending"
}
```

The agent directs the user to the interaction URL (#user-interaction) and polls the `Location` URL per the deferred response pattern (#deferred-responses). When the interaction completes, the resource returns `200 OK` and MAY include an `AAuth-Access` header (#aauth-access) with a session token for subsequent calls.

A resource MAY also authorize the agent based solely on its identity (from the agent token) without any interaction — for example, when the agent's key is already known or the agent's domain is trusted.

## Auth Token Required {#requirement-auth-token}

A resource MUST use `requirement=auth-token` with a `401 Unauthorized` response when an auth token is required. The header MUST include a `resource-token` parameter containing a resource token JWT (#resource-token-structure).

```http
HTTP/1.1 401 Unauthorized
AAuth-Requirement: requirement=auth-token; resource-token="eyJ..."
```

The agent MUST extract the `resource-token` parameter, verify the resource token (#resource-challenge-verification), and present it to its PS's token endpoint to obtain an auth token (#ps-token-endpoint). A resource MAY also use `402 Payment Required` with the same `AAuth-Requirement` header when payment is additionally required (#requirement-responses).

A resource MAY return `requirement=auth-token` with a new resource token to a request that already includes an auth token — for example, when the request requires a higher level of authorization than the current token provides. Agents MUST be prepared for this step-up authorization at any time.

### Deferred Delivery {#deferred-auth-token}

A resource MAY instead deliver the same requirement as a `202 Accepted` deferred response (#deferred-responses), holding the invocation rather than requiring the agent to retry it:

```http
HTTP/1.1 202 Accepted
Location: /pending/f7a3b9c
Retry-After: 5
Cache-Control: no-store
AAuth-Requirement: requirement=auth-token; resource-token="eyJ..."

{
  "status": "pending"
}
```

The agent verifies the resource token and obtains an auth token exactly as in the `401` case, then completes at the pending URL: it polls with signed `GET` requests per (#deferred-responses), presenting the auth token via `Signature-Key` once it holds one. The resource executes the held invocation on the first poll that presents a valid auth token, and answers with the invocation's response.

Completion consumes the pending record. The resource MUST retain the record, with the invocation's result, at least until the auth token's `exp`, and MUST answer a repeated presentation of the same auth token at the pending URL from that result rather than executing again — a response can be lost in transit, and the agent cannot otherwise distinguish "not executed" from "executed, response lost". If the resource token expires before the agent obtains an auth token, the resource MAY include a fresh resource token in the `AAuth-Requirement` header of a subsequent poll response; it still holds the invocation, so nothing is re-sent.

Which delivery to use is the resource's choice, per invocation. The `401` is the baseline every resource can implement without holding state, and the only delivery that maps onto transports with no place to complete at a separate URL. The `202` suits a resource that can hold the invocation; a resource hosting its own interaction already returns this shape (#interaction-response-poll-authority). Agents MUST support both: the deferred-response handling agents already implement (#deferred-responses) applies unchanged, with `requirement=auth-token` in the pending response rather than `requirement=interaction`.

## Resource Token

### Resource Token Structure

A resource token is a JWT with `typ: aa-resource+jwt` containing:

Header:
- `alg`: Signing algorithm. A fully-specified identifier is REQUIRED; `Ed25519` is RECOMMENDED. Implementations MUST NOT accept `none`, the polymorphic `EdDSA` identifier, or any symmetric algorithm (#signature-algorithms).
- `typ`: `aa-resource+jwt`
- `kid`: Key identifier

Payload:
- `iss`: Resource URL
- `dwk`: `aauth-resource.json` — the well-known metadata document name for key discovery ([@!I-D.hardt-httpbis-signature-key])
- `aud`: Token audience — the PS URL (when the resource delegates authorization to the agent's PS) or the AS URL (when the resource has its own access server)
- `jti`: Unique token identifier for replay detection, audit, and revocation
- `ps`: The `iss` of the person token the resource verified — the person server whose namespace `sub` belongs to
- `sub`: The `sub` of that person token, identifying the person this authorization is for
- `presented_jti`: The `jti` of the person token whose verification established `ps` and `sub`. On the first challenge of a grant that token was presented with the request; on a step-up or per-call challenge the request carries an auth token, and the resource supplies the value from its record of the person token it verified earlier. Binding the resource token to one person token by `jti` is what makes mission stripping detectable (#why-presented-jti)
- `agent_jkt`: JWK Thumbprint ([@!RFC7638]) of the agent's current signing key
- `iat`: Issued at timestamp
- `exp`: Expiration timestamp
- `scope`: Requested scopes, as a space-separated string of scope values. Companion specifications MAY define alternative authorization claims that replace `scope`.

A resource token carries no agent identifier. `agent_jkt` binds it to the agent's key, and the recipient learns the agent's identity from the agent token that signs the token request.

Optional payload claims:
- `account`: The account the authorization is for, echoing the `account` parameter of the request that produced this token (#account-binding).
- `mission_s256`: REQUIRED when the person token carried one, copied unchanged (#person-token-structure). A resource MUST NOT omit it.
- `tenant`: Copied from the person token when it carried one.
- `interaction`: Present when the resource requires its own user-facing flow — for example, obtaining OAuth authorization from a third-party service — before the PS can issue an auth token. Contains:
  - `url`: HTTPS URL of the resource's interaction endpoint
  - `code`: Interaction code to present at that URL

Resource tokens SHOULD NOT have a lifetime exceeding 5 minutes, and when `mission_s256` is present MUST NOT expire later than that mission's `expires_at` (#mission-approval). The `jti` claim provides an audit trail for token requests; ASes are not required to enforce replay detection on resource tokens. If a resource token expires before the PS presents it to the AS (e.g., because user interaction was required), the agent MUST obtain a fresh resource token from the resource and submit a new token request to the PS. The PS SHOULD remember prior consent decisions within a mission so the user is not re-prompted when the agent resubmits a request for the same resource and scope.

### Resource Token Verification

Verify the resource token per [@!RFC7515] and [@!RFC7519]:

1. Decode the JWT header. Verify `typ` is `aa-resource+jwt`.
2. Verify `dwk` is `aauth-resource.json`. Discover the issuer's JWKS via `{iss}/.well-known/{dwk}` per the HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]). Locate the key matching the JWT header `kid` and verify the JWT signature.
3. Verify `exp` is in the future and `iat` is not in the future.
4. Verify `aud` matches the recipient's own identifier (the PS in three-party, or the AS in four-party).
5. Verify `agent_jkt` matches the JWK Thumbprint of the key used to sign the HTTP request.
6. A PS MUST resolve `presented_jti` against its retained records of issued person tokens (#person-token-endpoint). If no record exists — a tampered token, another PS's `jti`, or a token outside the retention window — the PS MUST reject the resource token with `unknown_person_token`. If a record exists, the PS MUST verify that `ps`, `sub`, `mission_s256`, and `tenant` match it exactly, rejecting the resource token on any mismatch or omission; a mismatch against an existing record is evidence of tampering, such as mission stripping, and SHOULD be surfaced to operators rather than only rejected. An AS MUST verify that `ps` names the PS that sent the token request.
7. If `mission_s256` is present, a PS MUST verify the mission is active and that the current time precedes its `expires_at` where one is set.

For a parent-mediated sub-agent authorization (a `subagent_token` is present, see (#sub-agents)), step 5 instead verifies `agent_jkt` against the `subagent_token`'s `cnf.jwk` — the sub-agent's key — because the parent, not the sub-agent, signs the HTTP request.

### Resource Challenge Verification

When an agent receives a `401` response with `AAuth-Requirement: requirement=auth-token`:

1. Extract the `resource-token` parameter.
2. Decode and verify the resource token JWT.
3. Verify `iss` matches the resource the agent sent the request to.
4. Verify `agent_jkt` matches the JWK Thumbprint of the agent's signing key.
5. Verify `ps` matches the agent's own person server, and `sub` the value in the person token the agent presented.
6. Verify `exp` is in the future.
7. Send the resource token to the agent's PS's auth token endpoint.

# Person Server {#person-server}

This section defines how agents obtain authorization from their person server. When accessing a remote resource, the agent sends a resource token to the PS's token endpoint. When performing local actions not governed by a remote resource, the agent requests permission from the PS's permission endpoint. In both cases, the PS evaluates the request against mission scope, handles user consent if needed, and uses the same requirement response patterns.

## PS Token Endpoint {#ps-token-endpoint}

The PS's `auth_token_endpoint` is where agents send token requests. The PS evaluates the request, handles user consent if needed, and either issues the auth token directly or federates with the resource's AS.

### Token Endpoint Modes

| Mode | Key Parameters | Use Case |
|------|----------------|----------|
| PS authorization | `resource_token` (`aud` = PS) | PS asserts identity and consent; resource applies its own policy (three-party) |
| AS-federated | `resource_token` (`aud` = AS) | PS federates with the resource's AS, which evaluates resource policy (four-party) |
| Call chaining | `resource_token` + `upstream_token` | Resource acting as agent |

### Concurrent Token Requests

An agent MAY have multiple token requests pending at the PS simultaneously — for example, when a mission requires access to several resources. Each request has its own pending URL and lifecycle. The PS MUST handle concurrent requests independently. Some requests may be resolved without user interaction (e.g., within existing mission scope), while others may require consent. The PS is responsible for managing concurrent user interactions — for example, by batching consent prompts or serializing them.

### Agent Token Request

The agent MUST make a signed POST to the PS's `auth_token_endpoint`. The request MUST include an HTTP Sig (#http-message-signatures-profile) and the agent MUST present its agent token via the `Signature-Key` header using `scheme=jwt`.

**Request parameters:**

- `resource_token` (REQUIRED): The resource token.
- `upstream_token` (OPTIONAL): An auth token from an upstream authorization, used in call chaining (#call-chaining).
- `subagent_token` (OPTIONAL): A sub-agent's agent token, present when a parent agent requests authorization on behalf of one of its sub-agents (#sub-agents). The signing agent (the parent) MUST be named by the `subagent_token`'s `parent_agent`.
- `justification` (OPTIONAL): A Markdown string declaring why access is being requested. The PS SHOULD present this value to the user during consent. The PS MUST sanitize the Markdown before rendering to users. The PS MAY log the `justification` for audit and monitoring purposes. **TODO:** Define recommended sections.
- `login_hint` (OPTIONAL): Hint about who to authorize, per [@!OpenID.Core] Section 3.1.2.1.
- `tenant` (OPTIONAL): Tenant identifier, per OpenID Connect Enterprise Extensions 1.0 [@OpenID.Enterprise].
- `domain_hint` (OPTIONAL): Domain hint, per OpenID Connect Enterprise Extensions 1.0 [@OpenID.Enterprise].
- `prompt` (OPTIONAL): Space-delimited, case-sensitive list of values specifying whether the PS prompts the user for reauthentication and consent, per [@!OpenID.Core] Section 3.1.2.1. Defined values: `none`, `login`, `consent`, `select_account`.
- `platform` (OPTIONAL): Identifier for the runtime platform the agent runs on. The value MUST be from the AAuth Platform Value Registry (#aauth-platform-value-registry). Describes the runtime context (where the agent runs) but does not by itself convey what security measures were applied within that context. Used for display at the PS consent screen and the PS's connected-agents dashboard. Agent-attested.
- `device` (OPTIONAL): Short human-readable string identifying the specific device or browser, intended for display so users can distinguish entries in their connected-agents dashboard (e.g., `Chrome on macOS`, `Pixel 8 (App)`). The string is opaque to receivers — they display it but do not parse it. The string MUST consist of UTF-8 printable characters only (no control characters) and MUST NOT exceed 64 characters. Agents MUST NOT include personally identifying information beyond what the user has chosen (e.g., user-supplied nicknames). Agent-attested.
- `capabilities` (OPTIONAL): An array of capability values (#aauth-capabilities) the agent can handle for this request — the request-body equivalent of the `AAuth-Capabilities` header, which is not used on PS endpoints. Without a mission, this is how the PS learns the agent's capabilities (for example, whether the agent can drive `requirement=interaction`). Within a mission, `capabilities` is OPTIONAL: if omitted, the PS uses the values captured at mission approval (#mission-approval); if present, it refreshes them for this request.

**Example request:**
```http
POST /token HTTP/1.1
Host: ps.example
Content-Type: application/json
Prefer: wait=45
Signature-Input: sig=("@method" "@authority" "@path"
    "content-type" "content-digest"
    "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "resource_token": "eyJhbGc...",
  "justification": "Find available meeting times"
}
```

### PS Response

When the resource token's `aud` matches the PS's own identifier (three-party), the PS handles user consent for the requested scope and issues an auth token asserting identity and consent — no AS federation is needed. When `aud` identifies a different server (four-party), the PS federates with the AS per (#ps-as-federation).

In both cases, the PS handles user consent if needed and returns one of:

**Direct grant response** (`200`):
```json
{
  "auth_token": "eyJhbGc...",
  "expires_in": 3600
}
```

**User interaction required response** (`202`):
```http
HTTP/1.1 202 Accepted
Location: /pending/abc123
Retry-After: 0
Cache-Control: no-store
AAuth-Requirement: requirement=interaction;
    url="https://ps.example/interaction"; code="A1B2-C3D4"
Content-Type: application/json

{
  "status": "pending"
}
```

In four-party mode, the PS may also pass through a clarification from the AS to the agent via the `202` response (#as-token-endpoint).

### Resource-Initiated Interaction {#resource-initiated-interaction}

When the resource token contains an `interaction` claim, the resource requires its own user-facing flow — typically an OAuth authorization from a third-party service — before authorization can proceed. The PS coordinates this by chaining the resource's flow with its own consent step.

The PS resolves the resource interaction before presenting its own consent: if the user declines the resource's underlying authorization, the PS authorization is vacuous, so it makes no sense to ask for PS consent first.

**Flow:**

1. The PS returns `202` to the agent with its own interaction URL — the same as for any consent interaction.
2. The user arrives at the PS's interaction page. The PS shows an interstitial informing the user that the resource requires additional permissions before the PS can authorize access.
3. The PS redirects the user to the resource's interaction endpoint using the standard callback pattern, where `ps_callback_url` is a PS-generated, per-flow URL: `{interaction.url}?code={interaction.code}&callback={ps_callback_url}`
4. The resource completes its own OAuth or permission flow. The resource MUST redirect the user to the `callback` URL when its flow completes — either successfully or with an error per (#interaction-callback-errors).
5. The PS receives the callback redirect. If the callback contains an `error` parameter, the PS abandons the authorization and returns the mapped polling error to the agent. Otherwise it continues with its own consent step.
6. Upon user approval, the PS issues the auth token and resolves the agent's pending request.

A resource's interaction endpoint MUST support the standard `?code=...&callback=...` pattern regardless of whether the redirect comes from an agent or from a PS in a chained flow — the endpoint cannot and need not distinguish callers.

The `interaction.url` MUST be an HTTPS URL. The PS MUST validate this before constructing the redirect and MUST apply its egress admission policy to the URL.

## User Interaction

When a server responds with `202` and `AAuth-Requirement: requirement=interaction`, the agent directs the user to the interaction `url`/`code` — optionally relaying through its PS first — using the mechanics defined in (#requirement-responses) and (#interaction-relay). Two details specific to the agent directing the user itself:

When the agent has a browser, it MAY append a `callback` parameter:
```
{url}?code={code}&callback={callback_url}
```

The `callback` URL is constructed from the agent's `callback_endpoint` metadata. When present, the server redirects the user's browser to the `callback` URL after the user completes the action. If no `callback` parameter is provided, the server displays a completion page and the agent relies on polling to detect completion.

The `code` parameter is single-use: once the user arrives at the URL with a valid code, the code is consumed and cannot be reused.

When the interaction completes with an error, the server redirects to the `callback` URL with an `error` query parameter instead of signaling success. See (#interaction-callback-errors).

### Interaction Callback Errors {#interaction-callback-errors}

When an interaction cannot be completed successfully, the server MUST redirect to the `callback` URL with an `error` query parameter:

```
{callback_url}?error={error_code}
```

| Error | Meaning |
|---|---|
| `access_denied` | The user explicitly declined the interaction. |
| `user_abandoned` | The user opened the interaction but did not complete it — no explicit decision was made. |
| `server_error` | The party handling the interaction encountered an internal failure. |
| `temporarily_unavailable` | The interaction service is temporarily unavailable; the caller MAY retry. |
| `interaction_expired` | The interaction session expired before the user completed the flow. |

Recipients of a callback with an `error` parameter MUST NOT treat the pending request as completable and MUST surface the error to the caller. In the resource-initiated interaction flow (#resource-initiated-interaction), the PS maps the received callback error to a polling error returned to the agent: `access_denied` maps to `denied`; `user_abandoned` maps to `abandoned`; `interaction_expired` maps to `expired`; `server_error` and `temporarily_unavailable` map to `server_error`.

## Clarification Chat

During user consent, the user may ask questions about the agent's stated justification. The PS delivers these questions to the agent, and the agent responds. This enables a consent dialog without requiring the agent to have a direct channel to the user.

Agents that support clarification chat declare this via the `AAuth-Capabilities` request header (#aauth-capabilities) by including the `clarification` capability value.

### Clarification Required {#requirement-clarification}

A server MUST use `requirement=clarification` with a `202 Accepted` response when it needs the recipient to answer a question before proceeding. The response body MUST include a `clarification` field containing the question and MAY include `timeout` and `options` fields.

```http
HTTP/1.1 202 Accepted
Location: /pending/abc123
Retry-After: 0
Cache-Control: no-store
AAuth-Requirement: requirement=clarification
Content-Type: application/json

{
  "status": "pending",
  "clarification": "Why do you need write access to my calendar?",
  "timeout": 120
}
```

Body fields:

- `clarification` (REQUIRED): A Markdown string containing the question.
- `timeout` (OPTIONAL): Seconds until the server times out the request. The recipient MUST respond before this deadline.
- `options` (OPTIONAL): An array of string values when the question has discrete choices.

The recipient MUST respond with one of the actions defined in (#agent-response-to-clarification): a clarification response, an updated request, or a cancellation. This requirement is used by both PSes (delivering user questions to agents) and ASes (requesting clarification from PSes).

### Agent Response to Clarification

The agent MUST respond to a clarification with one of:

1. **Clarification response**: POST an `action` of `clarification_response` to the pending URL.
2. **Updated request**: POST an `action` of `updated_request` with a new `resource_token` to the pending URL, replacing the original request with updated scope or parameters.
3. **Cancel request**: DELETE the pending URL to withdraw the request.

A POST body MUST include an `action` member identifying the response type. A server MUST reject a POST with a missing or unrecognized `action` value with `400 Bad Request`. The `action` member makes each POST self-describing and keeps the pending route extensible for future response types.

#### Clarification Response

The agent responds by POSTing JSON with an `action` of `clarification_response` to the pending URL:

```http
POST /pending/abc123 HTTP/1.1
Host: ps.example
Content-Type: application/json
Content-Digest: sha-256=:...:
Signature-Input: sig=("@method" "@authority" "@path"
    "content-type" "content-digest"
    "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "action": "clarification_response",
  "clarification_response":
    "I need to create a meeting invite
     for the participants you listed."
}
```

The `clarification_response` value is a Markdown string. **TODO:** Define recommended sections. After posting, the agent resumes polling with `GET`.

#### Updated Request

The agent MAY obtain a new resource token from the resource (e.g., with reduced scope) and POST it to the pending URL:

```http
POST /pending/abc123 HTTP/1.1
Host: ps.example
Content-Type: application/json
Content-Digest: sha-256=:...:
Signature-Input: sig=("@method" "@authority" "@path"
    "content-type" "content-digest"
    "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "action": "updated_request",
  "resource_token": "eyJ...",
  "justification": "I've reduced my request to read-only access."
}
```

The new resource token MUST have the same `iss`, `agent`, and `agent_jkt` as the original. The PS presents the updated request to the user. A `justification` is OPTIONAL but RECOMMENDED to explain the change to the user.

#### Cancel Request

The agent MAY cancel the request by sending DELETE to the pending URL:

```http
DELETE /pending/abc123 HTTP/1.1
Host: ps.example
Signature-Input: sig=("@method" "@authority"
    "@path" "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."
```

The PS terminates the consent session and informs the user that the agent withdrew its request. Subsequent requests to the pending URL return `410 Gone`.

### Clarification Limits

PSes SHOULD enforce limits on clarification rounds (recommended: 5 rounds maximum). Clarification responses from agents are untrusted input and MUST be sanitized before display to the user.

## Permission Endpoint {#permission-endpoint}

The permission endpoint enables agents to request permission from the PS for actions not governed by a remote resource — for example, executing tool calls, writing files, or sending messages on behalf of the user. This enables governance before any resources support AAuth. The permission endpoint MAY be used with or without a mission.

When a mission is active, the mission approval MAY include a list of pre-approved tools in the `approved_tools` field. The agent calls the permission endpoint only for actions not covered by pre-approved tools.

### Permission Request

The agent MUST make a signed POST to the PS's `permission_endpoint`. The request MUST include an HTTP Sig (#http-message-signatures-profile) and the agent MUST present its agent token via the `Signature-Key` header.

**Request parameters:**

- `action` (REQUIRED): A string identifying the action the agent wants to perform (e.g., a tool name).
- `description` (OPTIONAL): A Markdown string describing what the action will do and why.
- `parameters` (OPTIONAL): A JSON object containing the parameters the agent intends to pass to the action.
- `mission_s256` (OPTIONAL): The mission this request belongs to. When present, the PS evaluates the request against the mission context and log history.

```http
POST /permission HTTP/1.1
Host: ps.example
Content-Type: application/json
Content-Digest: sha-256=:...:
Signature-Input: sig=("@method" "@authority" "@path"
    "content-type" "content-digest"
    "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "action": "SendEmail",
  "description": "Send the proposed itinerary to the user",
  "parameters": {
    "to": "user@example.com",
    "subject": "Japan trip itinerary"
  },
  "mission_s256": "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
}
```

### Permission Response

If the PS can decide immediately, it returns `200 OK`:

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "permission": "granted"
}
```

The `permission` field is one of:

- `granted`: The agent MAY proceed with the action.
- `denied`: The agent MUST NOT proceed. The response MAY include a `reason` field with a Markdown string explaining why.

If the mission is no longer active, the PS returns a mission status error (#mission-status-errors).

If the PS requires user input, it returns a deferred response (#deferred-responses) using the same pattern as other AAuth endpoints. The agent polls until the PS returns a final response.

The PS SHOULD record all permission requests and responses. When a mission is present, the PS records the permission request and response in the mission log.

## Audit Endpoint {#audit-endpoint}

The audit endpoint enables agents to log actions they have performed, providing the PS with a record for governance and monitoring. The agent sends a signed POST to the PS's `audit_endpoint` after performing an action. The audit endpoint requires a mission — there is no audit outside a mission context.

### Audit Request

The agent MUST make a signed POST to the PS's `audit_endpoint`. The request MUST include an HTTP Sig (#http-message-signatures-profile) and the agent MUST present its agent token via the `Signature-Key` header.

**Request parameters:**

- `mission_s256` (REQUIRED): The mission this record belongs to.
- `action` (REQUIRED): A string identifying the action that was performed.
- `description` (OPTIONAL): A Markdown string describing what was done and the outcome.
- `parameters` (OPTIONAL): A JSON object containing the parameters that were used.
- `result` (OPTIONAL): A JSON object containing the result or outcome of the action.

```http
POST /audit HTTP/1.1
Host: ps.example
Content-Type: application/json
Content-Digest: sha-256=:...:
Signature-Input: sig=("@method" "@authority" "@path"
    "content-type" "content-digest"
    "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "mission_s256": "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk",
  "action": "WebSearch",
  "description": "Searched for flights to Tokyo in May",
  "parameters": {
    "query": "flights to Tokyo May 2026"
  },
  "result": {
    "status": "completed",
    "summary": "Found 12 flight options"
  }
}
```

### Audit Response

The PS returns `201 Created` to acknowledge the record:

```http
HTTP/1.1 201 Created
```

The audit endpoint is fire-and-forget — the agent SHOULD NOT block on the response. The PS records the audit entry in the mission log. The PS MAY use audit records to detect anomalous behavior, alert the user, or revoke the mission.

If the mission is no longer active, the PS returns a mission status error (#mission-status-errors).

## Interaction Endpoint {#interaction-endpoint}

The interaction endpoint enables the agent to reach the user through the PS. The agent uses this endpoint to forward interaction requirements from resources that it cannot handle directly, to ask the user questions, and to relay payment approvals. Each is something the agent cannot do itself and needs the person for. Proposing mission completion is not among them: it is a mission lifecycle transition and belongs at the `mission_endpoint` (#mission-completion), alongside the proposal that started the mission. The `interaction_endpoint` URL is published in the PS's well-known metadata (#ps-metadata). The interaction endpoint MAY be used with or without a mission.

### Interaction Request

The agent MUST make a signed POST to the PS's `interaction_endpoint`. The request MUST include an HTTP Sig (#http-message-signatures-profile) and the agent MUST present its agent token via the `Signature-Key` header.

**Request parameters:**

- `type` (REQUIRED): The type of interaction. One of `interaction`, `payment`, or `question`.
- `description` (OPTIONAL): A Markdown string providing context for the user.
- `url` (OPTIONAL): The interaction URL to relay to the user (for `interaction` and `payment` types).
- `code` (OPTIONAL): The interaction code associated with the URL.
- `max_wait` (OPTIONAL): Maximum seconds the PS SHOULD hold the relay's deferred response before resolving it (for `interaction` and `payment` types). When the interaction URL is resource-hosted, the PS resolves its deferred response once the user has engaged or when this window elapses, whichever comes first; the agent then relies on the resource's pending URL for completion (#interaction-response-poll-authority). Absent `max_wait`, the PS resolves the relay when the user has engaged or it can make no further progress.
- `question` (OPTIONAL): A Markdown string containing a question for the user (for `question` type).
- `mission_s256` (OPTIONAL): The mission this request belongs to.

**Relay interaction example:**

```http
POST /interaction HTTP/1.1
Host: ps.example
Content-Type: application/json
Content-Digest: sha-256=:...:
Signature-Input: sig=("@method" "@authority" "@path"
    "content-type" "content-digest"
    "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "type": "interaction",
  "description": "The booking service needs you to confirm payment",
  "url": "https://booking.example/confirm",
  "code": "X7K2-M9P4",
  "mission_s256": "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
}
```

### Interaction Response {#interaction-response-poll-authority}

For `interaction` and `payment` types, the PS relays the interaction to the user and returns a deferred response (#deferred-responses).

When the interaction URL is hosted by the **PS itself**, the PS's deferred response is authoritative for completion: the agent polls it until the user completes the interaction.

When the interaction URL is hosted by a **resource** — the common case for a relayed `interaction`, such as a proxy's OAuth bootstrap page or a merchant's payment-confirmation page — the user completes the interaction at the resource, not at the PS. The agent then holds two pending URLs: the resource's original `Location` (from the resource's `202`) and the PS's relay `Location`. The **resource's** pending URL is authoritative for completion. The PS's relay deferred response reports only that the relay reached the user: it returns `status: "interacting"` (#deferred-responses) once the user has engaged, and a terminal response when the PS has done all it can — the user engaged, the agent's `max_wait` window elapsed, or the PS can make no further progress. The agent MUST treat the resource's pending URL as the signal that the interaction is complete, and continues polling it after the PS relay resolves.

If the PS has no channel available to relay an `interaction` or `payment` to the user, it returns `interaction_unavailable` (#interaction-endpoint-errors). This is the PS declining to relay this specific interaction; the agent falls back to directing the user to the `url`/`code` itself (#interaction-relay). It is distinct from `user_unreachable`: `interaction_unavailable` is non-terminal — the agent can still drive the interaction — whereas `user_unreachable` (#token-endpoint-error-codes) is terminal, meaning no party can reach the user.

For `question` type, the PS delivers the question to the user and returns the answer:

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "answer": "Yes, go ahead with the refundable option."
}
```

If the PS cannot reach the user and the agent does not have the `interaction` capability, the PS returns `user_unreachable` (#token-endpoint-error-codes) — a terminal error, since no party can reach the user. If the mission is no longer active, the PS returns a mission status error (#mission-status-errors). The PS SHOULD record all interaction requests and responses. When a mission is active, the PS records the interaction in the mission log.

### Interaction Endpoint Errors {#interaction-endpoint-errors}

Errors use the error response format (#error-response-format).

| Error | Status | Meaning |
|-------|--------|---------|
| `interaction_unavailable` | 424 | The PS has no channel available to relay this `interaction` or `payment` to the user. Non-terminal: the agent falls back to directing the user to the `url`/`code` itself (#interaction-relay). Distinct from the terminal `user_unreachable` (#token-endpoint-error-codes). |

## Re-authorization

AAuth does not have a separate refresh token or refresh flow. When an auth token expires, the agent obtains a fresh resource token from the resource's authorization endpoint and submits it to the PS's token endpoint — the same flow as the initial authorization. This gives the resource a voice in every re-authorization: the resource can adjust scope, require step-up authorization, or deny access based on current policy.

When an agent rotates its signing key, all existing auth tokens are bound to the old key and can no longer be used. The agent MUST re-authorize by obtaining fresh resource tokens and submitting them to the PS.

Agents SHOULD proactively obtain a new agent token and refresh all auth tokens before the current agent token expires, to avoid service interruptions. Auth tokens MUST NOT have an `exp` value that exceeds the `exp` of the agent token used to obtain them — a resource MUST reject an auth token whose associated agent token has expired.

# Mission {#missions}

Missions are OPTIONAL. The protocol operates in all modes without missions. When used, missions provide scoped authorization contexts that guide an agent's work across multiple resource accesses — enabling scope pre-approval, reduced consent fatigue, and centralized audit. A mission is a natural-language description of what the agent intends to accomplish, proposed by the agent and approved by the PS. The PS uses the mission to evaluate every subsequent request in context — it is the only party with the mission content, the user relationship, and the full history of the agent's actions. Once approved, the agent names the mission's `s256` when it obtains person tokens (#person-token-endpoint), from where it flows into resource tokens and auth tokens.

The `mission_endpoint` is the agent's surface for the missions it owns. Parties other than the owning agent — the person, an administrator, a management service — read and manage missions at the `mission_control_endpoint` (#ps-metadata) instead, under a different authentication model.

The agent has three operations, all of the same shape: it proposes, the person decides, and the PS returns a deferred response (#deferred-responses) with clarification chat available (#clarification-chat) whenever the person must be asked.

| Request | Operation |
|---|---|
| `POST {mission_endpoint}` | Propose a mission (#mission-creation) |
| `POST {mission_endpoint}/{mission_s256}` with `action: update` | Record a change in the work (#mission-update) |
| `POST {mission_endpoint}/{mission_s256}` with `action: completion` | Propose that the mission is finished (#mission-completion) |

The `action` member is REQUIRED on requests to a mission's own URL, and a PS MUST reject a request with a missing or unrecognized `action` with `400 Bad Request`. This is the same discriminator the pending route uses (#agent-response-to-clarification), for the same reason: it makes each POST self-describing and leaves the route extensible. Errors at these requests are defined in (#mission-endpoint-errors).

## Mission Creation {#mission-creation}

The agent creates a mission by sending a proposal to the PS's `mission_endpoint`. The agent MUST make a signed POST with an HTTP Sig (#http-message-signatures-profile), presenting its agent token via the `Signature-Key` header using `scheme=jwt`.

The proposal includes a Markdown description of what the agent intends to accomplish, and MAY include a list of tools the agent wants to use and a list of resources it expects to access:

```json
{
  "description": "# Plan Japan Vacation\n\n
    Plan and book a trip to Japan next month
    for 2 adults. Budget around $5k.
    Propose an itinerary before booking.",
  "tools": [
    {
      "name": "WebSearch",
      "description": "Search the web"
    },
    {
      "name": "BookFlight",
      "description": "Book flights"
    },
    {
      "name": "BookHotel",
      "description": "Book hotels"
    }
  ],
  "resources": [
    "https://flights.example",
    "https://hotels.example"
  ]
}
```

**`resources`** (OPTIONAL). An array of HTTPS URLs conforming to the Server Identifier requirements (#server-identifiers). The PS presents them to the person alongside the description, and issues a person token for each it approves in the approval response (#mission-approval), sparing the agent a separate request per resource. An agent MAY still obtain person tokens for other resources later (#person-token-endpoint), subject to the PS's policy; the list is not a limit on the mission.

The PS MAY return a `202 Accepted` deferred response (#deferred-responses) if human review, clarification, or approval is needed. During this phase, the PS and user may engage in clarification chat (#clarification-chat) with the agent to refine the mission scope, ask questions about the agent's intent, or negotiate which tools are needed. The PS or user may also modify the description — the approved mission MAY differ from the original proposal.

## Mission Approval {#mission-approval}

When the PS approves the mission, it returns the approved mission — the **mission blob** — together with the mission's `s256` and a person token for each approved resource:

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "s256": "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk",
  "mission": "eyJhcHByb3ZlciI6Imh0dHBzOi8vcHMuZXhhbXBsZSIsImFnZW50Ijoi...",
  "capabilities": [
    "interaction",
    "payment"
  ],
  "person_tokens": {
    "https://flights.example": "eyJhbGc...",
    "https://hotels.example": "eyJhbGc..."
  }
}
```

The `mission` member decodes to the mission blob:

```json
{
  "approver": "https://ps.example",
  "agent": "aauth:assistant@agent.example",
  "approved_at": "2026-04-07T14:30:00Z",
  "expires_at": "2026-05-07T14:30:00Z",
  "description": "# Plan Japan Vacation\n\n
    Plan and book a trip to Japan next month
    for 2 adults. Budget around $5k.
    Propose an itinerary before booking.",
  "approved_tools": [
    {
      "name": "WebSearch",
      "description": "Search the web"
    },
    {
      "name": "Read",
      "description": "Read files and web pages"
    }
  ],
  "approved_resources": [
    "https://flights.example",
    "https://hotels.example"
  ]
}
```

Response members:

- `s256` (REQUIRED): The mission identifier — the unpadded base64url encoding of the SHA-256 digest of the bytes `mission` decodes to.
- `mission` (REQUIRED): The mission blob, base64url-encoded without padding. An agent SHOULD verify `s256` against the decoded bytes before first use of the mission, and MAY skip verification where it trusts the PS unconditionally.
- `capabilities` (OPTIONAL): Array of capability strings (e.g., `interaction`, `payment`) that the PS can provide on behalf of the person for this session. The PS determines these based on whether it can currently reach the person — for example, via push notification, email, or an active session. The agent unions them with its own when constructing the `AAuth-Capabilities` request header (#aauth-capabilities). They describe this moment rather than a term of the mission, and are neither part of the blob nor covered by the digest.
- `person_tokens` (OPTIONAL): An object mapping resource identifiers to person tokens (#person-tokens), each carrying `mission_s256` set to `s256`. Present when the proposal named `resources`. A PS MAY omit a resource it declines to issue for; the agent MAY request one for it later and be refused individually. Each token carries its own `exp`, so no separate expiry is returned.

The mission blob MUST include:

- `approver`: HTTPS URL of the entity that approved the mission. Currently this is always the PS.
- `agent`: The agent identifier (`aauth:local@domain`).
- `approved_at`: ISO 8601 timestamp of when the mission was approved. Ensures the `s256` is globally unique.
- `description`: Markdown string describing the approved mission scope.

The mission blob MAY include:

- `expires_at`: ISO 8601 timestamp after which the PS treats the mission as terminated. When absent, the mission runs until it is completed or revoked. Every PS decision path that acts on a mission MUST compare the current time to `expires_at` and MUST treat a mission past it as terminated (#mission-status-errors). No token carrying `mission_s256` — person, resource, or auth — may have an `exp` later than `expires_at`; an issuer MUST shorten the token's lifetime to fit.
- `approved_tools`: Array of tool objects (each with `name` and `description`) that the agent may use without per-call permission at the PS's permission endpoint (#permission-endpoint). Nothing in the protocol enforces this list; see (#why-tools-are-not-enforced).
- `approved_resources`: Array of resource identifiers the person approved for this mission, drawn from the `resources` the proposal named. It records which resources were pre-approved, so an audit of the mission shows what the person agreed to before the agent began. It is not a limit: the agent MAY obtain person tokens for other resources during the mission, subject to the PS's policy, and those accesses appear in the mission log rather than in the blob.

The member lists above are a floor, not a closed set. A PS MAY include additional members, and a companion specification MAY define them; a reader MUST ignore members it does not recognize (#aauth-capabilities). Because `s256` covers the bytes the PS persists, a blob carrying an additional member has a different identifier from one without — which is correct, since they are different missions. Member names in the mission blob are governed by this specification; a companion specification defining one SHOULD coordinate the name to avoid collision.

### Mission Identifier {#mission-identifier}

`s256` identifies the mission everywhere it appears — as the `mission_s256` claim of person, resource, and auth tokens, and as the `mission_s256` parameter of PS requests.

It is a hash rather than an opaque identifier so that it is provable. An opaque identifier would name the mission but leave the PS free to attach it to any text afterwards. A digest binds every token carrying `mission_s256` to one specific mission, so the mission in the PS's log and the mission those tokens authorized are demonstrably the same.

The PS MUST compute `s256` over the exact bytes it persists as the mission blob, MUST return those same bytes as `mission`, and MUST serve them wherever it later exposes the mission for audit.

The approved description MAY differ from the proposal — the PS or user may refine, constrain, or expand the mission during review. The approved tools MAY be a subset of the proposed tools. The agent uses `s256` as `mission_s256` when requesting further person tokens (#person-token-endpoint).

## Mission Log {#mission-log}

The approved mission description is immutable — the `s256` hash binds it permanently. Missions do not change; they accumulate context.

All agent interactions with the PS within a mission context form the **mission log**: token requests (with justifications), accepted updates (#mission-update), permission requests and responses, audit records, interaction requests, and clarification chats. The PS maintains this log as an ordered record of the agent's actions and the governance decisions made. The mission log gives the PS the full history it needs to evaluate whether each new request is consistent with the mission's intent.

The agent names the mission when it requests a person token (#person-token-endpoint); the PS validates it and stamps `mission_s256` into the token, from where it flows into the resource token and the auth token. When the agent sends a resource token to its PS, the PS evaluates the request against the mission context and log history before federating with the resource's AS.

## Mission Update {#mission-update}

Work changes. When what the agent is doing no longer matches the description the person approved, it records the change rather than proceeding silently:

```http
POST /mission/dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk HTTP/1.1
Host: ps.example
Content-Type: application/json
Content-Digest: sha-256=:...:
Signature-Input: sig=("@method" "@authority" "@path"
    "content-type" "content-digest"
    "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "action": "update",
  "description": "# Hotel unavailable\n\n
    The hotel in the itinerary has no availability.
    Proposing a comparable property two blocks away
    at a similar rate."
}
```

- `action` (REQUIRED): `update`.
- `description` (REQUIRED): A Markdown string describing what changed.

The PS MAY accept the update on its own, or return a `202 Accepted` deferred response while the person reviews it. On acceptance it appends the update to the mission log and returns its `s256` — the unpadded base64url SHA-256 digest of the update's bytes as the PS persists them — so the sequence of accepted updates is verifiable, not merely stored:

```json
{
  "s256": "Q2h1Y2sgSW50ZWdyaXR5IENoZWNr..."
}
```

An update does not change the mission. The blob is immutable, `mission_s256` is unchanged, and every token carrying it remains valid — which is the point: the agent keeps working while the record catches up.

What the update changes is the context the PS evaluates against. From acceptance onward, the mission's meaning is the approved blob **plus its accepted updates**, and a party auditing the mission MUST read both. The blob alone records what the person approved at the outset, not what they approved in total.

An update may narrow or broaden the work. Both require the person's acceptance when the PS decides the change warrants it, and the PS applies the same judgment to an update that it applied to the proposal. When the work has changed enough that the original description no longer describes it, that is a new mission rather than an update, and the old one is terminated as `superseded` (#mission-management).

## Mission Completion {#mission-completion}

When the agent believes the mission is complete, it proposes completion with a summary of what was accomplished:

```http
POST /mission/dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk HTTP/1.1
Host: ps.example
Content-Type: application/json
Content-Digest: sha-256=:...:
Signature-Input: sig=("@method" "@authority" "@path"
    "content-type" "content-digest"
    "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "action": "completion",
  "summary": "Booked flights and hotel for 7-14 May.
    Itinerary sent. Total $4,180."
}
```

- `action` (REQUIRED): `completion`.
- `summary` (REQUIRED): A Markdown string summarizing what the agent accomplished.

The PS presents the summary to the person, returning a deferred response while they review. The person either accepts — the PS terminates the mission with reason `completed` and returns `200 OK` — or responds with follow-up questions via clarification chat (#clarification-chat), leaving the mission active. This is the most common mission lifecycle path.

The agent proposes completion; it does not declare it. Only the person's acceptance terminates the mission.

## Mission Management {#mission-management}

A mission has one of two states:

- **active**: The mission is in progress. The agent can make requests against it.
- **terminated**: The mission is permanently ended. The PS MUST reject requests with `mission_terminated`.

A terminated mission MUST NOT return to `active`. A caller that needs to continue the work proposes a new mission.

The PS records why a mission terminated, alongside the mission rather than inside the immutable blob. This document defines the following reasons; the list is open, and a recipient that does not recognize a reason MUST retain the `terminated` state and treat the reason as an opaque audit value.

| Reason | Meaning |
|---|---|
| `completed` | The person accepted the agent's completion proposal (#mission-completion) |
| `revoked` | The person, the owning agent, or an authorized administrator withdrew the mission |
| `expired` | The mission reached its `expires_at` (#mission-approval) |
| `superseded` | The mission was replaced by another approved mission |
| `administrative` | An authorized administrator ended the mission under local policy |

A termination reason MUST NOT be exposed as a mission state or used to permit a later transition.

Reading a mission's status, terminating one, and querying delegation are operations for parties other than the owning agent, and belong at the `mission_control_endpoint` (#ps-metadata). They will be defined in a companion specification, along with the administrative principals that invoke them.

## Mission Endpoint Errors {#mission-endpoint-errors}

| Error | Status | Meaning |
|-------|--------|---------|
| `invalid_request` | 400 | The `{mission_s256}` path segment is malformed, or `action` is missing or unrecognized |
| `mission_not_found` | 404 | No such mission, or it is not this agent's |
| `mission_terminated` | 403 | This agent's mission, permanently ended (#mission-status-errors) |

A PS MUST return the same status, error, body, header set, and observably equivalent timing whether the mission does not exist or the authenticated agent does not own it, and MUST NOT disclose anything about a mission before authorization succeeds. Note that the natural arrangement — checking ownership only after a successful lookup — leaks the difference in timing.

The distinction matters because `mission_s256` travels in auth tokens to resources. Without this rule, a resource operator running an agent could POST a mission reference it had observed and learn from the response whether that mission was still live, reading mission status through a side channel instead of through the control plane, where the read would be authorized.

A terminated mission is deliberately distinguishable: the agent that owns it already knows it exists, and needs `termination_reason` to decide whether to propose a new mission.

A PS SHOULD rate-limit and security-log repeated failures, and SHOULD NOT retain raw mission references from failed requests longer than abuse correlation requires.

## Mission Status Errors {#mission-status-errors}

When an agent makes a request to any PS endpoint with a `mission_s256` parameter referencing a mission that is no longer active, the PS MUST return an error:

```http
HTTP/1.1 403 Forbidden
Content-Type: application/problem+json

{
  "error": "mission_terminated",
  "mission_status": "terminated",
  "termination_reason": "expired"
}
```

| Error | Mission Status | Meaning |
|-------|---------------|---------|
| `mission_terminated` | `terminated` | The mission is permanently ended. The agent MUST stop acting on this mission. |

`termination_reason` is OPTIONAL and carries a value from (#mission-management). It is one error rather than one per reason because the reason set is open: an agent keys its behaviour on `mission_terminated` and reads the reason for context — `expired` invites proposing a new mission, `revoked` does not.

# Access Server Federation {#access-server-federation}

This section defines auth tokens and the mechanisms by which they are issued. The auth token is the end result of the authorization flow — a JWT issued by an access server that grants an agent access to a specific resource. This section covers the AS token endpoint, PS-AS federation, and the auth token structure.

## AS Token Endpoint {#as-token-endpoint}

The AS evaluates resource policy and issues auth tokens. It accepts JSON POST requests.

### PS-to-AS Token Request

The PS MUST make a signed POST to the AS's `auth_token_endpoint`. The PS authenticates via an HTTP Sig (#http-message-signatures-profile).

**Request parameters:**

- `resource_token` (REQUIRED): The resource token issued by the resource.
- `agent_token` (REQUIRED): The agent's agent token. For a parent-mediated sub-agent authorization, this is the parent (top-level) agent's token.
- `subagent_token` (OPTIONAL): A sub-agent's agent token, present when the PS federates a parent-mediated sub-agent authorization (#sub-agents). When present, the AS binds the issued auth token to the sub-agent, verifying `resource_token`'s `agent_jkt` against the `subagent_token`'s `cnf.jwk`.
- `upstream_token` (OPTIONAL): An auth token from an upstream authorization, used in call chaining (#call-chaining).

The resource token carries the person's identity as `ps` and `sub` (#resource-token-structure), so the AS needs no separate identity parameter and `requirement=claims` (#requirement-claims) is reserved for claims beyond it.

`agent_token` remains REQUIRED even though the resource never sees an agent identifier. A resource deploys an AS because it wants policy evaluated, and an agent token MAY carry claims bearing on that decision — software attestation, platform integrity, secure enclave status, workload identity (#agent-token-structure). The resource enforces; the AS evaluates; posture goes to the evaluator.

**Example request:**
```http
POST /token HTTP/1.1
Host: as.resource.example
Content-Type: application/json
Signature-Input: sig=("@method" "@authority"
    "@path" "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwks_uri;
    jwks_uri="https://ps.example/.well-known/jwks.json"

{
  "resource_token": "eyJhbGc...",
  "agent_token": "eyJhbGc..."
}
```

### AS Response

The PS calls the AS token endpoint and follows the standard deferred response loop (#deferred-responses): it handles `202` and `402` responses and continues until it receives a `200` with an auth token or a terminal error.

**Direct grant response** (`200`):
```json
{
  "auth_token": "eyJhbGc...",
  "expires_in": 3600
}
```

The AS MAY return `202 Accepted` with an `AAuth-Requirement` header indicating what is needed before it can issue an auth token:

- **`requirement=claims`** (#requirement-claims): The AS needs identity claims. The body includes `required_claims`. The PS MUST provide the requested claims (including a directed `sub` identifier for the resource) by POSTing to the `Location` URL. The AS cannot know what claims it needs until it has processed the resource token.
- **`requirement=clarification`** (#requirement-clarification): The AS needs a question answered. The PS triages who answers: itself (if mission context has the answer), the user, or the agent. The PS MAY pass the clarification down to the agent via a `202` response.
- **`requirement=interaction`** (#requirement-responses): The AS requires user interaction — for example, the user must authenticate at the AS to bind their PS, or the resource owner must approve access. The PS directs the user to the AS's interaction URL, or passes the interaction requirement back to the agent.
- **`requirement=approval`** (#requirement-responses): The AS is obtaining approval without requiring user direction.

**Payment required** (`402`):

The AS MAY return `402 Payment Required` when a billing relationship is required before it will issue auth tokens. The `402` response includes payment details per an applicable payment protocol such as x402 [@x402] or the Machine Payment Protocol (MPP) ([@I-D.ryan-httpauth-payment]). The response MUST include a `Location` header for the PS to poll after payment is settled.

```http
HTTP/1.1 402 Payment Required
Location: https://as.resource.example/token/pending/xyz
WWW-Authenticate: Payment id="x7Tg2pLq", method="stripe",
    request="eyJhbW91bnQiOiIxMDAw..."
```

The PS settles payment per the indicated protocol and polls the `Location` URL. When payment is confirmed, the AS continues processing the token request — which may result in a `200` with an auth token, or a further `202` requiring claims, interaction, or approval.

The PS caches the billing relationship per AS. Future token requests from the same PS to the same AS skip the billing step. The payment protocol, settlement mechanism, and billing terms are out of scope for this specification.

### Auth Token Delivery

When the AS issues an auth token (`200` response), the PS MUST verify the auth token before returning it to the agent:

1. Verify the auth token JWT signature using the AS's JWKS (#jwks-discovery).
2. Verify `iss` matches the AS the PS sent the token request to.
3. Verify `aud` matches the resource identified by the resource token's `iss`.
4. Verify `cnf.jwk` matches the agent's signing key.
5. Verify `sub` matches the directed identifier the PS issues for this person at this resource.
6. Verify `scope` is consistent with what was requested — not broader than the scope in the resource token.

After verification, the PS returns the auth token to the agent. The agent presents the auth token to the resource via the `Signature-Key` header (#auth-token-usage). The resource verifies the auth token against the AS's JWKS (#auth-token-verification).

The agent receives the auth token from its trusted PS, so signature verification is not strictly required. However, agents SHOULD verify the auth token's signature to detect errors early. Agents MUST verify that `aud` and `cnf` match their own values.

## Claims Required {#requirement-claims}

A server MUST use `requirement=claims` with a `202 Accepted` response when it needs identity claims to process a request. The response body MUST include a `required_claims` field containing an array of claim names.

```http
HTTP/1.1 202 Accepted
Location: https://as.resource.example/token/pending/xyz
Retry-After: 0
Cache-Control: no-store
AAuth-Requirement: requirement=claims
Content-Type: application/json

{
  "status": "pending",
  "required_claims": ["email", "tenant"]
}
```

The recipient MUST provide the requested claims (including a directed user identifier as `sub`) by POSTing to the `Location` URL. The recipient MUST include an HTTP Sig (#http-message-signatures-profile) on the POST. Claims not recognized by the recipient SHOULD be ignored. This requirement is used by ASes to request identity claims from PSes during token issuance.

## PS-AS Federation {#ps-as-federation}

The PS is the only entity that calls AS token endpoints. When the PS receives a resource token from an agent, the resource token's `aud` claim identifies where to send the token request. If `aud` matches the PS's own identifier, the PS issues an auth token asserting identity and consent for the requested scope (three-party). If `aud` identifies a different server (an AS), the PS discovers the AS's metadata at `{aud}/.well-known/aauth-access.json` (#access-server-metadata) and calls the AS's `auth_token_endpoint` (#as-token-endpoint) (four-party).

### PS-AS Trust Establishment {#ps-as-trust-establishment}

Trust between the PS and AS may be pre-established out of band or emerge dynamically from the AS's response to the PS's first token request — AAuth does not require a separate registration step before the protocol can be used. The AS evaluates the token request and responds based on its current policy:

- **Pre-established**: A business relationship configured between the PS and AS, potentially including payment terms, SLA, and compliance requirements. The AS recognizes the PS and processes the token request directly.
- **Interaction**: The AS returns `202` with `requirement=interaction`, directing the user to authenticate at the AS and confirm their PS. After this one-time binding, the AS trusts future requests from that PS for that user. This is the primary mechanism for establishing trust dynamically.
- **Payment**: The AS returns `402`, requiring the PS to establish a billing relationship before tokens will be issued. The PS settles payment per the indicated protocol and polls for completion. After billing is established, the AS trusts future requests from that PS.
- **Claims only**: The AS may trust any PS that can provide sufficient identity claims for a policy decision, without requiring a prior relationship.

These mechanisms may compose: for example, the AS may first require payment (`402`), then interaction for user binding (`202`), then claims (`202`) before issuing an auth token. Each step uses the same `Location` URL for polling.

~~~ ascii-art
PS                        User                    AS
  |                         |                       |
  |  POST /token            |                       |
  |  resource_token,        |                       |
  |  agent_token            |                       |
  |------------------------------------------------>|
  |                         |                       |
  |  402 Payment Required   |                       |
  |  Location: /token/pending/xyz                   |
  |<------------------------------------------------|
  |                         |                       |
  |  [PS settles payment per indicated protocol]    |
  |                         |                       |
  |  GET /token/pending/xyz |                       |
  |------------------------------------------------>|
  |                         |                       |
  |  202 Accepted           |                       |
  |  requirement=interaction|                       |
  |  url=".../authorize/abc"|                       |
  |<------------------------------------------------|
  |                         |                       |
  |  direct user to URL     |                       |
  |------------------------>|                       |
  |                         |  authenticate, bind PS|
  |                         |---------------------->|
  |                         |                       |
  |  GET /token/pending/xyz |                       |
  |------------------------------------------------>|
  |                         |                       |
  |  202 Accepted           |                       |
  |  requirement=claims     |                       |
  |<------------------------------------------------|
  |                         |                       |
  |  POST /token/pending/xyz|                       |
  |  {sub, email, tenant}   |                       |
  |------------------------------------------------>|
  |                         |                       |
  |  200 OK (auth_token)    |                       |
  |<------------------------------------------------|
  |                         |                       |
~~~
{: #fig-mm-as-trust title="PS-AS Trust Establishment (all steps shown — most requests skip some)"}

### AS Decision Logic (Non-Normative) {#as-decision-logic}

The following is a non-normative description of how an AS might evaluate a token request:

1. **PS = AS (same entity)**: Grant directly. The federation call is internal and trust is implicit. See (#ps-as-collapse).
2. **User has bound this PS at the AS**: Apply the user's configured policy for this PS.
3. **PS is pre-established (enterprise agreement)**: Apply the organization's configured policy.
4. **Resource is open or has a free tier**: Grant with restricted scope or rate limits.
5. **Resource requires billing**: Return `402` with payment details.
6. **Resource requires user binding**: Return `202` with `requirement=interaction`.
7. **AS needs identity claims to decide**: Return `202` with `requirement=claims`.
8. **Insufficient trust for requested scope**: Return `403`.

The AS is not required to follow this order. The decision logic is entirely at the AS's discretion based on resource policy.

### Organization Visibility

Organizations benefit from the trust model: an organization's agents share a single PS, and internal resources may share a single AS. The PS provides centralized audit across all agents and missions. Federation is only incurred at the boundary, when an internal agent accesses an external resource. When the same server fills both the PS and AS roles, federation collapses to a single internal evaluation — see (#ps-as-collapse).

### PS-AS Collapse {#ps-as-collapse}

When the agent's PS and the resource's chosen AS are the same server (an instance of role collocation, see (#roles)), federation collapses to a single internal evaluation. This is operationally similar to three-party access — no cross-server hop — but structurally different:

- **Three-party (PS authorization)**: the resource has no AS; the resource token's `aud` is the PS, and the auth token has `dwk: aauth-person.json`. The resource trusts identity claims and applies its own policy.
- **PS-AS collapse**: the resource has chosen an AS that also operates as the agent's PS; the resource token's `aud` is the AS, and the auth token has `dwk: aauth-access.json`. The resource trusts the AS's policy verdict.

The server applies user consent (its PS responsibility) and resource policy (its AS responsibility) in a single evaluation. Trust between PS and AS is implicit because they are the same entity.

## Auth Token {#auth-tokens}

### Auth Token Structure

An auth token is a JWT with `typ: aa-auth+jwt` containing:

Header:
- `alg`: Signing algorithm. A fully-specified identifier is REQUIRED; `Ed25519` is RECOMMENDED. Implementations MUST NOT accept `none`, the polymorphic `EdDSA` identifier, or any symmetric algorithm (#signature-algorithms).
- `typ`: `aa-auth+jwt`
- `kid`: Key identifier

Required payload claims:
- `iss`: The URL of the server that issued the auth token — an AS (four-party) or a PS asserting identity (three-party)
- `dwk`: The well-known metadata document name for key discovery ([@!I-D.hardt-httpbis-signature-key]). `aauth-access.json` when issued by an AS, `aauth-person.json` when issued by a PS.
- `aud`: The URL of the resource the agent is authorized to access.
- `jti`: Unique token identifier for replay detection, audit, and revocation
- `ps`: The person server the person is represented by. Equal to `iss` when a PS issued the token. An intermediary acting as an agent routes its downstream token request here (#call-chaining).
- `sub`: Directed user identifier, copied from the resource token. An opaque string, unique within `iss`, that identifies the person. The PS SHOULD derive a pairwise pseudonymous value per resource (`aud`), so different resources see different values for the same person (#directed-identifiers).
- `cnf`: Confirmation claim with `jwk` containing the agent's public key. The JWK MUST carry a fully-specified `alg` member (#signature-algorithms).
- `iat`: Issued at timestamp
- `exp`: Expiration timestamp. Auth tokens MUST NOT have a lifetime exceeding 1 hour, and when `mission_s256` is present MUST NOT be later than that mission's `expires_at` (#mission-approval).

An auth token carries no agent identifier and no delegation chain. `cnf` binds it to one key, and the resource enforces against `sub` and `scope`.

Optional payload claims:
- `scope`: Authorized scopes, as a space-separated string of scope values consistent with [@!RFC9068] Section 2.2.3
- `account`: The account the authorization is for, copied from the resource token (#account-binding).
- `mission_s256`: Copied from the resource token when it carried one. Present when the auth token was issued in the context of a mission.
- `tenant`: Tenant identifier per OpenID Connect Enterprise Extensions 1.0 [@OpenID.Enterprise], declaring the organization the person belongs to. `(iss, tenant)` identifies the organization. It is not part of the person's identifier, which is `(iss, sub)`.

The auth token MAY include additional claims registered in the IANA JSON Web Token Claims Registry [@!RFC7519] or defined in OpenID Connect Core 1.0 [@!OpenID.Core] Section 5.1.

### Auth Token Usage

Agents present auth tokens via the `Signature-Key` header ([@!I-D.hardt-httpbis-signature-key]) using `scheme=jwt`:

```http
Signature-Key: sig=jwt;
    jwt="eyJhbGciOiJFZERTQSIsInR5cCI6ImF1dGgr..."
```

Once an auth token has been issued for a resource, the agent presents the auth token (not the agent token) via `Signature-Key` on subsequent requests to that resource. The auth token's `cnf.jwk` is the same key that signed the request, so HTTP Message Signature verification proceeds identically to the agent-token case.

### Auth Token Verification

When a resource receives an auth token, verify per [@!RFC7515] and [@!RFC7519]. A valid JWT signature alone is not a complete AAuth authorization check — both JWT trust and request-context binding must pass.

#### JWT Trust Verification

1. Decode the JWT header. Verify `typ` is `aa-auth+jwt`.
2. Verify `dwk` is `aauth-access.json` (auth token from an AS) or `aauth-person.json` (auth token from a PS asserting identity). Discover the issuer's JWKS via `{iss}/.well-known/{dwk}` per the HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]). Locate the key matching the JWT header `kid` and verify the JWT signature.
3. Verify `exp` is in the future and `iat` is not in the future.
4. Verify `iss` is a valid HTTPS URL.

#### Request-Context Binding

5. Verify `aud` matches the resource's own identifier.
6. `cnf.jwk` is REQUIRED. If it is absent, or if its JWK is missing `kty` or the members required for that key type (e.g., `crv` and `x` for OKP keys; `crv`, `x`, and `y` for EC keys; `n` and `e` for RSA keys), reject the token as structurally incomplete before attempting key decoding. If present but not parseable as a supported public key, reject it as invalid key material. Otherwise verify `cnf.jwk` matches the key used to sign the HTTP request.
7. Verify `sub` is present, and that `(iss, sub)` matches or establishes the resource's record for this person (#trust-posture-in-ps-asserted-access).

### Auth Token Response Verification {#auth-token-response-verification}

When an agent receives an auth token:

1. SHOULD verify the auth token JWT signature using the issuer's JWKS (the AS in four-party, or the PS in three-party). The agent trusts its PS, so signature verification is not required but is RECOMMENDED to detect errors early.
2. Verify `iss` matches the resource token's `aud` claim.
3. Verify `aud` matches the resource the agent intends to access.
4. Verify `cnf.jwk` matches the agent's own signing key.
5. Verify `sub` matches the value in the person token it presented to that resource.

### Upstream Token Verification {#upstream-token-verification}

When the PS or AS receives an `upstream_token` parameter in a call chaining request:

1. Perform Auth Token Verification (#auth-token-verification) on the upstream token.
2. Verify `iss` is a trusted issuer (a PS or AS whose auth token the recipient previously brokered or is authorized to extend).
3. Verify the `aud` in the upstream token equals the `iss` of the intermediary's agent token (presented in the `Signature-Key` header). This binding confirms the upstream token was issued to the resource now making the downstream request.
4. The PS evaluates its mission and governance policy based on the upstream token's claims and mission context. The resulting downstream authorization is not required to be a subset of the upstream scopes — see (#call-chaining).

# Agent Delegation {#agent-delegation}

Agent delegation covers the scenarios where more than one agent is involved in fulfilling a request: a resource that acts as an agent to call a downstream resource (call chaining), and an orchestrating agent that spawns sub-agents.

## Multi-Hop Resource Access {#multi-hop}

This section defines how resources act as agents (an instance of role collocation, see (#roles)) to access downstream resources on behalf of the original caller. In multi-hop scenarios, a resource that receives an authorized request needs to access another resource to fulfill that request. The resource acts as an agent — it has its own agent identity and signing key — and routes the downstream authorization to obtain an auth token for the downstream resource.

### Call Chaining {#call-chaining}

When a resource needs to access a downstream resource on behalf of the caller, it acts as an agent. It routes the downstream token request to the person server named by the `ps` claim of the upstream auth token it received. The `ps` claim in the calling agent's own agent token is NOT used for this routing — that names the intermediary's person server, not the person's.

The intermediary first obtains a person token for the downstream resource, presenting the upstream auth token as `upstream_token` (#person-token-endpoint). It then presents that person token at the downstream resource, receives a resource token, and sends it to the person server named by `ps`, along with its own agent token and the upstream auth token as `upstream_token`. The PS evaluates the downstream request against the mission context when the upstream token carries `mission_s256`.

In every case the intermediary signs the downstream token request with its **own** key, presenting its own agent token via the `Signature-Key` header (#http-message-signatures-profile). The `upstream_token` is a body parameter — it is neither presented via `Signature-Key` nor used as the signing key. It is the auth token previously issued to the intermediary (its `aud` is the intermediary and its `cnf` is the intermediary's key), and it serves only as proof of the upstream authorization that the recipient extends downstream. The signature the recipient verifies is therefore always the intermediary's, over its own key.

The recipient evaluates the downstream request per (#upstream-token-verification).

#### Directed Identifiers Across a Chain {#directed-sub-chaining}

The `sub` of an auth token is a directed identifier: a PS SHOULD issue a pairwise pseudonymous value per resource, so that two resources serving the same person cannot correlate them by comparing tokens (#auth-tokens, #directed-identifiers). Identity is the pair `(iss, sub)` — a `sub` minted by one issuer for one audience carries no meaning under a different issuer for a different audience.

A downstream issuer sees the upstream `sub` in the `upstream_token` it is handed. It MUST NOT carry that value forward:

1. An issuer MUST NOT copy a directed `sub` from an upstream token into a token it issues.
2. The `sub` it issues is the directed identifier for the person at the downstream resource, taken from the downstream resource token, which the resource copied from the person token the PS issued for that resource.

Because the intermediary obtains a person token for the downstream resource before calling it (#person-token-endpoint), the PS has already minted a downstream-directed identifier by the time the resource token exists. The chain never needs to carry a `sub` forward, and never leaves a downstream token without one.

Copying instead would fail in both directions at once. The value would be meaningless under the new issuer, so the downstream resource would either misidentify the person or key state to an identifier no one can resolve; and the same string appearing at two resources is exactly the correlation handle pairwise identifiers exist to prevent, handed to a party the user never consented to share it with.

Note that downstream authorization is not required to be a subset of the upstream scopes. A downstream resource may have capabilities that are orthogonal to the upstream resource — for example, a flight booking API that calls a payment processor needs the payment processor to charge a card, an operation the user and original agent could never perform directly. The downstream resource's scope is constrained by its own AS policy and the PS's evaluation of the mission context, not by the upstream token's scope. The PS provides the governance constraint — it evaluates each hop independently and can deny requests that fall outside the mission or the user's intent.

Because the resource acts as an agent, it MUST have its own agent identity — it MUST publish agent metadata at `/.well-known/aauth-agent.json` so that downstream resources and ASes can verify its identity.

### Interaction Chaining {#interaction-chaining}

When the PS or AS requires user interaction for the downstream access, it returns a `202` with `requirement=interaction`. Resource 1 chains the interaction back to the original agent by returning its own `202`.

When a resource acting as an agent receives a `202 Accepted` response with `AAuth-Requirement: requirement=interaction`, and the resource needs to propagate this interaction requirement to its caller, it MUST return a `202 Accepted` response to the original agent with its own `AAuth-Requirement` header containing `requirement=interaction` and its own interaction code. The resource MUST provide its own `Location` URL for the original agent to poll. When the user completes interaction and the resource obtains the downstream auth token, the resource completes the original request and returns the result at its pending URL.

## Sub-Agents {#sub-agents}

Agent platforms increasingly spawn short-lived sub-agents — workers or tool-specific helpers — under an orchestrating parent agent. AAuth represents a sub-agent as an agent whose agent token carries a `parent_agent` claim identifying its parent. The user consents to the parent; sub-agents operate under that consent without per-spawn re-prompting, while remaining individually identifiable for audit and revocation.

### Sub-Agent Identity

A sub-agent has its own agent identity — its own `aauth:local@domain` identifier and signing key, issued by the agent provider, exactly like a top-level agent. Two things distinguish it:

- **`parent_agent` claim**: the sub-agent's agent token includes `parent_agent` set to the parent agent's identifier. Its presence is the authoritative marker of sub-agent status.
- **Local-part naming**: the sub-agent's `local` part MUST be the parent's `local` part followed by `+` and a non-empty discriminator (#agent-identifiers) — for example `aauth:planner.7f3c+search1@vendor.example`. For protocol decisions, verifiers rely on `parent_agent`, not on parsing the local part; the naming is for operational readability (e.g., logs).

```json
{
  "iss": "https://vendor.example",
  "dwk": "aauth-agent.json",
  "sub": "aauth:planner.7f3c+search1@vendor.example",
  "cnf": { "jwk": { "kty": "OKP", "crv": "Ed25519",
                    "x": "...", "alg": "Ed25519" } },
  "ps":  "https://ps.example",
  "parent_agent": "aauth:planner.7f3c@vendor.example"
}
```

Acquisition of a sub-agent token from the agent provider is platform-dependent and is described in [@?I-D.hardt-aauth-bootstrap], parallel to top-level agent token acquisition.

### Single-Level Depth

Delegation is at most one level deep: a top-level agent may have sub-agents, but a sub-agent MUST NOT have sub-agents of its own. Two rules enforce this:

- A PS MUST reject a token request signed by an agent whose agent token has a `parent_agent` claim — a sub-agent cannot request authorization on its own behalf or on behalf of a further sub-agent.
- An agent provider MUST NOT issue a sub-agent token whose parent (`parent_agent`) is itself a sub-agent.

For genuinely deeper workflows, AAuth already provides chained top-level agents (#call-chaining): each hop is an independent principal with its own grant, rather than recursive sub-agent spawning.

### Parent-Mediated Authorization

A sub-agent MUST NOT call the PS directly. Instead, the parent obtains auth tokens on the sub-agent's behalf:

1. The parent obtains a person token for the sub-agent by POSTing to the PS's `person_token_endpoint` with `subagent_token` (#person-token-endpoint); the issued token's `cnf` is the sub-agent's key. It passes the person token to the sub-agent out of band (for example, via IPC).
2. The sub-agent presents that person token at the resource and obtains a resource token bound to its own key (#resource-tokens), exactly as a top-level agent would. It passes the resource token back to its parent.
3. The parent POSTs to the PS's `auth_token_endpoint`, signing the request with its own key and presenting its own agent token via the `Signature-Key` header. The request body includes `resource_token` (the sub-agent's resource token) and `subagent_token` (the sub-agent's agent token).
4. The PS processes this as an authorization request from the parent (#ps-token-endpoint):
   - It verifies the HTTP Message Signature against the parent's `cnf.jwk`.
   - It verifies the `subagent_token` (#agent-token-verification) and that its `parent_agent` names the parent — the agent that signed the request.
   - It verifies the `resource_token` is bound to the sub-agent's key: `agent_jkt` matches the `subagent_token`'s `cnf.jwk`, not the signing key (#resource-token-verification).
   - It evaluates the parent's grant for the requested scope, exactly as for a direct request from the parent. If the user has already consented, the response is immediate; otherwise consent surfaces for the parent as usual.
5. On success the issuer — the PS in three-party, or the AS in four-party — issues an auth token bound to the sub-agent's key (`cnf` = the sub-agent's `jwk`). In four-party, the PS federates by passing the parent as `agent_token` and the sub-agent as `subagent_token` to the AS (#as-token-endpoint), so the AS records the parent authoritatively from those tokens. The parent passes the auth token to the sub-agent, which presents it to the resource signing with its own key.

The sub-agent relationship is recorded by the PS, which issued both tokens and holds the `parent_agent` binding. It does not appear in the tokens the resource sees.

Because every sub-agent authorization passes through the parent, the parent retains control — it can refuse, attenuate, or rate-limit — and revocation propagates naturally: revoking the parent's grant causes the next sub-agent authorization to fail, while existing auth tokens expire normally (≤1 hour).

# Third-Party Login {#third-party-login}

A third party — such as a PS, enterprise portal, app marketplace, or partner site — can direct a user to an agent's or resource's `login_endpoint` to initiate authentication. The agent or resource creates a resource token and sends it to the PS's token endpoint, obtaining an auth token with user identity.

This enables use cases where the user's journey starts outside the agent or resource — for example, an enterprise portal launching an agent for a specific user, an app marketplace connecting a user to a new service, or a PS dashboard directing a user to an agent.

## Login Endpoint

Agents and resources MAY publish a `login_endpoint` in their metadata. The `login_endpoint` accepts the following query parameters:

- `ps` (REQUIRED): The PS URL to authenticate with. The agent or resource MUST verify this is a valid PS by fetching its metadata at `{ps}/.well-known/aauth-person.json` (#ps-metadata).
- `login_hint` (OPTIONAL): Hint about who to authorize, per [@!OpenID.Core] Section 3.1.2.1.
- `domain_hint` (OPTIONAL): Domain hint, per OpenID Connect Enterprise Extensions 1.0 [@OpenID.Enterprise].
- `tenant` (OPTIONAL): Tenant identifier, per OpenID Connect Enterprise Extensions 1.0 [@OpenID.Enterprise].
- `start_path` (OPTIONAL): Path on the agent's or resource's origin where the user should be directed after login completes. The recipient MUST validate that `start_path` is a relative path on its own origin.

**Example login URL:**
```
https://agent.example/login
    ?ps=https://ps.example
    &tenant=corp
    &login_hint=user@corp.example
    &start_path=/projects/tokyo-trip
```

## Login Flow

Upon receiving a request at its `login_endpoint`, the agent or resource:

1. Validates the `ps` parameter by fetching the PS's metadata.
2. Creates a resource token with `aud` = PS URL, binding the request to its own identity.
3. POSTs to the PS's `auth_token_endpoint` with the resource token and any provided `login_hint`, `domain_hint`, or `tenant` parameters.
4. Proceeds with the standard deferred response flow (#deferred-responses) — directing the user to the PS's interaction endpoint with the interaction code.
5. After obtaining the auth token, redirects the user to `start_path` if provided, or to a default landing page.

If the user is already authenticated at the PS, the interaction step resolves near-instantly — the PS recognizes the user from its own session. If not, the user completes a normal authentication and consent flow.

~~~ ascii-art
User         Third Party     Agent/Resource                  PS
  |               |               |                           |
  |  select       |               |                           |
  |-------------->|               |                           |
  |               |               |                           |
  |  redirect to login_endpoint   |                           |
  |  (ps, tenant, start_path)     |                           |
  |<--------------|               |                           |
  |               |               |                           |
  |  login_endpoint               |                           |
  |------------------------------>|                           |
  |               |               |                           |
  |               |               |  POST auth_token_endpoint |
  |               |               |  resource_token,          |
  |               |               |  login_hint, tenant       |
  |               |               |-------------------------->|
  |               |               |                           |
  |               |               |  202 Accepted             |
  |               |               |  requirement=interaction  |
  |               |               |  url, code                |
  |               |               |<--------------------------|
  |               |               |                           |
  |  direct to {url}?code={code}  |                           |
  |<------------------------------|                           |
  |               |               |                           |
  |  authenticate at PS           |                           |
  |------------------------------------------------------>---|
  |               |               |                           |
  |               |               |  GET pending URL          |
  |               |               |-------------------------->|
  |               |               |  200 OK, auth_token       |
  |               |               |<--------------------------|
  |               |               |                           |
  |  redirect to start_path       |                           |
  |<------------------------------|                           |
~~~
Figure: Third-Party Login Flow {#fig-third-party-login}

The third party does not need to be the PS. Any party that knows the agent's or resource's `login_endpoint` (from metadata) can initiate the flow. The agent or resource treats the redirect as untrusted input — it verifies the PS through metadata discovery and initiates a signed flow.

## Security Considerations for Third-Party Login

- The `login_endpoint` does not carry any tokens, codes, or pre-authorized state. The agent or resource initiates a standard signed flow with the PS, which independently authenticates the user.
- The `start_path` parameter MUST be validated as a relative path on the recipient's own origin to prevent open redirect attacks.
- The `ps` parameter is untrusted input. The agent or resource MUST discover and verify the PS via its well-known metadata before proceeding.

# Protocol Primitives {#protocol-primitives}

This section defines the common mechanisms used across all AAuth endpoints: requirement responses, capabilities, deferred responses, error responses, scopes, token revocation, HTTP message signatures, key discovery, identifiers, and metadata documents.

## AAuth-Capabilities Request Header {#aauth-capabilities}

Agents use the `AAuth-Capabilities` request header to declare which protocol capabilities they can handle. This allows resources and PSes to tailor their responses — for example, a resource that sees `interaction` in the capabilities knows it can send `requirement=interaction`, whereas a resource that does not see `interaction` knows it must use an alternative path (such as issuing a resource token for three-party mode).

The `AAuth-Capabilities` header field is a List ([@!RFC8941], Section 3.1) of Tokens.

```http
AAuth-Capabilities: interaction, clarification, payment
```

This specification defines the following capability values:

| Value | Meaning |
|-------|---------|
| `interaction` | Agent can get a user to a URL — either directly (user is present) or via its PS's interaction endpoint |
| `clarification` | Agent can engage in back-and-forth clarification chat |
| `payment` | Agent can handle `402` payment flows — either directly or via its PS's interaction endpoint |

The agent determines its capabilities by combining what it can do directly with what its PS can do on its behalf. When the agent has a PS and has created a mission, the mission approval response MAY include a `capabilities` array listing what the PS can handle for this user/session (#mission-approval). When present, the agent unions those capabilities with its own to produce the `AAuth-Capabilities` header value.

Agents SHOULD include the `AAuth-Capabilities` header on signed requests to resources. The header is not used on requests to PS endpoints: on the PS token endpoint the agent conveys capabilities via the `capabilities` request parameter (#ps-token-endpoint), and within a mission the PS also has the capabilities captured at mission approval (#mission-approval). Recipients MUST ignore unrecognized capability values. When the header is absent, recipients MUST NOT assume any capabilities — the agent may not support interaction, clarification, or payment flows.

Capability values are Tokens and currently carry no parameters. A future capability value MAY define parameters; recipients MUST ignore parameters they do not recognize on a capability item rather than rejecting the header.

This is AAuth's general posture: recipients ignore what they do not recognize, and no document carries a version or schema identifier that a recipient must understand before processing it. Where a future extension defines a member that changes the meaning of what surrounds it, that extension states the must-understand requirement and the behaviour on failure, rather than relying on a general mechanism.

## Scopes {#scopes}

Scopes define what an agent is authorized to do at a resource. AAuth uses two categories of scope values:

- **Resource scopes**: Resource-specific authorization grants (e.g., `data.read`, `data.write`, `data.delete`). Each resource defines its own scope values and publishes human-readable descriptions in its metadata (`scope_descriptions`). Resources that already define OAuth scopes SHOULD use the same scope values in AAuth.
- **Identity scopes**: Requests for user identity claims following [@!OpenID.Core] (e.g., `openid`, `profile`, `email`, `address`, `phone`). When identity scopes are present, the auth token includes the corresponding identity claims. Enterprise extensions include the `tenant` claim from [@OpenID.Enterprise] and the `groups` and `roles` claims from [@!RFC9068] (originally defined by SCIM [@RFC7643]).

A resource token MUST only include resource scopes that the resource has defined in its `scope_descriptions` metadata, and identity scopes that the PS has declared in its `scopes_supported` metadata. This ensures all parties can interpret and present the requested scopes.

Scopes appear in three places in the protocol:

1. **Resource token** (`scope`): The scope the resource is willing to grant, as determined by the resource based on the agent's request at the authorization endpoint.
2. **Auth token** (`scope`): The scope actually granted. The auth token's scope MUST NOT be broader than the resource token's scope.
3. **Authorization endpoint request** (`scope`): The scope the agent is requesting from the resource.

The PS evaluates requested scopes against mission context (if present) and user consent. The AS evaluates scopes against resource policy. Either party may narrow the granted scope.

## Account Binding {#account-binding}

A resource may hold more than one account for the same person — an AAuth-to-OAuth proxy where a user has connected several accounts at the upstream service, a SaaS product where someone belongs to several workspaces. Scope says what the agent may do; it does not say which of those accounts it may do it to.

The OPTIONAL `account` parameter of the authorization endpoint request (#authorization-endpoint-request) binds an authorization to one of them. Its value is a string from the resource's own account namespace — an email address, a workspace identifier, a tenant id, whatever the resource already uses. This specification gives it no structure and no meaning; only the resource interprets it.

When the request carried `account`, the resource echoes it as the `account` claim of the resource token, the PS or AS copies it into the auth token, and the resource enforces per-account access directly from the token it receives. Different accounts yield different auth tokens, so an auth token for one account grants nothing at another, and the audit trail records which account each authorization covered.

The parameter selects; it does not hint. It is not `login_hint` ([@!OpenID.Core], Section 3.1.2.1), which is a hint about who to authenticate at the party receiving it. Nobody is being authenticated here — the account is already connected at the resource — and the value has to survive into the issued tokens as a claim rather than being consumed during a login. Overloading `login_hint` would also conflate the person logging in at their PS with the account being acted on at the resource, which are different things and may belong to different namespaces entirely.

## Requirement Responses {#requirement-responses}

Servers use the `AAuth-Requirement` response header to indicate protocol-level requirements to agents. The header MAY be sent with `401 Unauthorized` or `202 Accepted` responses. A `401` response indicates that authorization is required. A `202` response indicates that the request is pending and additional action is required — user interaction (`requirement=interaction`), third-party approval (`requirement=approval`), a clarification answer (`requirement=clarification`), or identity claims (`requirement=claims`).

`AAuth-Requirement` and `WWW-Authenticate` are independent header fields; a response MAY include both. A client that understands AAuth processes `AAuth-Requirement`; a legacy client processes `WWW-Authenticate`. Neither header's presence invalidates the other. AAuth never conveys its own requirements via `WWW-Authenticate`; a resource's existing `WWW-Authenticate` challenges (e.g., `Bearer`, `Payment`) therefore remain fully available alongside `AAuth-Requirement`.

The header MAY also be sent with `402 Payment Required` when a server requires both authorization and payment. The `AAuth-Requirement` conveys the authorization requirement; the payment requirement is conveyed by a separate mechanism such as x402 [@x402] or the Machine Payment Protocol (MPP) ([@I-D.ryan-httpauth-payment]).

### AAuth-Requirement Header Structure

The `AAuth-Requirement` header field is a Dictionary ([@!RFC8941], Section 3.2). It MUST contain the following member:

- `requirement`: A Token ([@!RFC8941], Section 3.3.4) indicating the requirement type.

Requirement-specific data are conveyed as parameters on the `requirement` member (for example, `resource-token`, `url`, `code`). Recipients MUST ignore unknown parameters.

Example:

```http
AAuth-Requirement: requirement=auth-token; resource-token="eyJ..."
```

### Requirement Values

The `requirement` value is an extension point. This document defines the following values:

| Value | Status Code | Meaning | Resource | PS | AS |
|-------|-------------|---------|:--------:|:--:|:--:|
| `agent-token` | `401` | AAuth agent token required for identity-only access | Y | | |
| `person-token` | `401` | Person token required to identify the person | Y | | |
| `auth-token` | `401` | Auth token required for resource access | Y | | |
| `interaction` | `202` | User action required at an interaction endpoint | Y | Y | Y |
| `approval` | `202` | Approval pending, poll for result | Y | Y | Y |
| `clarification` | `202` | Question posed to the recipient | Y | Y | Y |
| `claims` | `202` | Identity claims required | | | Y |

The `agent-token` requirement is defined in (#requirement-agent-token); the `person-token` requirement in (#requirement-person-token); the `auth-token` requirement in (#requirement-auth-token); the `interaction` and `approval` requirements are defined in this section;  `clarification` in (#requirement-clarification); and `claims` in (#requirement-claims).

An agent that does not recognize the `requirement` value MUST NOT treat the response as satisfiable. It surfaces the unsupported requirement to the caller as an error. For a `202` response with an unrecognized `requirement`, the agent MAY continue polling the `Location` URL in case a later response carries a requirement value it does understand, rather than immediately abandoning the request.

### Interaction Required

When a server requires user action — such as authentication, consent, payment approval, or any decision requiring a human in the loop — it returns a `202 Accepted` response:

```http
HTTP/1.1 202 Accepted
AAuth-Requirement:
    requirement=interaction;
    url="https://example.com/interact";
    code="A1B2-C3D4"
Location: /pending/f7a3b9c
Retry-After: 0
```

The `AAuth-Requirement` header MUST include the following parameters:

- `url` (String): The interaction URL where the user completes the required action. MUST use the `https` scheme and MUST NOT contain query or fragment components.
- `code` (String): An interaction code that links the agent's pending request to the user's session at the interaction URL. Generated and compared per (#interaction-code-format).

The response MUST also include:

- `Location`: A URL the agent polls (with GET) for a terminal response.
- `Retry-After`: Recommended polling interval in seconds.

#### Interaction Code Format {#interaction-code-format}

The `code` is a Structured Field String ([@!RFC8941], Section 3.3.3). The user reads it out of band — the agent displays it (or renders it in a QR code) and the user visually compares it against the code shown on the interaction page — so it MUST be both unguessable and unambiguous to a human. Servers and agents MUST follow these rules.

**Alphabet.** The code MUST be generated from Crockford base32 ([@?I-D.crockford-davis-base32-for-humans]) — the symbol set `0123456789ABCDEFGHJKMNPQRSTVWXYZ`, which omits the visually ambiguous letters `I`, `L`, `O`, and `U`. Every symbol is URL-safe, so the code requires no escaping when appended as `{url}?code={code}`. Servers MUST NOT emit codes containing characters outside this set (other than the optional grouping hyphen below).

**Entropy and length.** A code MUST carry at least 40 bits of entropy — at least 8 Crockford base32 symbols, drawn from a cryptographically secure random source. Servers MAY use longer codes for higher-value interactions.

**Hyphens.** A server MAY insert hyphen (`-`) characters into the displayed code purely for visual grouping (for example, `A1B2-C3D4`). The hyphen is presentational only: it carries no entropy and is not part of the code's value. Before comparison, both the server and any party validating the code MUST strip all hyphens.

**Case.** Comparison MUST be case-insensitive. A server MUST accept the code regardless of the case the user enters, and on input MUST fold the Crockford decode aliases (`I`/`L` → `1`, `O` → `0`) before comparison so that a user who transcribes an ambiguous glyph still matches.

**Correlation only.** The code is a correlation identifier — it ties the user's browser session to the pending interaction so the server can look up the correct request. It is NOT an authorization credential. The person's approve/deny decision MUST be recorded via an authenticated channel at the PS; how the PS authenticates the person is outside the scope of this specification. Because the agent relays the interaction URL and code to the user, the code is visible to the agent — the code alone MUST NOT authorize the decision.

**Single use.** A code MUST be single-use. Once the user arrives at the interaction URL with a valid code and the code is consumed, the server MUST reject any later presentation of the same code, returning `invalid_code` (#polling-error-codes).

**Rate-limiting.** Because the code guards access to the interaction page, the server MUST rate-limit code-validation attempts at the interaction URL. After a small number of failed attempts the server MUST treat the pending interaction as terminally failed and return `invalid_code` (#polling-error-codes) on subsequent attempts, bounding the brute-force window to far fewer guesses than the code's entropy would otherwise allow.

**Lifetime.** A code MUST expire no later than the pending interaction it is bound to (#deferred-responses). Once the pending request has expired, presenting the code MUST fail with `expired` (#polling-error-codes); the agent MAY initiate a fresh request to obtain a new code.

#### Relaying Through the Person Server {#interaction-relay}

When the agent has a PS, it SHOULD relay the interaction to the PS's `interaction_endpoint` (#interaction-endpoint) before directing the user itself. The PS may have a lower-friction channel to the user — an active web session, a registered mobile app — than the agent opening a browser or rendering a QR code.

To relay, the agent POSTs `{ "type": "interaction", "url": "...", "code": "..." }` to the PS's `interaction_endpoint` (#interaction-endpoint). The PS attempts to reach the user through its own channels and responds:

- **PS can relay**: it returns a `202` deferred response, and the agent polls for completion as described in (#interaction-endpoint).
- **PS cannot relay**: it returns `interaction_unavailable` (#interaction-endpoint-errors). This is non-terminal — the agent falls back to directing the user itself.

The agent directs the user itself — using the methods below — when it has no PS, or when the PS returns `interaction_unavailable`.

To direct the user, the agent constructs a user-facing URL by appending the code as a query parameter: `{url}?code={code}`. The agent then directs the user to this URL using one of:

- **Browser redirect**: The agent opens the URL in the user's browser.
- **Display code**: The agent displays the `url` and `code` for the user to enter manually. The agent MAY also render the constructed URL as a QR code for the user to scan with their phone.

After directing the user, the agent polls the `Location` URL with GET requests, respecting the `Retry-After` interval. A `202` response means the request is still pending. A non-`202` response is terminal — `200` indicates success, `403` indicates denial, and `408` indicates timeout.

~~~ ascii-art
Agent                        User                         Server
  |                            |                             |
  |  202 Accepted                                            |
  |  AAuth-Requirement:                                      |
  |    requirement=interaction;                              |
  |    url="..."; code="..."                                 |
  |  Location: /pending/...                                  |
  |<---------------------------------------------------------|
  |                            |                             |
  |  open {url}?code={code}    |                             |
  |  (or display code / QR)    |                             |
  |--------------------------->|                             |
  |                            |                             |
  |                            |  {url}?code={code}          |
  |                            |---------------------------->|
  |                            |                             |
  |                            |  user completes action      |
  |                            |<----------------------------|
  |                            |                             |
  |  GET /pending/...                                        |
  |--------------------------------------------------------->|
  |                            |                             |
  |  200 OK                                                  |
  |<---------------------------------------------------------|
~~~

**Use cases:** User login, consent, payment confirmation, document review, CAPTCHA, any workflow requiring human action.

### Approval Pending

When a server is obtaining approval from another party without requiring the agent to direct a user — for example, via push notification, email, or administrator review:

```http
HTTP/1.1 202 Accepted
AAuth-Requirement: requirement=approval
Location: /pending/f7a3b9c
Retry-After: 30
```

The response MUST include `Location` and `Retry-After`. The agent polls the `Location` URL with GET requests until a terminal response is received. No user action is required at the agent side. The same terminal response codes apply as for `interaction`.

**Use cases:** Administrator approval, resource owner consent, compliance review, direct user authorization via established communication channel.

## Deferred Responses {#deferred-responses}

Any endpoint in AAuth — whether a PS token endpoint, AS token endpoint, or resource endpoint — MAY return a `202 Accepted` response ([@!RFC9110]) when it cannot immediately resolve a request. This is a first-class protocol primitive, not a special case. Agents MUST handle `202` responses regardless of the nature of the original request.

### Initial Request

The agent makes a request and signals its willingness to wait using the `Prefer` header ([@!RFC7240]):

```http
POST /token HTTP/1.1
Host: auth.example
Content-Type: application/json
Prefer: wait=45
Signature-Input: sig=("@method" "@authority"
    "@path" "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "resource_token": "eyJhbGc..."
}
```

### Pending Response

When the server cannot resolve the request within the wait period:

```http
HTTP/1.1 202 Accepted
Location: /pending/f7a3b9c
Retry-After: 0
Cache-Control: no-store
Content-Type: application/json

{
  "status": "pending"
}
```

Headers:

- `Location` (REQUIRED): The pending URL. The `Location` URL MUST be on the same origin as the responding server.
- `Retry-After` (REQUIRED): Seconds the agent SHOULD wait before polling. `0` means retry immediately.
- `Cache-Control: no-store` (REQUIRED): Prevents caching of pending responses.
- `AAuth-Requirement` (OPTIONAL): Present when user interaction or approval is required. The `url` and `code` parameters are defined in (#requirement-responses).

Body fields:

- `status` (REQUIRED): `"pending"` while the request is waiting. `"interacting"` when the user has arrived at the interaction endpoint. Agents MUST treat unrecognized `status` values as `"pending"` and continue polling.

Additional body fields may be present depending on the `AAuth-Requirement` value — for example, `clarification` and `timeout` with `requirement=clarification`, or `required_claims` with `requirement=claims`. See the specific requirement definitions for details.

### Polling with GET

After receiving a `202`, the agent switches to `GET` for all subsequent requests to the `Location` URL. The agent does NOT resend the original request body. **Exception**: During clarification chat, the agent uses `POST` to deliver a clarification response.

The agent MUST respect `Retry-After` values. If a `Retry-After` header is not present, the default polling interval is 5 seconds. If the server responds with `429 Too Many Requests`, the agent MUST increase its polling interval by 5 seconds (linear backoff, following the pattern in [@RFC8628], Section 3.5). The `Prefer: wait=N` header ([@!RFC7240]) MAY be included on polling requests to signal the agent's willingness to wait for a long-poll response.

### Deferred Response State Machine

The following state machine applies to any AAuth endpoint that returns a `202 Accepted` response — including PS token endpoints, AS token endpoints, and resource endpoints during call chaining. A non-`202` response terminates polling.

```
Initial request (with Prefer: wait=N)
    |
    +-- 200 --> done — process response body
    +-- 202 --> note Location URL, check requirement/code
    +-- 400 --> invalid request — check error field, fix and retry
    +-- 401 --> invalid signature — check credentials;
    |           obtain auth token if resource challenge
    +-- 402 --> payment required (settle payment, poll Location)
    +-- 500 --> server error — start over
    +-- 503 --> back off per Retry-After, retry
               |
               GET Location (with Prefer: wait=N)
               |
               +-- 200 --> done — process response body
               +-- 202 --> continue polling (check status/clarification)
               |           status=interacting → stop prompting user
               +-- 403 --> denied or abandoned — surface to user
               +-- 408 --> expired — MAY initiate a fresh request
               +-- 410 --> gone — MUST NOT retry
               +-- 429 --> slow down — increase interval by 5s
               +-- 500 --> server error — start over
               +-- 503 --> temporarily unavailable
                           back off per Retry-After
```

## Error Responses {#error-responses}

### Authentication Errors

A `401` response from any AAuth endpoint uses the `Signature-Error` header as defined in ([@!I-D.hardt-httpbis-signature-key]). The header, not the response body, is the machine-readable carrier; agents MUST NOT depend on the body for signature error handling.

A server returning `unsupported_scheme` SHOULD include `Accept-Signature-Scheme`, and one returning `unsupported_algorithm` SHOULD include `Accept-Signature-Alg` (#verification). The error names what went wrong; the header names what would succeed. Because AAuth fixes the scheme (#keying-material) and requires `Ed25519` support of every agent and resource (#signature-algorithms), a conformant agent does not reach either error — the headers exist so that an agent preferring another algorithm, or a client arriving from outside AAuth, can recover in one round trip rather than by trial.

### Error Response Format {#error-response-format}

Error response bodies use the HTTP problem details format ([@!RFC9457]) with `Content-Type: application/problem+json`. The body is a JSON object with the following members:

- `error` (REQUIRED): String. A single error code, as defined by the endpoint returning the error. This is an RFC 9457 extension member; receivers MUST determine how to proceed from this member.
- `detail` (OPTIONAL): String. A human-readable explanation specific to this occurrence of the error.

Other RFC 9457 members (`type`, `title`, `status`, `instance`) MAY be present with their RFC 9457 semantics. AAuth does not define problem type URIs; receivers MUST NOT rely on `type` to identify AAuth errors.

### Token Endpoint Error Codes {#token-endpoint-error-codes}

| Error | Status | Meaning |
|-------|--------|---------|
| `invalid_request` | 400 | Malformed JSON, missing required fields |
| `invalid_agent_token` | 400 | Agent token malformed or signature verification failed |
| `expired_agent_token` | 400 | Agent token has expired |
| `invalid_resource_token` | 400 | Resource token malformed or signature verification failed |
| `expired_resource_token` | 400 | Resource token has expired |
| `unknown_person_token` | 400 | The person token named by the resource token's `presented_jti` is not among those the PS retains (#resource-token-verification) |
| `user_unreachable` | 403 | Terminal. The PS has no channel to reach the user and the agent did not declare the `interaction` capability, so the user cannot be reached at all. The non-terminal "user action is needed" case uses a `202` with `requirement=interaction` (#requirement-responses), not this error. |
| `server_error` | 500 | Internal error |

Example — the resource token presented to the token endpoint has expired:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/problem+json

{
  "error": "expired_resource_token",
  "detail": "The resource token expired; obtain a new
    resource token from the resource and retry."
}
```

### Polling Error Codes {#polling-error-codes}

| Error | Status | Meaning |
|-------|--------|---------|
| `denied` | 403 | User or approver explicitly denied the request |
| `abandoned` | 403 | Interaction code was used but user did not complete |
| `expired` | 408 | Timed out |
| `invalid_code` | 410 | Interaction code not recognized or already consumed |
| `slow_down` | 429 | Polling too frequently — increase interval by 5 seconds |
| `server_error` | 500 | Internal error |

Example — the user denied the pending request:

```http
HTTP/1.1 403 Forbidden
Content-Type: application/problem+json

{
  "error": "denied",
  "detail": "The user declined the request."
}
```

## Token Revocation {#token-revocation}

Any AAuth server that issues tokens MAY provide a revocation endpoint. The endpoint accepts a signed POST identifying the token to revoke by the pair `(iss, jti)`. Both members are REQUIRED. The server identifies the token from that pair and its own records; no token type is needed, since `(iss, jti)` is unique.

A `jti` is unique only within the namespace of the issuer that minted it. A revocation endpoint receives tokens from many issuers — a resource holds auth tokens from every PS and AS its callers use — so a `jti` alone does not identify a token unambiguously and invites cross-issuer collision, revoking the wrong token or silently failing to revoke the right one. Recipients maintaining revocation state MUST key it by `(iss, jti)`.

**Request:**

```http
POST /revoke HTTP/1.1
Host: ps.example
Content-Type: application/json
Signature-Input: sig=("@method" "@authority"
    "@path" "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "iss": "https://ps.example",
  "jti": "unique-token-identifier"
}
```

**Response:** `200 OK` if the token was revoked or was already invalid. `404` if the `(iss, jti)` pair is not recognized.

Revocation provides real-time termination of access. The PS or AS calls the revocation endpoint of the resource that a token was issued for, passing the `iss` and `jti` of the auth token to revoke. The following revocation scenarios are supported:

- **PS revokes an auth token it issued** (three-party): The PS calls the resource's revocation endpoint with the auth token's `iss` and `jti`.
- **PS revokes an auth token it provided** (four-party): The PS calls the resource's revocation endpoint with the auth token's `iss` and `jti`. The PS MAY also notify the AS.
- **AS revokes an auth token it issued**: The AS calls the resource's revocation endpoint with the auth token's `iss` and `jti`.
- **PS revokes a mission**: The PS marks the mission as revoked. All subsequent token requests referencing that mission's `s256` are denied. The PS SHOULD revoke outstanding auth tokens issued under the mission.
- **Agent provider revokes an agent token it issued**: On learning that an agent can no longer be trusted, the agent provider calls the PS's revocation endpoint with the agent token's `iss` and `jti`. The PS MUST deny subsequent requests presenting that agent token, and SHOULD revoke the auth tokens it issued or provided for that agent by calling the revocation endpoint of each resource those tokens were issued for. Under identity-based access (#requirement-agent-token) the agent presents its agent token to the resource directly, and the agent provider has no record of which resources those are; a resource accepting agent tokens SHOULD therefore provide a revocation endpoint, and where none is reached that access is bounded by the agent token lifetime alone.
- **Agent provider stops issuing agent tokens**: The agent provider decides not to issue new agent tokens to the agent. Existing agent tokens expire naturally. This is part of the regular token lifecycle — all tokens have limited lifetimes and require periodic re-issuance, which provides a natural policy re-evaluation point.

Revocation endpoints are advertised in server metadata as `revocation_endpoint`. Recipients of revocation requests MUST verify the caller's identity via HTTP Message Signatures and MUST only accept revocation from the issuer of the token being revoked or from a trusted PS.

Verifying an auth token does not ask the issuer about that token. A resource fetches the issuer's JWKS to obtain the verification key and caches it across many tokens, then checks the signature and claims locally; nothing in that path reports that a particular token has been revoked. A resource therefore learns of a revocation only when one reaches its revocation endpoint, and a party that no revocation request reaches is bounded by token lifetime alone — at most one hour for an auth token (#auth-tokens), five minutes for a resource token (#resource-tokens). Revocation shortens exposure; it does not eliminate it, and deployments requiring immediate termination should issue shorter-lived tokens rather than relying on revocation reaching every holder.

Auth tokens are short-lived (maximum 1 hour) and proof-of-possession (useless without the bound signing key). All AAuth tokens have limited lifetimes — agent tokens, resource tokens, and auth tokens all expire and require re-issuance. Each re-issuance is a policy evaluation point where the issuer can deny renewal. This natural expiration cycle, combined with real-time revocation, provides layered access control.

## HTTP Message Signatures Profile {#http-message-signatures-profile}

This section profiles HTTP Message Signatures ([@!RFC9421]) for use with AAuth. Signing requirements (what the agent does) and verification requirements (what the server does) are specified separately.

### Signature Algorithms {#signature-algorithms}

Agents and resources MUST support `Ed25519` ([@!RFC8032]). Agents and resources SHOULD support `ES256`. Algorithm identifiers are values from the IANA "JSON Web Signature and Encryption Algorithms" registry [@!IANA.JOSE.Algorithms], and the `alg` member of the JWK ([@!RFC7517]) carries the identifier.

Every key AAuth conveys or references is subject to the Algorithm Determination rules of the HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]). In particular:

- The `alg` member MUST be present and MUST be a fully-specified identifier — one that determines the signature operation completely, including curve and hash where applicable. A verifier MUST reject a key whose `alg` is absent.
- The polymorphic `EdDSA` identifier MUST NOT be used. Use `Ed25519` (or `Ed448`), which [@!RFC9864] registered as its fully-specified replacements when it deprecated `EdDSA`.
- `none`, any algorithm whose JOSE Implementation Requirement is `Prohibited`, and symmetric algorithms (the `oct` key type and the `HS256`, `HS384`, and `HS512` identifiers) MUST NOT be used.
- A verifier MUST reject a key whose `kty` or, where present, `crv` disagrees with its `alg`.

Naming `Ed25519` rather than `EdDSA` with the curve pinned separately in prose is what makes the requirement testable: a verifier reading only the `alg` value cannot distinguish Ed25519 from Ed448, and [@!RFC9864] deprecates exactly that pattern. `ES256` is likewise already fully specified, and its use is RECOMMENDED where a platform's keys are ECDSA on P-256 — notably hardware-backed keys on devices whose secure enclave does not offer Ed25519.

Post-quantum algorithms need no special treatment here: the ML-DSA identifiers registered by [@!RFC9964] are fully specified and are used directly as the `alg` value.

### Keying Material {#keying-material}

The signing key is conveyed in the `Signature-Key` header ([@!I-D.hardt-httpbis-signature-key]). Because every AAuth agent holds an agent token (#agent-tokens), AAuth uses the **identity** `scheme=jwt`: the agent presents a token carrying its public key in a `cnf` claim, and the key is taken from there. Agents MUST use `scheme=jwt`; agents MUST NOT use `scheme=jwks_uri` or `scheme=hwk` for AAuth resource, PS, or AS requests.

Which token the agent presents depends on what the recipient needs to know. All three carry the same key in `cnf`, so signature verification is identical in each case.

| Token | Presented to | Asserts |
|---|---|---|
| Agent token (#agent-tokens) | the PS and the AP always; a resource for agent identity access | which agent |
| Person token (#person-tokens) | a resource, at its authorization endpoint | which person |
| Auth token (#auth-tokens) | a resource, once it has authorized the agent | what is authorized |

The Signature-Key specification also defines `pseudonym` schemes (`scheme=hwk` for a bare inline public key, `scheme=jkt-jwt` for hardware-key delegation). AAuth does not use bare `hwk` access — the agent token is the minimum AAuth credential. `scheme=jkt-jwt` is used only in the agent provider's key-refresh ceremony (see [@?I-D.hardt-aauth-bootstrap]), not for protocol access to resources, PSes, or ASes.

See the Signature-Key specification ([@!I-D.hardt-httpbis-signature-key]) for scheme definitions, key discovery, and verification procedures.

### Signing (Agent)

The agent creates an HTTP Message Signature ([@!RFC9421]) on each request, including the following headers:

- `Signature-Key`: Public key or key reference for signature verification
- `Signature-Input`: Signature metadata including covered components
- `Signature`: The HTTP message signature

#### Covered Components {#covered-components}

The signature MUST cover the following derived components and header fields:

- `@method`: The HTTP request method ([@!RFC9421], Section 2.2.1)
- `@authority`: The target host ([@!RFC9421], Section 2.2.3)
- `@path`: The request path ([@!RFC9421], Section 2.2.6)
- `signature-key`: The Signature-Key header value

These four are mandated rather than advisory because each closes a request-substitution attack and all four are derivable by the agent at signing time on every platform, including browsers: `@method` prevents a captured signature from being replayed with a different method (a signed `GET` reused as a `DELETE`); `@authority` binds the signature to the target host, preventing cross-host replay; `@path` binds it to the specific endpoint; and `signature-key` binds the signature to the presented key material, preventing key substitution. Omitting any one would let a captured signature be replayed against a different method, host, path, or key.

On a request carrying a body to a PS or AS endpoint, the signature MUST additionally cover:

- `content-digest`: The Content-Digest header value ([@!RFC9530])
- `content-type`: The Content-Type header value

Without them a request body is not integrity-protected, and PS and AS requests carry members that decide what is authorized — `justification`, `mission_s256`, `resource`, `sub`, and the mission proposal itself. Only the tokens among those members are self-protecting; the rest are plain JSON. The requirement is unconditional at these endpoints because every one of them takes a JSON body of known shape, so computing a digest costs the sender nothing it was not already doing.

Resources are different: they serve arbitrary APIs, including bodyless requests, streamed uploads, and payloads large enough that digesting them is a real cost. A resource therefore declares what it needs through `additional_signature_components` (#resource-metadata) rather than the protocol mandating it. Servers MAY require further covered components; the agent learns about them from server metadata or from an `invalid_input` error response that includes `required_input`.

The following example shows a fully bound request combining a session token and an HTTP Message Signature. Token and key values are illustrative placeholders, not parseable test vectors. `Authorization: AAuth` carries the session token; `Signature-Key` carries the auth token (four-party) or agent token, whose `cnf.jwk` is the signing key. A valid signature over these components proves request-component integrity; authorization still depends on auth-token claims and resource enforcement.

```http
GET /api/documents HTTP/1.1
Host: resource.example
Authorization: AAuth session-token-placeholder
Signature-Input: sig=("@method" "@authority" "@path"
    "authorization" "signature-key");created=1730217600
Signature: sig=:BASE64URL-SIGNATURE-PLACEHOLDER:
Signature-Key: sig=jwt;jwt="eyJhbGciOiJFZERTQSJ9.PLACEHOLDER.PLACEHOLDER"
```

#### Signature Parameters

The `Signature-Input` header ([@!RFC9421], Section 4.1) MUST include the following parameters:

- `created`: Signature creation timestamp as an Integer (Unix time). The agent MUST set this to the current time.

Agents MUST NOT include the `alg` signature parameter, and verifiers MUST ignore it if present, per [@!RFC9421], Section 3.3.7: under the JOSE signing algorithms this profile uses, the algorithm is signaled by the key rather than requested on the wire, and JWA identifiers are not registered in the HTTP Signature Algorithms registry. The algorithm is determined per (#signature-algorithms).

Agents SHOULD NOT include the `keyid` parameter ([@!RFC9421], Section 5.1); the key is identified by the `Signature-Key` header. If `keyid` is present for a label that also appears in `Signature-Key`, the two MUST identify the same key, and the verifier MUST take the key from `Signature-Key`.

### Verification (Server) {#verification}

When a server receives a signed request, it MUST perform the following steps. Any failure MUST result in a `401` response with the appropriate `Signature-Error` header ([@!I-D.hardt-httpbis-signature-key]).

1. Extract the `Signature`, `Signature-Input`, and `Signature-Key` headers. If any are missing, return `invalid_request`.
2. Verify that the `Signature-Input` covers the required components defined in (#covered-components). If the server requires additional components, verify those are covered as well. If not, return `invalid_input` with `required_input`.
3. Verify the `created` parameter is present and within the server's signature validity window of the server's current time. The default window is 60 seconds. Servers MAY advertise a different window via their metadata (e.g., `signature_window` in resource metadata). Reject with `invalid_signature` if outside this window. Servers and agents SHOULD synchronize their clocks using NTP ([@RFC5905]).
4. Select the `Signature-Key` dictionary member for the label being verified and read its scheme. If the scheme is not one the server implements — including any scheme this profile does not use (#keying-material) and any unregistered value — return `unsupported_scheme` with an `Accept-Signature-Scheme` header naming the schemes the server accepts. A server MUST NOT fail in a scheme-specific or undefined manner on an unrecognized scheme.
5. Obtain the public key from the `Signature-Key` header according to the scheme, as specified in ([@!I-D.hardt-httpbis-signature-key]). Return `invalid_key` if the key cannot be parsed, `unknown_key` if the key is not found at the `jwks_uri`, `invalid_jwt` if a JWT scheme fails verification, `expired_jwt` if the JWT has expired, or `issuer_missing` / `issuer_mismatch` if the issuer's metadata document fails the checks in (#metadata-documents).
6. Determine the signature algorithm from the `alg` member of the obtained key, per (#signature-algorithms). Return `unsupported_algorithm` if `alg` is absent, is a polymorphic identifier, or names an algorithm or key type the server does not implement, and include an `Accept-Signature-Alg` header naming the algorithms the server accepts. Return `invalid_key` if the key's `kty` or `crv` disagrees with its `alg`.
7. Verify the HTTP Message Signature ([@!RFC9421]) using the obtained public key and determined algorithm. Return `invalid_signature` if verification fails.

Steps 5 and 6 are ordered so that the algorithm is read from the key the scheme resolved to. Under `scheme=jwt` the key is the `cnf.jwk` of the presented token, which the server does not hold until the assertion has been verified.

An `Accept-Signature-Alg` header names exactly the algorithms the server accepts, neither a subset nor a superset, so an agent that selects an algorithm from that list and presents a key carrying it is assured of clearing step 6. A server MAY omit either `Accept-Signature-*` header where enumerating what it accepts to an unauthenticated caller is judged a disclosure risk, accepting that agents then have to discover the sets by trial or out of band.

This profile pins the response status to `401` for every signature failure, where the HTTP Signature Keys specification uses `400` for most of them and permits `401` for the recoverable ones. AAuth requests are authenticated by their signature, so a signature that does not verify is an authentication failure rather than a malformed request, and a single status keeps agent retry logic uniform.

A `403` response denies access after the signature verified — authentication succeeded and authorization did not. Per ([@!I-D.hardt-httpbis-signature-key]), such a response MUST NOT include a `Signature-Error`, `Accept-Signature-Scheme`, or `Accept-Signature-Alg` header. This applies to the AAuth errors returned with `403` (#token-endpoint-error-codes, #polling-error-codes).

#### Signature-Key Scheme Rejection {#scheme-rejection}

AAuth requires `scheme=jwt` (#keying-material), so a request presenting any other scheme is rejected under step 4 above:

```http
HTTP/1.1 401 Unauthorized
Signature-Error: error=unsupported_scheme
Accept-Signature-Scheme: jwt
```

A resource that also serves clients outside AAuth — signing per ([@!I-D.hardt-httpbis-signature-key]) without an AAuth agent token — MAY accept further schemes and MUST then list all of them. `Accept-Signature-Scheme` states what the server accepts from any caller; `AAuth-Requirement: requirement=agent-token` (#requirement-agent-token) is the narrower statement that an AAuth agent token in particular is required, and a server challenging an AAuth agent uses that rather than `Accept-Signature-Scheme`.

#### Freshness and Replay {#freshness-and-replay}

The `created` parameter is the primary replay defense: the server rejects signatures whose `created` is outside the validity window (default 60 seconds), so a captured signature becomes unusable once the window closes. `expires` is OPTIONAL; servers MUST honor it when present and MUST reject requests where `expires` is in the past.

Within the validity window, a captured signature could in principle be replayed. For state-changing requests where this matters, a verifier MAY maintain a short-lived cache keyed by `(signing-key-thumbprint, created, @method, @authority, @path)` for the duration of the window, rejecting duplicate tuples. `@authority` is included because it is a mandated covered component (#covered-components) and distinguishes requests across virtual hosts or tenants sharing the same path. Resources are NOT required to maintain replay caches for resource tokens (#resource-tokens), which are consumed in a single PS call. This profile defines no nonce mechanism.

## JWKS Discovery and Caching {#jwks-discovery}

All AAuth token verification — agent tokens, resource tokens, and auth tokens — requires discovering the issuer's signing keys via the `{iss}/.well-known/{dwk}` pattern defined in the HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]).

Every key an AAuth server publishes at its `jwks_uri` MUST carry a fully-specified `alg` member (#signature-algorithms). A JWKS is the only channel through which the algorithm of a discovered key is conveyed — the `Signature-Key` header carries `iss`, `kid`, and `dwk`, which identify a key rather than describe it — so a published key that omits `alg` cannot be used, even though [@!RFC7517] makes the member OPTIONAL. Deployments reusing an existing JWKS need only ensure that the keys AAuth selects by `kid` carry `alg`; other members of the same document are never resolved.

A verifier MUST select the key matching `kid` without requiring any other member of the JWKS to be usable, and MUST NOT fail because an unselected member names a key type or algorithm it does not implement. Without this an issuer could not add a post-quantum key alongside a classical one — doing so would break every verifier that does not implement the new key type, including those that were only ever going to use the classical key.

Implementations MUST cache JWKS responses and SHOULD respect HTTP cache headers (`Cache-Control`, `Expires`) returned by the JWKS endpoint. When an implementation encounters an unknown `kid` in a JWT header, it SHOULD refresh the cached JWKS for that issuer to support key rotation. To prevent abuse, implementations MUST NOT fetch a given issuer's JWKS more frequently than once per minute. If a JWKS fetch fails, implementations SHOULD use the cached JWKS if available and SHOULD retry with exponential backoff. Cached JWKS entries SHOULD be discarded after a maximum of 24 hours regardless of cache headers, to ensure removed keys are no longer trusted.

If a cached key matching the JWT `kid` fails signature verification, the verifier SHOULD refresh the issuer's JWKS once and retry before returning `unknown_key` (if the key is then absent from the refreshed JWKS) or `invalid_jwt` (if verification still fails), subject to the once-per-minute floor above. This covers silent re-keying where the issuer replaces key material under the same `kid` without changing the identifier.

Before fetching any issuer metadata or `jwks_uri`, verifiers MUST apply egress admission per ([@!I-D.hardt-httpbis-signature-key]).

## Identifiers {#identifiers-and-discovery}

### Server Identifiers

The `issuer` values in metadata documents that identify agent providers, resources, access servers, and person servers MUST conform to the following:

- MUST use the `https` scheme
- MUST contain only scheme and host (no port, path, query, or fragment)
- MUST NOT include a trailing slash
- MUST be lowercase
- Internationalized domain names MUST use the ASCII-Compatible Encoding (ACE) form (A-labels) as defined in [@!RFC5890]

Valid identifiers:

- `https://agent.example`
- `https://xn--nxasmq6b.example` (internationalized domain in ACE form)

Invalid identifiers:

- `http://agent.example` (not HTTPS)
- `https://Agent.Example` (not lowercase)
- `https://agent.example:8443` (contains port)
- `https://agent.example/v1` (contains path)
- `https://agent.example/` (trailing slash)

Implementations MUST perform exact string comparison on server identifiers.

### Endpoint URLs

The `auth_token_endpoint`, `person_token_endpoint`, `authorization_endpoint`, `mission_endpoint`, and `callback_endpoint` values MUST conform to the following:

- MUST use the `https` scheme
- MUST NOT contain a fragment
- MUST NOT contain a query string

When `localhost_callback_allowed` is `true` in the agent's metadata, the agent MAY use a localhost callback URL as the `callback` parameter to the interaction endpoint.

### Other URLs

The `jwks_uri`, `tos_uri`, `policy_uri`, `logo_uri`, and `logo_dark_uri` values MUST use the `https` scheme.

## Metadata Documents {#metadata-documents}

Participants publish metadata at well-known URLs ([@!RFC8615]) to enable discovery.

When fetching a metadata document, implementations MUST verify that it contains an `issuer` member, and that the `issuer` value matches the URL the document was retrieved from (the URL minus the `/.well-known/{dwk}` suffix), compared by byte equality as presented. A document with no `issuer` MUST be rejected with `issuer_missing`; one whose `issuer` does not match MUST be rejected with `issuer_mismatch` ([@!I-D.hardt-httpbis-signature-key]). This is the check [@!RFC8414], Section 3.3 requires of authorization server metadata.

This check prevents host-poisoned metadata: an attacker hosting a metadata document at one domain that claims an `issuer` of a different domain. Without it, a permissive verifier following the `jwks_uri` in such a document could end up trusting attacker-controlled keys for tokens claiming the impersonated issuer.

The following fields are defined identically across all four metadata documents (`aauth-agent.json`, `aauth-resource.json`, `aauth-person.json`, `aauth-access.json`):

| Field | Requirement | Description |
|-------|-------------|-------------|
| `issuer` | REQUIRED | The server's HTTPS URL. MUST match the URL the document was fetched from. Placed in the `iss` claim of JWTs issued by this server. Required by any Signature-Key verifier to confirm the document belongs to the claimed signer ([@!I-D.hardt-httpbis-signature-key]). |
| `jwks_uri` | REQUIRED (see per-role) | URL to the server's JSON Web Key Set. |
| `accept_signature_algs` | OPTIONAL | JSON array of fully-specified JWS algorithm identifiers the server's verifier accepts — exactly the set, neither a subset nor a superset. Semantics identical to the `Accept-Signature-Alg` response header ([@!I-D.hardt-httpbis-signature-key]), advertised before first contact rather than after a failure. One list per server, covering every endpoint. Since `Ed25519` is REQUIRED of every party (#signature-algorithms), the list's value is naming the additional algorithms. A server MAY omit it for the same disclosure reasons it MAY omit the header. |
| `name` | OPTIONAL | Human-readable display name. |
| `description` | OPTIONAL | Markdown string describing the server, for display at consent screens or dashboards. Implementations MUST sanitize before rendering. |
| `logo_uri` | OPTIONAL | URL to the server's logo. MUST use `https`. |
| `logo_dark_uri` | OPTIONAL | URL to the server's logo for dark backgrounds. MUST use `https`. |
| `documentation_uri` | OPTIONAL | URL with developer documentation. MUST use `https`. |
| `tos_uri` | OPTIONAL | URL to terms of service. MUST use `https`. |
| `policy_uri` | OPTIONAL | URL to privacy policy. MUST use `https`. |

AAuth intentionally diverges from RFC 9728 on two points: AAuth uses `issuer` (not `resource`) as the primary identifier field so that a generic Signature-Key verifier can extract the signer identity uniformly from any dwk document without knowing which role it represents; and AAuth uses unprefixed field names (`name`, `tos_uri`, `policy_uri`, `documentation_uri`) rather than the `resource_`-prefixed forms in RFC 9728, for consistency across all four roles.

Per-role sections below list these common fields in their examples and note any role-specific REQUIRED/conditional differences (e.g., `jwks_uri` is conditionally REQUIRED for resources). Role-specific fields are listed after the common fields.

### Agent Provider Metadata {#agent-provider-metadata}

Published at `/.well-known/aauth-agent.json`:

```json
{
  "issuer": "https://agent.example",
  "jwks_uri": "https://agent.example/.well-known/jwks.json",
  "name": "Example AI Assistant",
  "description": "**Example AI Assistant** drafts and sends email on your behalf.",
  "logo_uri": "https://agent.example/logo.png",
  "logo_dark_uri": "https://agent.example/logo-dark.png",
  "documentation_uri": "https://agent.example/docs",
  "callback_endpoint": "https://agent.example/callback",
  "event_endpoint": "https://agent.example/events",
  "localhost_callback_allowed": true,
  "tos_uri": "https://agent.example/tos",
  "policy_uri": "https://agent.example/privacy"
}
```

Fields:

- `issuer` (REQUIRED): The agent provider's HTTPS URL (the `domain` in agent identifiers it issues). This is the value placed in the `iss` claim of agent tokens.
- `jwks_uri` (REQUIRED): URL to the agent provider's JSON Web Key Set
- `name` (OPTIONAL): Human-readable agent name
- `description` (OPTIONAL): A Markdown string describing the agent or its provider, for display to users (for example, at a PS consent screen or connected-agents dashboard). Implementations MUST sanitize the Markdown before rendering to users.
- `logo_uri` (OPTIONAL): URL to agent logo (per [@RFC7591])
- `logo_dark_uri` (OPTIONAL): URL to agent logo for dark backgrounds
- `documentation_uri` (OPTIONAL): URL with developer documentation for the agent provider
- `callback_endpoint` (OPTIONAL): The agent's HTTPS callback endpoint URL
- `event_endpoint` (OPTIONAL): HTTPS URL at which the AP receives event tokens from resources. Required if the AP supports AAuth Events ([@?I-D.hardt-aauth-events]).
- `login_endpoint` (OPTIONAL): URL where third parties can direct users to initiate authentication (#third-party-login)
- `localhost_callback_allowed` (OPTIONAL): Boolean. Default: `false`.
- `tos_uri` (OPTIONAL): URL to terms of service (per [@RFC7591])
- `policy_uri` (OPTIONAL): URL to privacy policy (per [@RFC7591])

### Person Server Metadata {#ps-metadata}

Published at `/.well-known/aauth-person.json`:

```json
{
  "issuer": "https://ps.example",
  "name": "Example Person Server",
  "description": "**Example Person Server** — manage which agents act for you and review what they do.",
  "logo_uri": "https://ps.example/logo.png",
  "logo_dark_uri": "https://ps.example/logo-dark.png",
  "documentation_uri": "https://ps.example/docs",
  "tos_uri": "https://ps.example/tos",
  "policy_uri": "https://ps.example/privacy",
  "auth_token_endpoint": "https://ps.example/token",
  "person_token_endpoint": "https://ps.example/person",
  "mission_endpoint": "https://ps.example/mission",
  "permission_endpoint": "https://ps.example/permission",
  "audit_endpoint": "https://ps.example/audit",
  "interaction_endpoint": "https://ps.example/interaction",
  "mission_control_endpoint": "https://ps.example/mission-control",
  "jwks_uri": "https://ps.example/.well-known/jwks.json"
}
```

Fields:

- `issuer` (REQUIRED): The PS's HTTPS URL. MUST match the URL used to fetch the metadata document. This is the value placed in the `iss` claim of JWTs issued by the PS.
- `name` (OPTIONAL): Human-readable person server name
- `description` (OPTIONAL): A Markdown string describing the person server, for display to users. Implementations MUST sanitize the Markdown before rendering to users.
- `logo_uri` (OPTIONAL): URL to person server logo
- `logo_dark_uri` (OPTIONAL): URL to person server logo for dark backgrounds
- `documentation_uri` (OPTIONAL): URL with developer documentation for the person server
- `tos_uri` (OPTIONAL): URL to terms of service
- `policy_uri` (OPTIONAL): URL to privacy policy
- `auth_token_endpoint` (REQUIRED): URL where agents send token requests
- `person_token_endpoint` (REQUIRED): URL where agents request a person token for a resource (#person-token-endpoint)
- `mission_endpoint` (OPTIONAL): URL where an agent proposes, updates, and completes the missions it owns (#missions). Present when the PS supports missions. A mission's own URL is `{mission_endpoint}/{mission_s256}`.
- `permission_endpoint` (OPTIONAL): URL where agents request permission for actions not governed by a remote resource (#permission-endpoint)
- `audit_endpoint` (OPTIONAL): URL where agents log actions performed (#audit-endpoint)
- `interaction_endpoint` (OPTIONAL): URL where agents relay interactions to the user through the PS (#interaction-endpoint)
- `mission_control_endpoint` (OPTIONAL): URL of the PS's mission control plane — where parties other than the owning agent read and manage missions: the person, an organization's administrator, or a management service. `mission_endpoint` is the agent's surface and authenticates callers by agent token; this endpoint serves principals AAuth does not define, so its authentication model, operations, and responses are left to a companion specification (#mission-management). A PS MAY also use it for a deployment's human-facing administrative interface.
- `revocation_endpoint` (OPTIONAL): URL where authorized parties can revoke tokens (#token-revocation). This is also where an agent provider revokes an agent token it issued, so that the PS denies the agent token and revokes what it issued for that agent.
- `jwks_uri` (REQUIRED): URL to the PS's JSON Web Key Set
- `scopes_supported` (RECOMMENDED): Array of scope values the PS supports, including identity scopes (e.g., `openid`, `profile`, `email`) and enterprise scopes (e.g., `tenant`, `groups`, `roles`)
- `claims_supported` (RECOMMENDED): Array of identity claim names the PS can provide (e.g., `sub`, `email`, `name`, `tenant`)

### Access Server Metadata {#access-server-metadata}

Published at `/.well-known/aauth-access.json`:

```json
{
  "issuer": "https://as.resource.example",
  "name": "Example Access Server",
  "description": "**Example Access Server** — issues access for the Example resource.",
  "logo_uri": "https://as.resource.example/logo.png",
  "logo_dark_uri": "https://as.resource.example/logo-dark.png",
  "documentation_uri": "https://as.resource.example/docs",
  "tos_uri": "https://as.resource.example/tos",
  "policy_uri": "https://as.resource.example/privacy",
  "auth_token_endpoint": "https://as.resource.example/token",
  "jwks_uri": "https://as.resource.example/.well-known/jwks.json"
}
```

Fields:

- `issuer` (REQUIRED): The AS's HTTPS URL. MUST match the URL used to fetch the metadata document. This is the value placed in the `iss` claim of auth tokens.
- `name` (OPTIONAL): Human-readable access server name
- `description` (OPTIONAL): A Markdown string describing the access server, for display to users. Implementations MUST sanitize the Markdown before rendering to users.
- `logo_uri` (OPTIONAL): URL to access server logo
- `logo_dark_uri` (OPTIONAL): URL to access server logo for dark backgrounds
- `documentation_uri` (OPTIONAL): URL with developer documentation for the access server
- `tos_uri` (OPTIONAL): URL to terms of service
- `policy_uri` (OPTIONAL): URL to privacy policy
- `auth_token_endpoint` (REQUIRED): URL where PSes send token requests
- `revocation_endpoint` (OPTIONAL): URL where authorized parties can revoke tokens (#token-revocation)
- `jwks_uri` (REQUIRED): URL to the AS's JSON Web Key Set

### Resource Metadata {#resource-metadata}

Published at `/.well-known/aauth-resource.json`:

```json
{
  "issuer": "https://resource.example",
  "jwks_uri": "https://resource.example/.well-known/jwks.json",
  "access_mode": "auth-token",
  "name": "Example Data Service",
  "description": "**Example Data Service** stores and serves your documents.",
  "logo_uri": "https://resource.example/logo.png",
  "logo_dark_uri": "https://resource.example/logo-dark.png",
  "documentation_uri": "https://resource.example/docs",
  "tos_uri": "https://resource.example/tos",
  "policy_uri": "https://resource.example/privacy",
  "authorization_endpoint": "https://resource.example/authorize",
  "scope_descriptions": {
    "data.read": "Read access to your data and documents",
    "data.write": "Create and update your data and documents",
    "data.delete": "Permanently delete your data and documents"
  },
  "additional_signature_components": ["content-type", "content-digest"]
}
```

Fields:

- `issuer` (REQUIRED): The resource's HTTPS URL. This is the value placed in the `iss` claim of resource tokens.
- `jwks_uri` (REQUIRED when the resource issues resource tokens or makes signed calls): URL to the resource's JSON Web Key Set. A resource that only verifies agent signatures for identity-based access — issuing no resource tokens and making no signed requests of its own (e.g., as an agent in multi-hop, #multi-hop) — has no keys to publish and MAY omit `jwks_uri`.
- `access_mode` (OPTIONAL): The credential flow the resource expects, letting an agent plan its first call without a speculative challenge. This document defines `agent-token` (identity-only — the agent signs with its agent token), `person-token` (the resource authorizes on the person's identity alone — the agent signs with a person token), `session-token` (resource-managed — the agent completes the resource's interaction/consent flow and receives a session token via `AAuth-Access`), and `auth-token` (the agent obtains an auth token from its PS using a resource token; the initial call MUST present a person token). Extensions MAY define further values, which are recorded in the AAuth Access Mode Value Registry (#aauth-access-mode-value-registry); R3 ([@?I-D.hardt-aauth-r3]) defines `per-call`, for a resource that authorizes each invocation individually against that call's parameters. An agent that does not recognize a declared value proceeds as it would with no declaration, calling the resource and reading the `AAuth-Requirement` it gets back. Default: `agent-token`. The declaration is advisory: a resource MAY return any `AAuth-Requirement` at runtime regardless of the declared mode (#requirement-responses), and MAY apply different modes to different endpoints — a resource advertising an R3 vocabulary states the mode for an individual operation there ([@?I-D.hardt-aauth-r3]), and otherwise an agent learns of any variation from the runtime requirement. An agent MAY use `access_mode` to skip resources its setup cannot satisfy — for example, a PS-less agent (no `ps` claim in its agent token) cannot complete the `auth-token` flow.
- `name` (OPTIONAL): Human-readable resource name
- `description` (OPTIONAL): A Markdown string describing the resource, for display to users (for example, at a consent screen). Implementations MUST sanitize the Markdown before rendering to users.
- `logo_uri` (OPTIONAL): URL to resource logo
- `logo_dark_uri` (OPTIONAL): URL to resource logo for dark backgrounds
- `documentation_uri` (OPTIONAL): URL with developer documentation for the resource
- `tos_uri` (OPTIONAL): URL to terms of service
- `policy_uri` (OPTIONAL): URL to privacy policy
- `authorization_endpoint` (OPTIONAL): URL where agents request authorization (#authorization-endpoint-request). When absent, the resource issues resource tokens and interaction requirements via `401` responses (#requirement-auth-token, #resource-managed-auth).
- `login_endpoint` (OPTIONAL): URL where third parties can direct users to initiate authentication (#third-party-login)
- `scope_descriptions` (OPTIONAL): Object mapping scope values to Markdown strings for consent display. Scope values are resource-specific; resources that already define OAuth scopes SHOULD use the same scope values in AAuth. Identity-related scopes (e.g., `openid`, `profile`, `email`) follow [@!OpenID.Core].
- `signature_window` (OPTIONAL): Integer. The signature validity window in seconds for the `created` timestamp. Default: 60. Resources serving agents with poor clock synchronization (mobile, IoT) MAY advertise a larger value. High-security resources MAY advertise a smaller value.
- `additional_signature_components` (OPTIONAL): Array of HTTP message component identifiers ([@!RFC9421]) that agents MUST include in the `Signature-Input` covered components when signing requests to this resource, in addition to the base components required by the HTTP Message Signatures profile ([@!I-D.hardt-httpbis-signature-key])
- `revocation_endpoint` (OPTIONAL): URL where authorized parties can revoke auth tokens for this resource (#token-revocation)

# Incremental Adoption {#incremental-adoption}

AAuth is designed for incremental adoption. Each party — agent, resource, PS, AS — can independently add support. The system works at every partial adoption state. No coordination is required between parties.

## Drop-In Replacement for API Keys and OAuth {#drop-in-migration}

The first two resource steps require neither a person server nor an access server. They map directly onto what resources already do today:

- **Agent identity access drops in where you use API keys.** A resource that verifies the agent's HTTP Message Signature gets a cryptographic, per-agent identity in place of a shared secret — nothing to copy and leak, no pre-registration, no authorization flow. The agent signs, the resource recognizes who it is and applies its existing access control. This is identity-based access (#overview-identity-access); it involves no PS and no AS.
- **Resource-managed access drops in where you use OAuth.** A resource keeps its existing authorization — consent screens, OAuth access tokens, or session tokens — and wraps it: it returns its existing token opaquely via the `AAuth-Access` header (#aauth-access), bound to the agent's signature so it cannot be stolen and replayed as a standalone bearer token. The resource talks directly to the agent. This is resource-managed (two-party) access (#overview-resource-managed); it too involves no PS and no AS.

Both modes are complete and useful on their own. Adding a PS (PS authorization, three-party) and an AS (federated authorization, four-party) is additive — it brings cross-domain identity assertion and policy federation — but neither is a prerequisite for the value a resource gets from the first two steps.

### Consuming a Resource End to End {#consuming-a-resource}

A resource that wants agents to discover and use it with no prior integration publishes two things in its `aauth-resource.json` (#resource-metadata):

- **`access_mode`** — the credential flow the agent should expect: `agent-token`, `person-token`, `session-token`, or `auth-token`.
- **An R3 vocabulary.** Resources SHOULD advertise an R3 vocabulary (`r3_vocabularies`, [@?I-D.hardt-aauth-r3]) describing their operations, so that an agent that knows only the resource's hostname can learn the API and begin using it. The R3 document itself is fetched only by the AS and PS, not the agent; the vocabulary (an OpenAPI, MCP, gRPC, or similar API description) is the agent-facing surface.

An agent onboards as follows:

1. Fetch `aauth-resource.json`; read `access_mode` and the advertised vocabulary.
2. Fetch the vocabulary to learn the resource's operations, then construct calls.
3. If `access_mode` is `auth-token` and the agent has no PS, it cannot complete that flow and SHOULD skip the resource.
4. Make the call and satisfy whatever the resource requires, bringing the user in only where the mode calls for it:
   - **`agent-token`** — the agent signs with its agent token and calls. If the resource needs to bind the agent to a user account (the equivalent of associating an API key with an account), it returns a `202` with `requirement=interaction` (#requirement-responses) pointing at a login or account-link page; the agent brings the user there, directly or via the PS's interaction endpoint (#interaction-endpoint). Once bound, subsequent calls with the same agent token are recognized with no further interaction. No token is issued — the account-bound agent token is the durable credential.
   - **`session-token`** — the agent's call, or a request to the `authorization_endpoint`, triggers a `202` with `requirement=interaction` pointing at the resource's existing consent or login flow. After the user completes it, the resource returns an opaque token via the `AAuth-Access` header (#aauth-access); the agent presents that token in `Authorization: AAuth ...`, bound to its signature, on subsequent calls.
   - **`auth-token`** — the resource issues a resource token via the `authorization_endpoint` or a `401` (#requirement-auth-token). The agent sends it to its PS, which runs consent — bringing the user in at the PS, not the resource — and returns an auth token the agent signs with. Whether the PS asserts identity directly (three-party) or federates with the resource's AS (four-party) is invisible to the agent.

Throughout, the agent runs a single loop: make the request, read any `AAuth-Requirement`, satisfy it — bringing in the user where the requirement directs — and retry. The `access_mode` declaration lets the agent anticipate the flow; the runtime `AAuth-Requirement` remains authoritative, so a resource can mix modes across endpoints or escalate at any time.

## Agent Adoption Path

Each step builds on the previous one. An agent that adopts any step gains immediate value.

1. **Obtain an agent token and sign requests** (`scheme=jwt`, `typ: aa-agent+jwt`): The agent has a full AAuth identity with an `aauth:local@domain` identifier issued by an agent provider. It signs requests using HTTP Message Signatures ([@!RFC9421]) per the Signature-Key specification ([@!I-D.hardt-httpbis-signature-key]) and presents its agent token via the `Signature-Key` header using `scheme=jwt`. Resources that recognize signatures can verify the agent's identity and apply access control. Resources that don't ignore the signature and `Signature-Key` headers — existing auth mechanisms continue to work. This enables identity-based access.
2. **Add a person server** (include `ps` claim in agent token): The agent can obtain auth tokens from its PS directly. Resources in three-party and four-party modes can issue resource tokens targeting the PS. Enables PS-issued auth tokens with user identity, `tenant`, `groups`, and `roles` claims.
3. **Add governance** (create a mission): The agent creates a mission at its PS, gaining permissions, audit, PS-relayed interactions, and consent-managed resource access. The mission can be as simple as the user's prompt.

## Resource Adoption Path

Each step builds on the previous one. A resource that adopts any step works with agents at all identity levels.

1. **Recognize AAuth signatures**: Verify HTTP Message Signatures and respond with `Accept-Signature` headers ([@!I-D.hardt-httpbis-signature-key]). Resources that don't recognize AAuth ignore the signature headers — existing auth mechanisms continue to work. This is identity-based access.
2. **Manage authorization**: Handle authorization with interaction, consent, or existing infrastructure — via `401` responses, an authorization endpoint, or both. Return `AAuth-Access` headers (#aauth-access) for subsequent calls. This is resource-managed access (two-party).
3. **Accept identity claims from any PS**: Read the `ps` claim from the agent token and issue resource tokens with `aud` = PS URL. The agent's PS returns an auth token asserting identity claims about the user and consent for the requested scope; the resource applies its own policy. This is PS-asserted access (three-party).
4. **Deploy an access server**: Issue resource tokens with `aud` = AS URL. The PS federates with the AS. This is federated access (four-party).

## Adoption Matrix

| Agent | Resource | Mode | What Works |
|-------|----------|------|------------|
| Agent token | Recognizes signatures | Agent identity | Identity verification, access control by agent identity |
| Agent token | Manages authorization | Resource-managed | Resource-handled auth, interaction, `AAuth-Access` |
| Person token | Accepts person tokens | Person identity | Resource knows the person and any mission; applies its own access control |
| Person token | Issues resource tokens | PS authorization | PS asserts identity and consent for a scope; resource applies its own policy |
| Person token | AS deployed | Federated authorization | Full federation, AS policy enforcement |
| Agent token + `ps` + mission | Any or none | + governance | Tool-call permissions, audit, PS-relayed interaction, consent-managed access |

# Security Considerations

## Proof-of-Possession

All AAuth tokens are proof-of-possession tokens. The holder must prove possession of the private key corresponding to the public key in the token's `cnf` claim.

## Token Security

- Agent tokens bind agent keys to agent identity
- Resource tokens bind access requests to resource identity, preventing confused deputy attacks
- Auth tokens bind authorization grants to agent keys

## Pending URL Security

- Pending URLs MUST be unguessable and SHOULD have limited lifetime
- Pending URLs MUST be on the same origin as the server that issued them
- Servers MUST verify the agent's identity on every poll
- Once a terminal response is returned, the pending URL MUST return `410 Gone`

## Clarification Chat Security

- PSes MUST enforce a maximum number of clarification rounds
- Clarification responses from agents are untrusted input and MUST be sanitized before display

## Untrusted Input

All protocol inputs — JSON request bodies, clarification responses, justification strings, mission descriptions, and token claims — are untrusted input from potentially adversarial parties. This is consistent with standard web security practice where HTTP request bodies, headers, and query parameters are always treated as untrusted. Implementations MUST sanitize all values before rendering to users and MUST validate all values before processing. Markdown fields MUST be sanitized before rendering to prevent script injection.

## Interaction Code Misdirection

An attacker could attempt to trick a user into approving an authorization request by directing them to an interaction URL with the attacker's code. The PS mitigates this by displaying the full request context — the agent's identity, the resource being accessed, and the requested scope — so the user can recognize requests they did not initiate. A stronger mitigation is for the PS to interact directly with the user via a pre-established channel (push notification, email, or existing session) using `requirement=approval`, which eliminates the possibility of misdirection through attacker-supplied links entirely.

The reverse threat — an attacker who knows a pending request's interaction URL but not its `code` and tries to guess it to drive the interaction — is bounded by the code-format rules in (#interaction-code-format). The minimum 40 bits of entropy make a single guess overwhelmingly likely to fail, and the mandatory rate-limit terminates the pending interaction after a few failed attempts, capping total guesses far below the entropy bound. These entropy and rate-limit requirements are the brute-force defense; they complement the user-recognition and pre-established-channel defenses above, which address misdirection of a legitimate code rather than recovery of an unknown one.

## Token Issuer Discovery

The recipient of the resource token — and thus the issuer of the auth token — is identified by the `aud` claim. In three-party mode, `aud` identifies the agent's PS, which asserts identity and consent. In four-party mode, `aud` identifies the resource's AS, which evaluates resource policy. Federation mechanics for four-party are described in (#ps-as-federation).

## AAuth-Access Security

The `AAuth-Access` header carries an opaque wrapped token that is meaningful only to the issuing resource. The token MUST NOT be usable as a standalone bearer token — the resource wraps its internal authorization state so that the token is meaningless without a valid AAuth signature from the agent. The agent MUST include `authorization` in the signed components when presenting the token, binding it to the signed request.

## Trust Posture in PS-Asserted Access

In three-party mode, the resource has no AS of its own — it accepts identity claims and consent from whichever PS the agent declares. This is a deliberate trust posture: the resource externalizes identity claim issuance while retaining policy enforcement. Resources MUST apply their own policy on the resulting claims rather than treating the PS-issued auth token as a bearer authorization. Resources that need policy decisions made externally (per-resource scope enforcement, organizational gating, billing) should deploy an AS and use four-party mode.

Because identity assertion does not require pre-registration, the resource follows the same protocol flow whether it is meeting the user for the first time or recognizing a returning one. The auth token's `(iss, sub)` pair is a stable identifier per user per PS — the resource looks up the tuple and creates a new user record on a miss, matches an existing one on a hit. As in many OIDC deployments, registration and login are the same flow; the resource's own logic distinguishes the two outcomes. In multi-tenant deployments the auth token MAY also carry a `tenant` claim ([@OpenID.Enterprise]); `(iss, tenant, sub)` identifies a user within an organization, and `(iss, tenant)` identifies the organization itself — useful for grouping users from the same employer or account.

The PS MUST protect its signing keys with appropriate rigor — compromise of a PS's signing key allows forgery of identity claims for every resource that accepts that PS.

## Person Token Exposure {#person-token-exposure}

A person token identifies the person to a resource before any authorization decision, on every request that carries one including those the resource refuses. A resource therefore learns of people whose agents it never serves.

The directed `sub` bounds the exposure to one `(PS, resource)` pair. The PS bounds it further: it decides whether to issue at all, and SHOULD treat the first person token for a given resource as requiring the person's approval (#person-token-endpoint).

A person token grants nothing, so disclosure to an unintended party leaks an identifier and no access, and `cnf` prevents another party from presenting it.

## Continuity, Not Identity Proofing {#continuity-not-proofing}

A person token proves "the same entity again", not a verified legal identity. The protocol does not state what standard, if any, a PS applied before recognizing a person, and a resource MUST NOT infer one (#person-tokens). Continuity is sufficient for most resource access: authorizing an agent, keeping an account stable across agents and sessions, applying per-person policy. A resource requiring more — an age check, a residency check, regulated onboarding — obtains it out of band or through claims a person server explicitly asserts.

## Organization Identification {#person-token-org-policy}

The OPTIONAL `tenant` claim declares the organization the person belongs to, and unlike `sub` it is not directed — the same value appears at every resource the organization's agents reach.

That is deliberate. It lets a resource apply organizational policy before it issues anything: recognise a contracted customer, or rate-limit and refuse an organization whose agents are abusing it. Without it a resource's only lever at first contact is the person server, which is far too coarse — refusing one would refuse every organization that uses it — and pairwise `sub` otherwise makes one organization's agents indistinguishable from many unrelated people.

`tenant` is organizational context and MUST NOT be treated as part of the person's identifier, which is `(iss, sub)` (#directed-identifiers).

## Person Token Is Not Authorization {#person-token-not-authorization}

A PS-issued auth token and a person token carry the same `iss`, `dwk`, `aud`, `sub`, and `cnf`. Only `typ` distinguishes them. A resource that verifies the signature and reads `sub` without checking `typ` accepts a person token wherever it accepts an auth token.

Implementations MUST check `typ` before acting on any AAuth JWT, and MUST reject `aa-person+jwt` where an auth token is required (#person-token-verification). Deployments SHOULD test this case explicitly; it fails open.

## Incremental Consent {#incremental-consent}

A mission can be updated (#mission-update), and an update may broaden the work as well as narrow it. An agent could therefore propose a modest mission, obtain easy approval, and broaden it in steps each small enough to wave through, arriving somewhere the person would have refused had it been proposed at the outset.

The person's acceptance is required at every step, so no single step is unauthorized. What erodes is the person's sense of the whole. A PS SHOULD present the accumulated picture — the approved description together with the updates already accepted — when asking the person to accept another, rather than the increment alone.

The same erosion is available through a series of separate missions, so this is a property of incremental approval rather than of the update mechanism. It is stated here because the update mechanism makes it cheap.

## PS Approval Endpoint Authentication {#ps-approval-endpoint-auth}

When the PS approval/consent endpoint is reachable beyond a single-user local deployment, the PS MUST authenticate the approving party before acting on a consent or denial decision. Acceptable mechanisms include an operator session cookie, a signed request from an authenticated operator, or an equivalent out-of-band channel.

An unauthenticated approval endpoint allows a remote party to consent on the user's behalf — a privilege escalation that breaks the agent-person binding invariant (#agent-person-binding). A locally-trusted PS (loopback only, no external network reachability) is exempt from this requirement provided it enforces OS-level access controls on the loopback interface.

## Agent-Person Binding {#agent-person-binding}

The PS MUST ensure that each agent is associated with exactly one person. This one-to-one binding is a trust invariant — it ensures that every action an agent takes is attributable to a single accountable party.

The binding is typically established lazily — when the person first authorizes the agent at the PS via the interaction flow. The PS recognizes a returning agent by `(agent_token.iss, agent_token.sub)`; on first interaction with a new tuple for a person, the PS SHOULD treat it as a new-agent enrollment and surface this clearly at the consent screen, displaying the agent provider's name and logo (from agent provider metadata) alongside any agent-supplied display values (`platform`, `device`) provided in the request. An organization administrator may pre-authorize agents for the organization. Once established, the PS MUST NOT allow a different person to claim the same agent. If an agent's association needs to change (e.g., an employee leaves an organization), the existing binding MUST be revoked and a new binding established.

This invariant enables:

- **Accountability**: Every authorization decision traces to a single person.
- **Consent integrity**: Consent granted by one person cannot be exercised by a different person through the same agent.
- **Audit**: The PS can provide a complete record of an agent's actions on behalf of its person.
- **Revocation**: Revoking an agent's association with its person immediately prevents the agent from obtaining new auth tokens.

## PS as High-Value Target

The PS is a centralized authority that sees every authorization in a mission. PS implementations MUST apply appropriate security controls including access control, audit logging, and monitoring. Compromise of a PS could affect all agents and missions it manages.

Several architectural properties mitigate this centralization risk. The person chooses their PS — no other party in the protocol imposes a PS, and the person can migrate to a different PS at any time. The PS MAY delegate authentication to an identity provider chosen by the person or organization (e.g., an enterprise IdP via OIDC federation), reducing the PS's role in credential management. The PS MAY also delegate policy evaluation to external services selected by the person, so that consent and authorization decisions are not solely determined by the PS operator. To the rest of the protocol, the PS presents a single interface regardless of how it is composed internally.

## Call Chaining Identity

When a resource acts as an agent in call chaining, it uses its own signing key and presents its own credentials. The resource MUST publish agent metadata so downstream parties can verify its identity.

## Token Revocation and Lifecycle

Real-time revocation (#token-revocation) and short token lifetimes provide layered access control. Organizations have multiple control points — agent provider, PS, and AS — each of which can deny renewal or revoke tokens independently. Shorter auth token lifetimes reduce the window between a control action and natural expiration.

## TLS Requirements

All HTTPS connections MUST use TLS 1.2 or later, following the recommendations in BCP 195 [@!RFC9325].

## Non-Repudiation and Audit After Key Rotation

AAuth signatures prove authenticity at request time: a valid HTTP Message Signature shows that the signer held the private key bound to the presented identity when the request was made (proof-of-possession). This is request-time authentication, not long-term non-repudiation. Agent keys are short-lived and agent providers rotate their JWKS; once a key is removed from the issuer's JWKS, a signature made with it can no longer be verified by re-fetching the JWKS later. The persistent identifiers (`agent`, `sub`) do not by themselves cryptographically prove that a specific key signed a specific request at a specific time once that key is gone.

This is partly by design — short-lived keys and directed identifiers (#directed-identifiers) limit long-term linkability. Deployments that require durable audit or non-repudiation beyond a key's lifetime SHOULD capture the evidence at verification time, while the key is still discoverable, rather than relying on re-verification later:

- **Archive the verified artifacts.** At verification time, record the signed request (covered components and signature), the `Signature-Key` value (the presented key or JWT), the verification result, and a trusted timestamp. Optionally snapshot the issuer's JWKS entry (`kid` + JWK) so the key binding can be re-checked independently of later rotation.
- **Use external timestamping or transparency logs** where stronger non-repudiation is needed — for example, RFC 3161 [@?RFC3161] timestamps over the signed request, or appending verification records to a tamper-evident log.
- **Bind audit records to durable identifiers.** Index archived records by `(iss, sub)` for agents and by `jti` for tokens, so later review can attribute activity even though the signing key is no longer live.

These measures trade privacy for durability: archived signatures and keys are correlatable, so deployments MUST balance audit retention against the privacy-preserving properties of short-lived keys and directed identifiers (#privacy-considerations), and apply appropriate retention limits and access controls.

# Privacy Considerations

## Directed Identifiers

The PS SHOULD provide a pairwise pseudonymous user identifier (`sub`) per resource, preventing resources from correlating users across trust domains. Each resource sees a different `sub` for the same user, preserving user privacy.

A `sub` MUST be unique within the issuer, so `(iss, sub)` identifies the person unambiguously and `tenant` is never part of the identifier. The same value MUST be used in the person token (#person-token-structure), in the resource token the resource derives from it, and in every auth token issued for that resource, and MUST NOT vary with the agent or its key.

Directed identifiers limit correlation between resources. They do not make a person's activity at one resource unlinkable across their agents: the agent signs with one key everywhere and that key appears in `cnf` in every token, so parties able to compare thumbprints correlate regardless of `sub`.

The person token reduces what a resource learns before authorization rather than increasing it. Presenting an agent token discloses the agent provider's domain and an agent identifier that is the same at every resource the agent visits — and because each agent belongs to exactly one person (#agent-person-binding), that identifier is a globally correlatable pseudonym for the person. A person token replaces both with an identifier scoped to the one resource receiving it.

## PS Visibility

In three-party and four-party modes, the PS sees every authorization request made by its agents — including the resource being accessed, the requested scope, and the mission context. This centralized visibility enables governance and audit, but it also means the PS is a sensitive data aggregation point. The person chooses to trust their PS with this visibility — no other party imposes the choice. PS implementations MUST apply appropriate access controls and data retention policies.

In two-party mode, no PS is involved and there is no centralized visibility — the resource handles authorization directly with the agent.

## Mission Content Exposure

The mission JSON is visible to the PS and, when included in resource tokens and auth tokens via the `s256` hash, its integrity is verifiable by any party that holds it. The approved mission JSON is shared between the agent and PS. Resources and ASes see only the `s256` hash and the approver URL, not the full mission content.

# IANA Considerations

## HTTP Header Field Registration

This specification registers the following HTTP header fields in the "Hypertext Transfer Protocol (HTTP) Field Name Registry" established by [@!RFC9110]:

- Header Field Name: `AAuth-Requirement`
- Status: permanent
- Structured Type: Dictionary
- Reference: This document, (#requirement-responses)

- Header Field Name: `AAuth-Access`
- Status: permanent
- Reference: This document, (#aauth-access)

- Header Field Name: `AAuth-Capabilities`
- Status: permanent
- Structured Type: List
- Reference: This document, (#aauth-capabilities)

## HTTP Authentication Scheme Registration

This specification registers the following HTTP authentication scheme in the "Hypertext Transfer Protocol (HTTP) Authentication Scheme Registry" established by [@!RFC9110]:

- Authentication Scheme Name: `AAuth`
- Reference: This document, (#aauth-access)
- Notes: Used with session tokens returned via the `AAuth-Access` header. The token MUST be bound to an HTTP Message Signature — the `authorization` field MUST be included in the signature's covered components.

## Well-Known URI Registrations

This specification registers the following well-known URIs per [@!RFC8615]:

| URI Suffix | Change Controller | Reference |
|---|---|---|
| `aauth-agent.json` | IETF | This document, (#agent-provider-metadata) |
| `aauth-person.json` | IETF | This document, (#ps-metadata) |
| `aauth-access.json` | IETF | This document, (#access-server-metadata) |
| `aauth-resource.json` | IETF | This document, (#resource-metadata) |

## Media Type Registrations

This specification registers the following media types:

### application/aa-agent+jwt

- Type name: application
- Subtype name: aa-agent+jwt
- Required parameters: N/A
- Optional parameters: N/A
- Encoding considerations: binary; a JWT is a sequence of Base64url-encoded parts separated by period characters
- Security considerations: See (#security-considerations)
- Interoperability considerations: N/A
- Published specification: This document, (#agent-tokens)
- Applications that use this media type: AAuth agents, PSes, and ASes
- Fragment identifier considerations: N/A

### application/aa-auth+jwt

- Type name: application
- Subtype name: aa-auth+jwt
- Required parameters: N/A
- Optional parameters: N/A
- Encoding considerations: binary; a JWT is a sequence of Base64url-encoded parts separated by period characters
- Security considerations: See (#security-considerations)
- Interoperability considerations: N/A
- Published specification: This document, (#auth-tokens)
- Applications that use this media type: AAuth ASes, agents, and resources
- Fragment identifier considerations: N/A

### application/aa-person+jwt

- Type name: application
- Subtype name: aa-person+jwt
- Required parameters: N/A
- Optional parameters: N/A
- Encoding considerations: binary; a JWT is a sequence of Base64url-encoded parts separated by period characters
- Security considerations: See (#security-considerations)
- Interoperability considerations: N/A
- Published specification: This document, (#person-tokens)
- Applications that use this media type: AAuth PSes, agents, and resources
- Fragment identifier considerations: N/A

### application/aa-resource+jwt

- Type name: application
- Subtype name: aa-resource+jwt
- Required parameters: N/A
- Optional parameters: N/A
- Encoding considerations: binary; a JWT is a sequence of Base64url-encoded parts separated by period characters
- Security considerations: See (#security-considerations)
- Interoperability considerations: N/A
- Published specification: This document, (#resource-tokens)
- Applications that use this media type: AAuth resources and ASes
- Fragment identifier considerations: N/A

## JWT Type Registrations

This specification registers the following JWT `typ` header parameter values in the "JSON Web Token Types" sub-registry:

| Type Value | Reference |
|---|---|
| `aa-agent+jwt` | This document, (#agent-tokens) |
| `aa-person+jwt` | This document, (#person-tokens) |
| `aa-auth+jwt` | This document, (#auth-tokens) |
| `aa-resource+jwt` | This document, (#resource-tokens) |

The following JWT `typ` values are registered by AAuth Events ([@?I-D.hardt-aauth-events]):

| Type Value | Reference |
|---|---|
| `aa-subscribe+jwt` | [@?I-D.hardt-aauth-events] |
| `aa-event+jwt` | [@?I-D.hardt-aauth-events] |

## JWT Claims Registrations

This specification registers the following claims in the IANA "JSON Web Token Claims" registry established by [@!RFC7519]:

| Claim Name | Claim Description | Change Controller | Reference |
|---|---|---|---|
| `dwk` | Discovery Well-Known document name | IETF | This document |
| `ps` | Person server URL — the agent's person server in an agent token, and the person server whose namespace `sub` belongs to in a resource or auth token | IETF | This document |
| `agent_jkt` | JWK Thumbprint of the agent's signing key, in a resource token | IETF | This document |
| `parent_agent` | Parent agent identifier in a sub-agent's agent token | IETF | This document |
| `presented_jti` | The `jti` of the person token a resource token is bound to | IETF | This document |
| `mission_s256` | SHA-256 hash of the approved mission JSON, in person, resource, and auth tokens | IETF | This document |
| `account` | Account the authorization is for, in resource and auth tokens | IETF | This document |
| `interaction` | Resource interaction step required before authorization, an object with `url` and `code`, in a resource token | IETF | This document |

## AAuth Requirement Value Registry

This specification establishes the AAuth Requirement Value Registry. The registry policy is Specification Required ([@!RFC8126], Section 4.6). See (#designated-expert-instructions) for instructions to the designated expert.

| Value | Reference |
|-------|-----------|
| `agent-token` | This document |
| `person-token` | This document |
| `interaction` | This document |
| `approval` | This document |
| `auth-token` | This document |
| `clarification` | This document |
| `claims` | This document |

## AAuth Capability Value Registry

This specification establishes the AAuth Capability Value Registry. The registry policy is Specification Required ([@!RFC8126], Section 4.6). See (#designated-expert-instructions) for instructions to the designated expert.

| Value | Reference |
|-------|-----------|
| `interaction` | This document |
| `clarification` | This document |
| `payment` | This document |

## AAuth Platform Value Registry {#aauth-platform-value-registry}

This specification establishes the AAuth Platform Value Registry, used as values of the `platform` request parameter sent to the PS token endpoint (#ps-token-endpoint). The registry policy is Specification Required ([@!RFC8126], Section 4.6). See (#designated-expert-instructions) for instructions to the designated expert.

| Value | Description | Reference |
|-------|-------------|-----------|
| `web` | Browser-hosted web application | This document |
| `mobile` | Native mobile application (iOS, Android) | This document |
| `desktop` | Native desktop application (macOS, Windows, Linux) | This document |
| `workload` | Headless server-class workload (backend service, CI runner, scheduled job, edge function) | This document |
| `self-hosted` | User-controlled deployment under a domain the user controls | This document |

## AAuth Access Mode Value Registry {#aauth-access-mode-value-registry}

This specification establishes the AAuth Access Mode Value Registry, used as values of the `access_mode` field in resource metadata (#resource-metadata). The registry policy is Specification Required ([@!RFC8126], Section 4.6). See (#designated-expert-instructions) for instructions to the designated expert.

| Value | Description | Reference |
|-------|-------------|-----------|
| `agent-token` | The resource authorizes on the agent's identity alone | This document |
| `person-token` | The resource authorizes on the person's identity alone | This document |
| `session-token` | The resource manages authorization itself and issues a session token | This document |
| `auth-token` | The agent obtains an auth token from its PS using a resource token | This document |

## Designated Expert Instructions {#designated-expert-instructions}

Registration requests for the AAuth Requirement Value, AAuth Capability Value, AAuth Platform Value, and AAuth Access Mode Value registries are evaluated by a designated expert appointed by the IESG, using the Specification Required policy ([@!RFC8126], Section 4.6).

Registration requests should be sent to IANA, which will forward them to the designated expert. The expert is expected to respond within two weeks. Denials should include an explanation and, if applicable, suggestions for how the request could be revised to be successful.

A registration request must include the proposed value, a brief description of its meaning, and a reference to the specification defining it. The designated expert should verify that:

- The referenced specification is stable and freely available, and describes the value's semantics in sufficient detail that interoperable, independent implementations are possible.
- The proposed value is a lowercase token using only lowercase letters and hyphen, consistent with the registries' existing entries, and is not confusingly similar to an existing entry.
- The registration does not duplicate the semantics of an existing entry without clear justification.
- For the Requirement Value and Capability Value registries, the specification defines the protocol behavior expected of a party that declares or encounters the value, including how a party that does not understand the value behaves.
- For the Platform Value registry, the value describes a distinct runtime context that is meaningful for display to a person at a consent screen or dashboard, and the description does not overstate the security properties the value conveys.
- For the Access Mode Value registry, the value names a credential flow an agent can carry out, the specification defines what the agent presents and how it obtains it, and an agent that does not understand the value can still fall back to the runtime `AAuth-Requirement`.

## URI Scheme Registration

This specification registers the `aauth` URI scheme in the "Uniform Resource Identifier (URI) Schemes" registry ([@!RFC7595]):

- Scheme name: `aauth`
- Status: Permanent
- Applications/protocols that use this scheme: AAuth Protocol
- Contact: IETF
- Change controller: IETF
- Reference: This document, (#agent-identifiers)

The `aauth` URI scheme follows the pattern established by the `acct` scheme ([@RFC7565]). An `aauth` URI identifies an agent instance and has the syntax `aauth:local@domain`, where `local` is the agent-specific part and `domain` is the agent provider's domain name. The `aauth` URI is used in the `sub` and `parent_agent` claims of agent tokens and in the `agent` field of the mission blob.

# Implementation Status

*Note: This section is to be removed before publishing as an RFC.*

This section records the status of known implementations of the protocol defined by this specification at the time of posting of this Internet-Draft, and is based on a proposal described in [@RFC7942]. The description of implementations in this section is intended to assist the IETF in its decision processes in progressing drafts to RFCs.

The following implementations are known:

- **TypeScript** — [github.com/aauth-dev/packages-js](https://github.com/aauth-dev/packages-js). Organization: Hellō. Coverage: agent token issuance, HTTP Message Signatures, resource token exchange, PS token endpoint. Level of maturity: exploratory.
- **.NET** — [github.com/aauth-dev/dotnet-samples](https://github.com/aauth-dev/dotnet-samples) (NuGet: `AAuth`). Contact: Dasith Wijesiriwardena. Coverage: SDK spanning the access modes, the three-party challenge/exchange flow (autonomous and deferred consent), signature verification middleware, resource and auth token builders, and JWKS/metadata discovery, plus Blazor sample apps. Level of maturity: exploratory.
- **Python** — [github.com/christian-posta/aauth-full-demo](https://github.com/christian-posta/aauth-full-demo). Contact: Christian Posta. Coverage: agent-to-resource flows with Keycloak as AS. Level of maturity: exploratory.
- **Java (Keycloak SPI)** — [github.com/christian-posta/keycloak-aauth-extension](https://github.com/christian-posta/keycloak-aauth-extension). Contact: Christian Posta. Coverage: AAuth access server extension for Keycloak 26.2.5. Level of maturity: exploratory.

# Document History

*Note: This section is to be removed before publishing as an RFC.*

- draft-hardt-oauth-aauth-protocol-11
  - Three places still said a resource discovers the agent's PS from the `ps` claim in the agent token — the three-party access mode, the bootstrapping requirements, and the claim's own definition — which the Design Rationale already contradicted. The agent token's `ps` is the advance signal that the agent has a person server, which is what lets a resource decide to challenge for a person token. The PS of an issued authorization is the `iss` of the person token the resource verified, which the resource copies into the resource token's `ps`.
  - Corrected the JWT Claims Registrations table. `ps` was registered twice; the two rows are collapsed into one covering agent, resource, and auth tokens. `agent` is no longer a claim in any token and its row is removed — it survives only as a member of the mission blob, which is not a JWT. Added `presented_jti`, `account`, and `interaction`, none of which were registered.
  - Established the AAuth Access Mode Value Registry, seeded with `agent-token`, `person-token`, `session-token`, and `auth-token`. The `access_mode` field was described as a closed list of four, which left no room for the `per-call` value R3 defines; the registry is how the other extensible AAuth value spaces are already handled.
  - Pointed `access_mode` at R3 operation access annotations. Two places said a resource MAY apply different modes to different endpoints without naming a mechanism for saying which.
  - Added the person token (`aa-person+jwt`), issued by a PS to identify the person to one resource. Presented via `Signature-Key` in place of the agent token. A resource MUST verify one before issuing a resource token. Lifetime capped at 1 hour, as for auth tokens.
  - Added `person_token_endpoint`, REQUIRED in PS metadata, taking `resource`, `mission_s256`, `subagent_token`, and `upstream_token`.
  - Five resource access modes instead of four, sorted by what the resource ends up knowing and which party established it: agent identity, resource-managed, person identity, PS authorization, federated authorization. A resource MAY apply different modes to different endpoints.
  - A person token carries no authorization from the PS, but a resource MAY serve requests on identity alone, so holding one is effectively access at such a resource. The consent question at first issuance is whether the agent may act at the resource as the person.
  - Renamed the PS and AS metadata field `token_endpoint` to `auth_token_endpoint`; added `person-token` to `access_mode`.
  - Added `requirement=person-token`, and the `invalid_person_token` and `invalid_account` authorization endpoint errors.
  - Resource tokens carry `ps`, `sub`, and `presented_jti`, and no agent identifier. The PS resolves the named person token and rejects any mismatch, which makes mission stripping detectable — comparing claims alone cannot, because concurrent missions mean several person tokens per agent and resource.
  - Auth tokens carry `ps` and a REQUIRED `sub`, and no agent identifier. `act` and the delegation chain are removed.
  - Replaced the `mission` object with the `mission_s256` claim in person, resource, and auth tokens; `approver` is dropped everywhere but the mission blob.
  - Removed the `AAuth-Mission` header and its registration. A mission reaches a resource only inside a PS-issued token, so it is no longer agent-asserted. The approval response carries the mission blob base64url-encoded, with `s256` alongside it, so the digest covers an unambiguous byte sequence and the agent can verify it as it would a JWT payload.
  - Mission blob gained `approved_resources` and MAY carry `expires_at`; no token carrying `mission_s256` may outlive it, and every PS decision path compares the current time to it. Added the `mission_expired` status.
  - Moved `capabilities` out of the mission blob to the approval response — it describes whether the PS can currently reach the person, which is not a term of the mission and should not perturb its digest.
  - A mission proposal MAY name the `resources` it expects to use; the approval response returns a person token for each.
  - Chain routing uses the auth token's `ps` claim. Removed the branch routing a downstream request to the upstream AS, which required the two resources to share an access server and was never stated as such.
  - `sub` MUST be unique within the issuer; `(iss, sub)` is the identifier and `tenant` is organizational context, not part of it. `sub` values from different issuers MUST NOT be matched.
  - Stated the extensibility posture: recipients ignore what they do not recognize, and no document carries a version or schema a recipient must understand.
  - Defined the mission endpoint's error responses, including that a PS MUST answer identically — status, body, headers, and timing — whether a mission does not exist or the agent does not own it. Without that the agent surface is an existence oracle for any party that has seen a `mission_s256` in an auth token. Adopted from `draft-mcguinness-mission-aauth-management`.
  - The mission endpoint is the owning agent's surface, with three operations of one shape: `POST {mission_endpoint}` proposes a mission, and `POST {mission_endpoint}/{mission_s256}` carries `action: update` or `action: completion`. The `action` discriminator is the one the pending route already uses.
  - Added mission update. An update records a change in the work, is appended to the mission log, and is digested so the sequence is verifiable. It does not change the blob, `mission_s256`, or any token carrying it; what it changes is the context the PS evaluates against, so the mission's meaning becomes the approved blob plus its accepted updates and an audit MUST read both.
  - Moved completion off the interaction endpoint. It is a lifecycle transition, not transport: creation and completion are the same shape — the agent proposes, the person decides, clarification is available, the response is deferred — and were split across two endpoints for no structural reason. The interaction endpoint keeps `interaction`, `payment`, and `question`, which are the things the agent genuinely cannot do itself.
  - Defined the termination reasons `completed`, `revoked`, `expired`, `superseded`, and `administrative` as an open set recorded outside the immutable blob, and folded `mission_expired` back into `mission_terminated` with an OPTIONAL `termination_reason` member. One error rather than one per reason, because the reason set is open.
  - `mission_control_endpoint` is the mission control plane: where parties other than the owning agent read and manage missions. Its authentication model and operations are left to a companion specification, because AAuth defines no administrative principal.
  - A request carrying a body to a PS or AS endpoint MUST additionally sign `content-digest` and `content-type`. Those requests decide what is authorized and only their tokens were self-protecting. Resources keep declaring what they need through `additional_signature_components`, since bodyless requests and streamed uploads make a blanket requirement wrong there.
  - Stated that the mission blob's member lists are a floor: a PS MAY add members, readers ignore what they do not recognize, and a blob with an extra member has a different identifier because it is a different mission.
  - Named the opaque credential a resource issues in resource-managed access the **session token**. It was the only credential in the protocol without a name. The `access_mode` value `aauth-access-token` becomes `session-token`.
  - Renamed the resource token claim `person_token_jti` to `presented_jti`. The old name asserted the credential presented was a person token, which is false on every step-up and per-call challenge, where it is an auth token. The value is unchanged: the `jti` of the person token whose verification established `ps` and `sub`. Addresses issue #95.
  - Stated the person token's assurance floor where the token is introduced: it asserts recognition and agency, guarantees continuity of `(iss, sub)`, and a resource MUST NOT treat it as evidence of identity proofing, legal identity, or any assurance level. Addresses issue #97.
  - Stated the retention obligation resource token verification already implied: a PS MUST retain a record of each person token it issues, beyond `exp` by at least the longest resource token lifetime it accepts, and rejects a resource token naming an unretained `jti` with the new `unknown_person_token` error, distinct from a claim mismatch against an existing record. Addresses issue #87.
  - Added the OPTIONAL common metadata field `accept_signature_algs`, the out-of-band twin of the `Accept-Signature-Alg` response header: exactly the set of fully-specified algorithms the server's verifier accepts, one list per server. Addresses issue #94.
  - A resource MAY deliver `requirement=auth-token` as a `202 Accepted` deferred response that holds the invocation; the agent completes at the pending URL with the auth token, and completion consumes the pending record. The `401` remains the baseline delivery; agents MUST support both. Addresses issue #92.

- draft-hardt-oauth-aauth-protocol-10
  - Adopted the fully-specified `Ed25519` of [@!RFC9864] in place of the `EdDSA` it deprecates. `alg` is REQUIRED and MUST be fully specified; `EdDSA`, `none`, and symmetric algorithms MUST NOT be used; a verifier MUST reject a key whose `kty` or `crv` disagrees with its `alg`. Addresses issue #57.
  - A `cnf` JWK MUST carry a fully-specified `alg`, as MUST every key at an AAuth server's `jwks_uri`. A verifier MUST select the key matching `kid` without requiring the other JWKS members to be usable.
  - Aligned verification and error mapping with [@!I-D.hardt-httpbis-signature-key]: added `unsupported_scheme`, `unsupported_algorithm`, `invalid_key`, `issuer_missing`, and `issuer_mismatch`; pinned signature failures to `401`; a `403` MUST NOT carry `Signature-Error` or either `Accept-Signature-*` header; the `alg` signature parameter MUST NOT be used.
  - Revocation identifies a token by `(iss, jti)`, and recipients key revocation state by that pair. An agent provider revokes an agent token at the PS's `revocation_endpoint`. Addresses issues #59 and #60.
  - A downstream issuer MUST NOT copy a directed `sub` from an upstream token, MAY emit one only from its own authenticated federation step, and MUST NOT place a person identifier in `act`. Addresses issue #41.
  - Added the OPTIONAL `account` parameter on the authorization endpoint request, echoed in the resource token and copied into the auth token, binding an authorization to one of several accounts a resource may hold for the same person. Addresses issue #52.

- draft-hardt-oauth-aauth-protocol-09
  - Clarification chat: added a required `action` discriminator (`clarification_response` / `updated_request`) to the agent's POST responses on the pending URL, so the response type is explicit rather than inferred from key presence.
  - Error responses: adopted RFC 9457 problem details — error bodies use `Content-Type: application/problem+json` with the AAuth error code as a required `error` extension member; `error_description` replaced by the RFC 9457 `detail` member; added token endpoint and polling error examples.

- draft-hardt-oauth-aauth-protocol-08
  - Call chaining: upstream token `aud` MUST equal the `iss` of the intermediary's agent token; routing to PS or AS is derived from the upstream auth token (`mission.approver` or `iss`), not the calling agent's `ps` claim; PS MUST require a mission to remain in the loop for four-party upstream chains.
  - Interaction code: added that the code is a correlation identifier, not an authorization credential; the code alone MUST NOT authorize the decision.

- draft-hardt-oauth-aauth-protocol-07
  - Added `Interaction Callback Errors` section defining the `?error=` wire format for callback redirects (`access_denied`, `user_abandoned`, `server_error`, `temporarily_unavailable`, `interaction_expired`) and the PS mapping to polling errors. Updated Resource-Initiated Interaction to reference the new section and specify PS behavior on error callbacks. Added Joshua Gay to Acknowledgments.

- draft-hardt-oauth-aauth-protocol-06
  - Implementation and interoperability clarity driven by feedback from Joshua Gay (sidecat): mission reference dereference boundary and `approver`/`s256` syntax rules; agent keying material restricted to `scheme=jwt`; `AAuth-Requirement` parameter shape and unknown-value behavior; `AAuth-Access` token grammar (`token68`); `AAuth-Capabilities` forward-compatibility; JWKS same-`kid` refresh and egress admission; auth token verification split into JWT trust and request-context binding with structured `cnf.jwk` failure ordering; PS approval endpoint authentication security consideration; freshness and replay policy subsection. Interoperability demo profile extracted to a standalone non-normative document.

- draft-hardt-oauth-aauth-protocol-05
  - Auth tokens: `act` is OPTIONAL, absent in direct authorization; `act.agent` identifies the immediate upstream agent (the delegator), not the presenter; nesting records the full chain. Updated verification steps, sub-agent issuance, PS upstream token construction, and delegation chain examples accordingly. Replaced the "sub-agent calls a chained resource" example with "sub-agent inside a chain."

- draft-hardt-oauth-aauth-protocol-04
  - Auth tokens: replaced `act.sub` with `act.agent` within each `act` node; see [issue #47](https://github.com/dickhardt/AAuth/issues/47).

- draft-hardt-oauth-aauth-protocol-03
  - Metadata: added a common-fields table at the top of the Metadata Documents section covering all four well-known files; documented intentional RFC 9728 divergences (`issuer` not `resource`; unprefixed field names).
  - Metadata: added `documentation_uri` to `aauth-agent.json`, `aauth-person.json`, and `aauth-access.json`.
  - Interaction code: updated Crockford base32 citation to `[@?I-D.crockford-davis-base32-for-humans]`.

- draft-hardt-oauth-aauth-protocol-02
  - Added sub-agents: agent token `parent_agent` claim, single-level depth, parent-mediated authorization with a `subagent_token` parameter, and the `+` sub-agent local-part delimiter; registered `parent_agent` in the JWT Claims registry.
  - Renamed the terminal `interaction_required` error to `user_unreachable`; added `interaction_unavailable` (424) and PS-first interaction relay; clarified completion polling for resource-hosted interactions; added the `max_wait` interaction parameter.
  - Added `capabilities` and OIDC `prompt` request parameters to the PS token endpoint.
  - Added `requirement=agent-token` (`401`); ordered the resource-access challenge sections weakest-to-strongest.
  - Added an `access_mode` resource-metadata field, a "Drop-In Replacement for API Keys and OAuth" section, and a "Consuming a Resource End to End" walkthrough; relaxed `jwks_uri` to be required only when the resource issues resource tokens or makes signed calls.
  - Added an OPTIONAL Markdown `description` field to each well-known metadata document.
  - Metadata: require the returned `issuer` to match the URL it was fetched from.
  - Call chaining: clarified that the intermediary signs with its own key and `upstream_token` is a body parameter.
  - Added rationale for the mandated covered components in the HTTP Message Signatures profile.
  - Added a Security Consideration on non-repudiation after key rotation; clarified that the agent token is AAuth's minimum credential (identity Signature-Key schemes only; pseudonym `hwk`/`jkt-jwt` not an AAuth mode).
  - Bootstrapping: pointer to the AAuth Bootstrap document; resources SHOULD publish `access_mode` and an R3 vocabulary.
  - Diagrams: use snake_case `agent_token` and `auth_token`.
  - Named the `{approver, s256}` pair the "mission reference" and used it consistently for the `mission` claim in resource and auth tokens, distinct from the full mission blob.
  - Stated that AAuth never conveys its own requirements via `WWW-Authenticate`, leaving a resource's existing challenges available alongside `AAuth-Requirement`.
  - Specified the interaction `code` format: Crockford base32 alphabet, ≥40 bits of entropy, presentational hyphens stripped before case-insensitive comparison, single use, mandatory rate-limiting, and expiry bound to the pending interaction; documented the entropy/rate-limit rules as the brute-force defense in Interaction Code Misdirection and made the four `code` examples consistently hyphenated.
  - Editorial consistency pass: trimmed redundant mode walkthroughs, removed the empty "Clarification Flow" subsection, and added distinct anchors to the appendix flow diagrams.

- draft-hardt-oauth-aauth-protocol-01
  - Renamed PS-managed access to PS-asserted access throughout, reflecting the trust posture: the resource accepts identity claims and consent from the agent's PS while applying its own access policy.
  - Renamed Agent Server to Agent Provider (AP) throughout, including in agent identifier definition, well-known metadata, and IANA registrations.
  - Added Roles section describing collocation patterns (PS+AS, Resource+Agent, AP+Resource, Agent+AP, org-wide bundles).
  - Added Policy Evaluation Points section describing how AP, PS, AS, and Resource each evaluate the agent from their own vantage point.
  - Added PS-AS Collapse subsection distinguishing it from three-party access.
  - Added Trust Posture in PS-Asserted Access security section.
  - Added optional `platform` request parameter (with new IANA AAuth Platform Value Registry: `web`, `mobile`, `desktop`, `workload`, `self-hosted`) and `device` request parameter at the PS token endpoint, both agent-attested and used for display at the consent screen and connected-agents dashboard.
  - Replaced ad hoc `org` references with the `tenant` claim from OpenID Connect Enterprise Extensions; added `tenant` as an optional auth token claim.
  - Consistency pass: identity-based access now requires an agent token (collapsed agent adoption path from 4 to 3 steps); audit's mission requirement no longer hidden by the "missions, permissions, audit" shorthand; `capabilities` array on mission approval is "MAY include"; `ps` claim in agent token is "MUST include" for three-party and above; auth token usage clarified (agent presents auth token, not agent token, on subsequent requests to a resource).
  - Demoted the AAuth Bootstrap reference from normative to informative.

- draft-hardt-oauth-aauth-protocol-00
  - Initial draft. Replaces [draft-hardt-aauth-protocol-02](https://datatracker.ietf.org/doc/draft-hardt-aauth-protocol/02/); no technical changes.

# Acknowledgments

The author would like to thank reviewers for their feedback on concepts and earlier drafts, and contributors who raised issues and pull requests: Aaron Parecki, Ben McAdams, Christian Posta, Danny Fuhriman, Dasith Wijesiriwardena, Frederik Krogsdal Jacobsen, He Gu, Jared Hanson, Jeoffrey Haeyaert, João André Marques, Joshua Gay, Karl McGuinness, Ken Huang, Lukas Friman, Mark Hendrickson, Mayur Agnihotri, Nate Barbettini, Nick Gamb, Paul Carleton, Rohan Harikumar, Sanjay Dalal, Scott Motte, Wils Dawson, Zeeshan Khan.

{backmatter}

# Detailed Flows {#detailed-flows}

This appendix provides flow diagrams for the chaining patterns defined in the main specification, where the choreography is hard to follow from prose alone.

## Four-Party: Call Chaining {#flow-call-chaining}

See (#call-chaining) for normative requirements. Resource 1 acts as an agent, sending the downstream resource token plus its own agent token and the upstream auth token to the PS.

~~~ ascii-art
Agent        Resource 1       Resource 2          PS
  |              |                |                 |
  | HTTPSig w/   |                |                 |
  | auth_token   |                |                 |
  |------------->|                |                 |
  |              |                |                 |
  |              | HTTPSig w/     |                 |
  |              | R1 person_token|                 |
  |              |--------------->|                 |
  |              |                |                 |
  |              | 401            |                 |
  |              | + resource_tok |                 |
  |              |<---------------|                 |
  |              |                |                 |
  |              | POST auth_token_endpoint         |
  |              | resource_token from R2           |
  |              | upstream_token                   |
  |              | agent_token (R1's)               |
  |              |--------------------------------->|
  |              |                |                 |
  |              |                | [PS federates   |
  |              |                |  with R2's AS]  |
  |              |                |                 |
  |              | auth_token for R2                |
  |              |<---------------------------------|
  |              |                |                 |
  |              | HTTPSig w/     |                 |
  |              | auth_token     |                 |
  |              |--------------->|                 |
  |              |                |                 |
  |              | 200 OK         |                 |
  |              |<---------------|                 |
  |              |                |                 |
  | 200 OK       |                |                 |
  |<-------------|                |                 |
~~~

## Interaction Chaining {#flow-interaction-chaining}

See (#interaction-chaining) for normative requirements. When the PS requires user interaction for the downstream access, Resource 1 chains the interaction back to the original agent.

~~~ ascii-art
User      Agent       Resource 1      Resource 2    PS
  |         |              |               |          |
  |         | HTTPSig req  |               |          |
  |         |------------->|               |          |
  |         |              |               |          |
  |         |              | HTTPSig req   |          |
  |         |              | (as agent)    |          |
  |         |              |-------------->|          |
  |         |              |               |          |
  |         |              | 401           |          |
  |         |              | + resource_tok|          |
  |         |              |<--------------|          |
  |         |              |               |          |
  |         |              | POST token_ep |          |
  |         |              | resource_tok, |          |
  |         |              | upstream_tok, |          |
  |         |              | agent_tok     |          |
  |         |              |------------------------->|
  |         |              |               |          |
  |         |              | 202 Accepted  |          |
  |         |              | interaction   |          |
  |         |              |<-------------------------|
  |         |              |               |          |
  |         | 202 Accepted |               |          |
  |         | interaction  |               |          |
  |         | code="MNOP"  |               |          |
  |         |<-------------|               |          |
  |         |              |               |          |
  | direct to R1 {url}     |               |          |
  |<--------|              |               |          |
  |         |              |               |          |
  | R1 redirects to PS     |               |          |
  |----------------------->|               |          |
  | PS {url}?code={code}   |               |          |
  |<-----------------------|               |          |
  |         |              |               |          |
  | authenticate and consent               |          |
  |-------------------------------------------------->|
  |         |              |               |          |
  | redirect to R1 callback                |          |
  |<--------------------------------------------------|
  |         |              |               |          |
  |         |         [R1 polls PS,        |          |
  |         |          gets auth_token]    |          |
  |         |              |               |          |
  |         |              | HTTPSig w/    |          |
  |         |              | auth_token    |          |
  |         |              |-------------->|          |
  |         |              |               |          |
  |         |              | 200 OK        |          |
  |         |              |<--------------|          |
  |         |              |               |          |
  | redirect to agent callback             |          |
  |<-----------------------|               |          |
  |         |              |               |          |
  | callback|              |               |          |
  |-------->|              |               |          |
  |         |              |               |          |
  |         | GET /pending |               |          |
  |         |------------->|               |          |
  |         |              |               |          |
  |         | 200 OK       |               |          |
  |         |<-------------|               |          |
~~~

# Design Rationale

## Identity and Foundation

### Why HTTPS-Based Agent Identity

HTTPS URLs as agent identifiers enable dynamic ecosystems without pre-registration.

### Why Per-Instance Agent Identity

OAuth's `client_id` identifies an application — every instance of the same app shares a single identifier and typically a single set of credentials. AAuth's `aauth:local@domain` agent identifier identifies a specific instance with its own signing key. This enables per-instance authorization (grant access to this specific agent process, not all instances of the app), per-instance revocation (revoke one compromised instance without affecting others), and per-instance audit (trace every action to the specific instance that performed it). The agent provider controls which instances receive agent tokens, providing centralized governance over a distributed agent fleet.

### Why Agents Are Under an Agent Provider

Placing agents under an agent provider rather than allowing each agent to self-certify its own identity serves two purposes. First, **scale**: a single agent provider can issue, rotate, and revoke agent tokens across a fleet of thousands of instances. Resources and PSes verify agent tokens by fetching the AP's JWKS — one trust anchor for all agents from that provider — rather than performing individual key management with each instance. Second, **policy enforcement**: the AP is a natural PEP for agents. It controls which agent instances receive tokens, what identity claims they carry, and when tokens are denied or revoked. An agent that is also its own AP would bypass this layer entirely, eliminating the governance point without gaining anything: the protocol complexity increases while the security properties weaken. AAuth therefore requires every agent to hold a token issued by a distinct AP, not self-signed.

### Why Every Agent Has a Person

Every agent acts on behalf of a person — the entity accountable for the agent's actions. AAuth enables a person server to maintain this link, making it visible and enforceable across the protocol. When present, the PS ensures there is always an accountable party for authorization decisions, audit, and liability.

### Why Person Tokens

An agent identifier embeds its agent provider's domain, so a person moving to another provider necessarily arrives at a resource as someone new, losing whatever state the resource held for them. The person is the party the resource has a relationship with — the account, the history, and any standing limits are theirs — and keying on `(iss, sub)` makes that relationship survive the change. It also keeps agent providers from becoming gatekeepers: a resource that never learns which agent product is calling cannot condition access on it.

Identifying the person at the authorization endpoint rather than after authorization also lets the resource decide before it commits. Account selection (#account-binding), standing policy for that person, and any per-person limit are all evaluable when the request arrives, instead of after a resource token has been issued and taken to a PS.

### Why a Mission Belongs to an Agent

A person's relationship with a resource survives their changing agents, but a mission does not: it names one agent, and moving to another means proposing a new mission. The two are different things with different lifetimes. `sub` identifies the person, durably, because the resource's account and history are theirs. A mission is a grant of latitude to one agent to pursue one piece of work, and the person server evaluates every request against the record of what that agent has already done under it. Carrying that record across a change of agent would attribute one agent's history to another.

The practical effect is that anything done under a mission identifier was done by the agent the mission names, which is what makes the mission log worth reading.

### Why No Agent Identifier Reaches a Resource

Naming the agent, or its provider, in a token the resource reads would restore exactly the coupling the person token exists to remove: a resource able to see either can pin policy to it, and the person's relationship stops surviving a change of agent. So neither the person token, the resource token, nor the auth token carries one. `agent_jkt` and `cnf` still bind every request to one key.

The agent token still reaches the AS, because a resource deploys an AS to have policy evaluated and an agent token MAY carry claims bearing on that — attestation, platform integrity, workload identity. The resource enforces; the AS evaluates; posture goes to the evaluator. The consequence is that agent-provider independence is complete in three-party and partial in four-party, where the resource has explicitly delegated policy to an AS.

### Why Identity Alone Can Authorize

A person token carries no authorization, yet a resource in person-identity mode (#overview-person-identity) serves requests on it. That is not a contradiction: the person server has authorized nothing, and the resource has decided that knowing the person is enough — the same decision it makes after a login it ran itself. Signing in to a site with an identity provider gets whatever that site gives signed-in people, and no one describes the identity assertion as an authorization.

What follows is that issuing a person token is consequential even though it grants nothing. The person server is deciding that this agent may act at this resource as this person, bounded by whatever that resource does on identity. That is why the question put to the person at first issuance is about acting, not naming, and why a person server should know what the resource does with identity before it asks.

### Why the Mission Is Encoded Rather Than Nested

The approval response carries the mission blob base64url-encoded rather than as a JSON object so that `s256` has an unambiguous byte sequence to cover. A nested object has no defined serialization once it is inside an envelope — the receiver would have to re-serialize it to hash it, and any difference in key order, whitespace, or escaping produces a different digest. Encoding makes the string itself the bytes, so the agent decodes, hashes, and compares, which is the operation it already performs on a JWT payload.

An earlier revision avoided the problem by making the response body the mission and putting `s256` in a header, which worked but left no room in the response for anything else. The encoded member restores that room without giving up verifiability.

### Why the Mission Identifier Is a Hash

An opaque identifier would name the mission but leave the person server free to attach it to different text afterwards. A digest binds every token carrying `mission_s256` to one specific mission, so the mission in the log and the mission those tokens authorized are demonstrably the same. Verification is available to the agent at approval and to anyone holding the blob later.

### Why a Resource Token Names the Person Token {#why-presented-jti}

Binding by `presented_jti` rather than by comparing claims is what makes mission stripping detectable. A resource cannot drop `mission_s256` and present the result as an unscoped request, because the person server resolves the person token it actually issued and compares. Comparing claims alone cannot work: an agent running concurrent missions holds several person tokens for the same resource, so "the person token issued for this agent and resource" does not identify one, and a resource that omitted `mission_s256` could not be caught. Naming the token resolves it exactly, and the person server compares everything it issued in one lookup.

### Why Tool Pre-Approval Is Not Enforced {#why-tools-are-not-enforced}

Tool use is local to the agent. No party the protocol can hold to account observes it, so `approved_tools` is a record of what the person agreed to rather than a control that stops anything. Its value is that a departure from it is visible afterwards, in the mission log and in what the agent reports to the audit endpoint.

The enforcement that does exist sits outside the protocol and is worth naming: the runtime that decides whether to call a tool is built by the agent provider, and the agent provider attests the agent. A person's leverage over local actions is therefore their choice of agent provider, not the tool list. The auth token is the only hard control AAuth offers, and it covers remote resources.

### Why There Is No Delegation Chain Claim

Earlier revisions recorded the upstream chain in an `act` claim. It served no reader. The immediate caller in a chain signs the request with its own key and presents its own credentials, so a downstream resource already knows who is calling; `act` named the parties one and two hops further up, which the downstream has no relationship with and cannot evaluate. Those parties are also the person's tooling, disclosed to a resource that did not need them.

The chain is held by the person server, which authorizes every hop and holds the mission log. The same reasoning that made the resource stop attributing missions makes it stop recording delegation: the resource enforces, the person server attributes.

### Why the `ps` Claim in Agent Tokens

A resource learns the agent's PS from the person token it verifies, but it needs to know the agent has one before that — to decide whether to challenge for a person token at all, and to know that the `auth-token` flow is available. The `ps` claim in the agent token provides that, separately from mission governance.

## Protocol Mechanics

### Why `.json` in Well-Known URIs

AAuth well-known metadata URIs use the `.json` extension (e.g., `/.well-known/aauth-agent.json`) rather than the extensionless convention used by OAuth and OpenID Connect. The `.json` extension makes the content type immediately obvious — no content negotiation is needed. More importantly, it enables static file hosting: a `.json` file served from GitHub Pages, S3, or a CDN works without server-side configuration. This aligns with AAuth's self-hosted agent model (see [@?I-D.hardt-aauth-bootstrap]), where an agent's metadata can be published as static files with no active server.

### Why Standard HTTP Async Pattern

AAuth uses standard HTTP async semantics (`202 Accepted`, `Location`, `Prefer: wait`, `Retry-After`). This applies uniformly to all endpoints, aligns with RFC 7240, replaces OAuth device flow, supports headless agents, and enables clarification chat.

### Why JSON Instead of Form-Encoded

JSON is the standard format for modern APIs. AAuth uses JSON for both request and response bodies.

### Why No Authorization Code

AAuth eliminates authorization codes entirely. OAuth authorization codes require PKCE ([@RFC7636]) to prevent interception attacks, adding complexity for both clients and servers. AAuth avoids the problem: the user redirect carries only the callback URL, which has no security value to an attacker. The auth token is delivered exclusively via polling, authenticated by the agent's HTTP Message Signature.

### Why Callback URL Has No Security Role

Tokens never pass through the user's browser. The callback URL is purely a UX optimization.

### Why No Refresh Token

AAuth has no refresh tokens. When an auth token expires, the agent obtains a fresh resource token and submits it through the standard authorization flow. This gives the resource a voice in every re-authorization — the resource can adjust scope, require step-up authorization, or deny access based on current policy. A separate refresh token would bypass the resource entirely, and is unnecessary given that the standard flow is a single additional request.

### Why Reuse OpenID Connect Vocabulary

AAuth reuses OpenID Connect scope values, identity claims, and enterprise parameters. This lowers the adoption barrier.

## Architecture

### Why a Separate Person Server

The PS is distinct from the AS because they serve different parties with different concerns. The PS represents the agent and its user — it handles consent, identity, mission governance, and audit. The AS represents the resource — it evaluates policy and issues tokens. Combining these into a single entity would conflate the interests of the requesting party with the interests of the resource owner, which is the same conflation that makes OAuth insufficient for cross-domain agent ecosystems.

### Why Five Resource Access Modes

The modes are not levels of protocol adoption but answers to one question: what does the resource need to know before it serves a request? A resource that only verifies agent signatures can start using AAuth today without deploying a PS or AS. One that needs the person can take a person token and decide for itself. One that wants a scope agreed with the person takes an auth token, and one that wants policy evaluated takes it from its own access server. Each mode is self-contained and useful — not a stepping stone to the "real" protocol — and a resource may use different modes on different endpoints, which is the common case: most calls need only identity, and a few sensitive operations warrant an authorization decision.

Resource-managed and person-identity access are kept separate because the difference is who established the person's identity, and that determines what the resource can rely on. In resource-managed access the resource ran its own flow, so it knows the person on its own terms and needs nothing from a person server. In person-identity access it accepts an identity a person server asserted, which is federated login — cheaper for the resource, and dependent on trusting that person server.

Agent governance (missions plus permission, audit, and interaction relay) works independently of all five.

### Why Resource Tokens

In GNAP and OAuth, the resource server is a passive consumer of tokens — it verifies them but never produces signed artifacts. AAuth inverts this: the resource cryptographically asserts what is being requested by issuing a resource token that binds the resource's own identity, the agent's key thumbprint, the requested scope, and the mission context into a single signed JWT. This prevents confused deputy attacks — an attacker cannot substitute a different resource in the authorization flow because the resource token is signed by the resource. It also gives the resource a voice in every authorization and re-authorization, and provides a complete audit artifact linking the request to a specific resource, agent, scope, and mission.

### Why Session Tokens Are Opaque

In two-party mode, the resource returns an opaque wrapped token via the `AAuth-Access` header rather than a JWT auth token. This allows the resource to wrap its existing authorization infrastructure (OAuth access tokens, session tokens, etc.) without exposing internal structure. The token is bound to the AAuth signature — the agent includes it in the `Authorization` header as a covered component — so it cannot be stolen and replayed as a standalone bearer token.

### Why Missions Are Not a Policy Language

Missions are intentionally not a machine-evaluable policy language. AAuth separates two kinds of authorization decisions:

- **Deterministic policy** is handled by scopes, resource tokens, and AS policy evaluation. These are mechanically evaluable — "does this agent have `data.read` scope for this resource?" A policy engine (Cedar, OPA/Rego, or any other) can answer this question consistently and automatically.

- **Contextual governance** is handled by missions, justifications, and clarification at the PS. These are the contextual decisions that policy engines cannot answer — "is booking a $10,000 flight reasonable for planning a weekend trip?" or "should this agent access the HR database given what it's trying to accomplish?" The mission description, the agent's justification for each resource access, and the clarification dialog between user and agent provide the context for these decisions.

Prior attempts to make authorization semantics machine-evaluable across domains have not scaled. OAuth Rich Authorization Requests (RAR) require clients and servers to agree on domain-specific `type` values and JSON structures — workable within a single API but combinatorially explosive across arbitrary services. UMA attempted cross-domain resource sharing with machine-readable permission tickets, but adoption stalled because resource owners, requesting parties, and authorization servers could not converge on shared semantics for what permissions meant across organizational boundaries. The fundamental problem is that the meaning of "appropriate access" is contextual, evolving, and domain-specific — it cannot be captured in a predefined vocabulary that all parties share.

Missions solve this differently. Rather than requiring all parties to agree on machine-evaluable semantics, AAuth concentrates governance evaluation at the PS — the only party with full context. The PS has the mission description, the user's identity and organizational context, the agent's justification for each request, the history of what the agent has done so far, and a channel to the user for clarification. No other party in the protocol has this context, and no predefined policy language can substitute for it.

This context can be presented to humans or to agents acting as decision-makers. The PS does not need to evaluate missions deterministically — it presents the mission context, the justification, and the resource request to whatever decision-maker is appropriate: a human reviewing a consent screen, an AI agent evaluating policy on behalf of an organization, or an automated system applying heuristics. As AI decision-making matures, governance can shift from human review to agent evaluation — without changing the protocol. AAuth standardizes how context is conveyed to the decision-maker; it does not prescribe how the decision is made.

The mission's `description` is Markdown because it represents human intent, not machine policy. The `approved_tools` array provides structured machine-evaluable elements where appropriate. Resources and access servers do not need the mission content — they enforce their own deterministic policies independently. The mission is a further restriction applied by the PS, and only the PS has sufficient context to evaluate it. Distributing mission semantics to other parties would be both a privacy leak and a false promise of enforcement, since those parties lack the context to evaluate the mission meaningfully.

### Why Missions Have Only Two States

Missions are either **active** or **terminated**. There is no suspended state. An `expires_at` in the mission blob does not add a state — it declares in advance when the PS will treat the mission as terminated, which the person can see at approval time. A suspended state would require the agent to learn that the mission has resumed, but AAuth has no push channel from the PS to the agent — the agent can only poll. For short pauses (minutes), the deferred response mechanism already provides natural waiting via `202` polling. For long pauses (hours or more), the agent would need to poll indefinitely with no indication of when to stop, making suspension operationally equivalent to termination. Terminating the mission and creating a new one is cleaner — the PS retains the old mission's log for audit, and the new mission can be scoped appropriately for the changed circumstances that prompted the pause. This keeps mission lifecycle simple: a mission is alive until it is done.

### Why Downstream Scope Is Not Constrained by Upstream Scope

In multi-hop scenarios, downstream authorization is intentionally not required to be a subset of upstream scopes. A flight booking API that calls a payment processor needs the payment processor to charge a card — an operation orthogonal to the upstream scope. Formal subset rules would prevent legitimate delegation chains. Instead, the PS evaluates each hop against the mission context, providing governance-based constraints that are more flexible than algebraic attenuation rules while maintaining a complete audit trail.

## Comparisons with Alternatives

### Why Not mTLS?

Mutual TLS (mTLS) authenticates the TLS connection, not individual HTTP requests. Different paths on the same resource may have different requirements — some paths may require no signature, others a signed request, others verified identity, and others an auth token. Per-request signatures allow resources to vary requirements by path. Additionally, mTLS requires PKI infrastructure (CA, certificate provisioning, revocation), cannot express progressive requirements, and is stripped by TLS-terminating proxies and CDNs. mTLS remains the right choice for infrastructure-level mutual authentication (e.g., service mesh). AAuth addresses application-level identity where progressive requirements and intermediary compatibility are needed.

### Why Not DPoP?

DPoP ([@RFC9449]) binds an existing OAuth access token to a key, preventing token theft. AAuth differs in that agents can establish identity from zero — no pre-existing token, no pre-registration. The agent signs with its own agent token (#agent-tokens), which it obtains from its agent provider without any resource-side registration; no resource- or AS-issued token is needed to make the first identified call. DPoP has a single mode (prove you hold the key bound to this token), while AAuth supports progressive requirements from verified agent identity through authorized access with interactive consent. DPoP is the right choice for adding proof-of-possession to existing OAuth deployments.

### Why Not Extend GNAP

GNAP ([@RFC9635]) shares several motivations with AAuth — proof-of-possession by default, client identity without pre-registration, and async authorization. A natural question is whether AAuth's capabilities could be achieved as GNAP extensions rather than a new protocol. There are several reasons they cannot.

**Resource tokens require an architectural change, not an extension.** In GNAP, as in OAuth, the resource server is a passive consumer of tokens — it verifies them but never produces signed artifacts that the access server consumes. AAuth's resource tokens invert this: the resource cryptographically asserts what is being requested, binding its own identity, the agent's key thumbprint, and the requested scope into a signed JWT. Adding this to GNAP would require changing its core architectural assumption about the role of the resource server.

**Interaction chaining requires a different continuation model.** GNAP's continuation mechanism operates between a single client and a single access server. When a resource needs to access a downstream resource that requires user consent, GNAP has no mechanism for that consent requirement to propagate back through the call chain to the original user. Supporting this would require rethinking GNAP's continuation model to support multi-party propagation through intermediaries.

**The federation model is fundamentally different.** In GNAP, the client must discover and interact with each access server directly. AAuth's model — where the agent only ever talks to its PS, and the PS federates with resource ASes — is a different trust topology, not a configuration option. Retrofitting this into GNAP would produce a profile so constrained that it would be a distinct protocol in practice.

**GNAP's generality is a liability for this use case.** GNAP is designed to be maximally flexible — interaction modes, key proofing methods, token formats, and access structures are all pluggable. This means implementers must make dozens of profiling decisions before arriving at an interoperable system. AAuth makes these decisions prescriptively: one token format (JWT), one key proofing method (HTTP Message Signatures), one interaction pattern (interaction codes with polling), and one identity model (`local@domain` with HTTPS metadata). For the agent-to-resource ecosystem, this prescriptiveness is a feature — it enables interoperability without bilateral agreements.

In summary, AAuth's core innovations — resource-signed challenges, interaction chaining through multi-hop calls, PS-to-AS federation, mission-scoped authorization, and clarification chat during consent — are architectural choices that would require changing GNAP's foundations rather than extending them. The result would be a heavily constrained GNAP profile that shares little with other GNAP deployments.

### Why Not Extend WWW-Authenticate?

`WWW-Authenticate` ([@!RFC9110], Section 11.6.1) tells the client which authentication scheme to use. Its challenge model is "present credentials" — it cannot express progressive requirements, authorization, or deferred approval, and it cannot appear in a `202 Accepted` response.

`AAuth-Requirement` and `Accept-Signature` coexist with `WWW-Authenticate`. A `401` response MAY include multiple headers, and the client uses whichever it understands:

```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer realm="api"
Accept-Signature: sig=("@method" "@authority" "@path");sigkey=uri
```

A `402` response MAY include `WWW-Authenticate` for payment (e.g., the Payment scheme defined by the Micropayment Protocol ([@!I-D.ryan-httpauth-payment])) alongside `Accept-Signature` for authentication or `AAuth-Requirement` for authorization:

```http
HTTP/1.1 402 Payment Required
WWW-Authenticate: Payment id="x7Tg2pLq", method="example",
    request="eyJhbW91bnQiOiIxMDAw..."
Accept-Signature: sig=("@method" "@authority" "@path");sigkey=jkt
```

### Why Not Extend OAuth?

OAuth 2.0 ([@!RFC6749]) was designed for delegated access — a user authorizes a pre-registered client to act on their behalf at a specific server. Extending OAuth for agent-to-resource authorization would require changing its foundational assumptions:

- **Client identity**: OAuth clients have no independent identity. A `client_id` is issued by each authorization server — it is meaningless outside that relationship. AAuth agents have self-sovereign identity (`aauth:local@domain`) verifiable by any party.
- **Pre-registration**: OAuth requires clients to register with each authorization server before use. AAuth agents call resources they have never contacted before — the first API call is the registration.
- **Bearer tokens**: OAuth access tokens are bearer credentials — anyone who holds the token can use it. AAuth binds every token to a signing key via HTTP Message Signatures — a stolen token is useless without the private key.
- **No resource identity**: OAuth does not cryptographically identify the resource. AAuth resources sign resource tokens, binding their identity to the authorization flow.
- **No governance layer**: OAuth has no concept of missions, permission endpoints, audit logging, or interaction relay. These would need to be built on top as extensions, losing the coherence of a protocol designed around them.
- **No federation model**: OAuth's authorization server is always the resource owner's server. AAuth separates the person server (user's choice) from the access server (resource's choice) and defines how they federate.

The Model Context Protocol (MCP) illustrates these limitations. MCP adopted OAuth 2.1 for agent-to-server authorization and immediately needed Dynamic Client Registration ([@RFC7591]) because agents cannot pre-register with every server. But Dynamic Client Registration gives the agent a different `client_id` at each server — the agent still has no portable identity. Tokens are bearer credentials, so a stolen token grants full access. There is no resource identity — the server does not cryptographically prove who it is. There is no governance layer — no missions, no permission management, no audit trail. And the entire authorization model is per-server: each MCP server has its own authorization server, and the agent must discover and register with each one independently. MCP's experience demonstrates that OAuth can be made to work for the first API call, but it cannot provide the identity, governance, and federation that agents need as they operate across trust domains.

Rather than layer these changes onto OAuth — which would break backward compatibility and produce something unrecognizable — AAuth is a new protocol designed for the agent model from the ground up. AAuth complements OAuth: resources can wrap existing OAuth infrastructure behind the AAuth-Access token, and PSes can delegate user authentication to OpenID Connect providers.
