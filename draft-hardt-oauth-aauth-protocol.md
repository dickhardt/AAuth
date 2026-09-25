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

Every agent instance has its own identifier and signing key, and every request it makes is bound to that key by an HTTP Message Signature ([@!RFC9421]): no credential is a bearer credential, and none needs pre-registration, so the first API call to a resource is the registration. A person server represents the person — asserting who the agent acts for, managing consent and missions, relaying interactions and payments, and recording what the agent did — and federates with the access servers that guard resources across trust domains. Each party adopts independently. Asynchronous event delivery to agents is defined in AAuth Events ([@?I-D.hardt-aauth-events]).

The HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]) defines how signing keys are bound to JWTs and discovered via well-known metadata, and how agents present cryptographic identity using HTTP Message Signatures ([@!RFC9421]). This specification defines the `AAuth-Requirement`, `AAuth-Access`, and `AAuth-Capabilities` headers, and the authorization protocol across five resource access modes.

Because agent identity is independent and self-contained, AAuth is designed for incremental adoption: each party can add support independently, and rollout does not need to be coordinated. A resource that verifies an agent's signature can manage access by identity alone, with no other infrastructure; adding a person server and an access server is additive. The five resource access modes are introduced in (#protocol-overview) and the adoption path in (#incremental-adoption).

## Built On

AAuth builds on existing standards and design patterns:

- **OpenID Connect vocabulary**: AAuth reuses OpenID Connect scope values, identity claims, and enterprise extensions ([@OpenID.Enterprise]), lowering the adoption barrier for identity-aware resources.
- **Well-known metadata and key discovery**: Servers publish metadata at well-known URLs ([@!RFC8615]) and signing keys via JWKS endpoints, following the pattern established by OAuth Authorization Server Metadata ([@RFC8414]) and OpenID Connect Discovery ([@OpenID.Core]).
- **HTTP Message Signatures**: All requests are signed with HTTP Message Signatures ([@!RFC9421]) using keys bound to tokens conveyed via the Signature-Key header ([@!I-D.hardt-httpbis-signature-key]), providing proof-of-possession, identity, and message integrity on every call.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

In HTTP examples throughout this document, line breaks and indentation are added for readability. Actual HTTP messages do not contain these extra line breaks. Examples of signed requests show the `Signature-Key` header and omit the `Signature-Input`, `Signature`, and `Content-Digest` headers that every signed request carries; the fully bound form is shown in (#aauth-access) and (#covered-components).

# Terminology

Parties:

- **Person**: A user or organization — the legal person — on whose behalf an agent acts and who is accountable for the agent's actions.
- **Agent**: An HTTP client ([@!RFC9110], Section 3.5) acting on behalf of a person. Identified by an agent identifier URI using the `aauth` scheme, of the form `aauth:local@domain` (#agent-identifiers). An agent MAY have a person server, declared via the `ps` claim in the agent token.
- **Agent Provider (AP)**: A server that manages agent identity and issues agent tokens to agents. Trusted by the person to issue agent tokens only to authorized agents.
- **Resource**: A server that requires authentication and/or authorization to protect access to its APIs and data. A resource MAY enforce access policy itself or delegate policy evaluation to an access server.
- **Person Server (PS)**: A server that represents the person to the rest of the protocol. The person chooses their PS; it is not imposed by any other party. The PS manages missions, handles consent, asserts user identity, and brokers authorization on behalf of agents.
- **Access Server (AS)**: A policy engine that evaluates token requests, applies resource policy, and issues auth tokens on behalf of a resource.
- **Supervisor**: The party that performs supervision — the Person by default, or a supervision server (SS) the PS delegates to (#roles).

Each server role is identified by an HTTPS URL (#server-identifiers) and publishes metadata at its well-known URL (#metadata-documents).

Tokens:

- **Agent Token**: Issued by an agent provider to establish the agent's identity. MAY declare the agent's person server (#agent-tokens).
- **Person Token**: Issued by a PS to identify the person an agent acts for, to one resource, before any authorization exists. Carries identity and no authorization (#person-tokens).
- **Resource Token**: Issued by a resource to describe the access the agent needs (#resource-tokens).
- **Auth Token**: Issued by a PS or AS to grant an agent access to a resource, containing identity claims and/or authorized scopes (#auth-tokens).
- **Session Token**: Issued by a resource to an agent when the resource manages authorization itself. Opaque to the agent, carried in the `AAuth-Access` header and presented back via `Authorization: AAuth` (#aauth-access).

Protocol concepts:

- **Mission**: A scoped authorization context for agent governance (#missions). Required when the person's PS requires governance over the agent's actions. A mission is a JSON object containing structured fields (agent, approved_at, approved tools) and a Markdown description. Identified by the PS that approved it and the SHA-256 hash of the mission JSON (`s256`). Missions are proposed by agents and approved by the PS and person.
- **Mission Log**: The ordered record of all agent↔PS interactions within a mission — token requests, permission requests, audit records, interaction requests, and clarification chats. The PS maintains the log and uses it to evaluate whether each new request is consistent with the mission's intent (#mission-log).
- **Supervision**: The evaluation of one act — a token request, a permission request, a mission update — against the mission's intent, the prior log entries, and the person's policy (#policy-evaluation-points). Governance names the layer: missions plus permission, audit, and interaction relay. Supervision names the decision made within it, and the Supervisor makes it.
- **HTTP Sig**: An HTTP Message Signature ([@!RFC9421]) created per the AAuth HTTP Message Signatures profile defined in this specification (#http-message-signatures-profile), using a key conveyed via the `Signature-Key` header ([@!I-D.hardt-httpbis-signature-key]).
- **Markdown**: AAuth uses Markdown ([@CommonMark]) as the human-readable content format for mission descriptions, justifications, clarifications, and scope descriptions. Implementations MUST sanitize Markdown before rendering to users. **Editor's note:** recommended section structures for the Markdown-valued parameters of this document (mission descriptions, updates, and completion summaries; justifications; clarifications and clarification responses; permission, audit, and interaction descriptions) are to be defined together in a later revision, so that they are consistent across parameters.
- **Interaction**: User authentication, consent, or other action at an interaction endpoint (#user-interaction). Triggered when a server returns `202 Accepted` with `requirement=interaction`.
- **Justification**: A Markdown string provided by the agent declaring why access is needed, presented to the user by the PS during consent (#ps-token-endpoint).
- **Clarification**: A Markdown string containing a question posed to the agent by the user during consent via the PS (#clarification-chat). The agent may respond with an explanation or an updated request.

# Protocol Overview

An agent holds a signing key and an agent token that binds the key to its identifier. Every request the agent makes is signed with that key, and every other token it obtains is bound to the same key. All AAuth tokens are JWTs, verified with a key from the issuer's JWKS, which is discovered from the issuer's well-known metadata (#aauth-tokens). This section shows how the parties fit together; the sections that follow define each part.

## Obtaining an Agent Token

The agent generates a signing key pair and proves its identity to its agent provider through a platform-specific mechanism ([@?I-D.hardt-aauth-bootstrap]). The agent provider issues an agent token binding the key to the agent's identifier (#agent-tokens). The agent token MAY carry a `ps` claim naming the agent's person server.

## Resource Access Modes {#resource-access-modes}

AAuth supports five resource access modes. They differ in what the resource ends up knowing and which party established it, not in how much of the protocol they use. A resource MAY apply different modes to different endpoints.

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
                    /---------------\
                   |      Person     |
                    \---------------/
                      ^           ^
              mission |           | consent
                      v           v
                     +--------------+                   +--------------+
                     |              |    federation     |              |
                     |   Person     |------------------>|   Access     |
                     |   Server     |<------------------|   Server     |
                     |              |    auth token     |              |
                     +--------------+                   +--------------+
                      ^          ^ |
            mission   |   signed | | person token
                      |  request | | or auth token
                      v          | v
              agent  +--------------+  signed request   +--------------+
+-----------+ token  |              |------------------>|              |
|  Agent    |------->|    Agent     |<------------------|   Resource   |
|  Provider |        |              | resource response |              |
+-----------+        +--------------+ or resource token +--------------+

~~~
Figure: Protocol Parties and Relationships {#fig-parties}

- **Agent Provider → Agent**: Issues an agent token binding the agent's signing key to its identity (#agent-tokens).
- **Agent ↔ Resource**: Agent sends signed requests; the resource returns responses, or a resource token when authorization is needed (#resource-tokens).
- **Agent ↔ PS**: Agent obtains person tokens and auth tokens, and with governance creates missions and requests permissions (#person-server).
- **PS ↔ AS**: Federation (four-party only). The PS sends the resource token to the AS; the AS returns an auth token (#access-server-federation).
- **Person ↔ PS**: Mission approval and consent for resource access.

Detailed end-to-end flows are in (#detailed-flows).

### Agent Identity Access {#overview-identity-access}

The agent signs requests with its agent token. The resource verifies the agent's identity and applies its own access control, granting or denying based on who the agent is (#requirement-agent-token). This replaces API keys with cryptographic identity. No authorization flow, no tokens beyond the agent token.

~~~ ascii-art
Agent                                        Resource
  |                                             |
  | HTTP Sig w/ agent_token                     |
  |-------------------------------------------->|
  |                                             |
  | 200 OK                                      |
  |<--------------------------------------------|
~~~
Figure: Identity-Based Access {#fig-identity-access}

The agent identifier reaches a resource only in this mode and in resource-managed access. In the other three, no token the resource reads carries one (#why-no-agent-identifier).

### Resource-Managed Access (Two-Party) {#overview-resource-managed}

The resource handles authorization itself, via its own interaction, existing OAuth or OIDC infrastructure, or internal policy (#resource-managed-auth). After authorization, the resource MAY return an `AAuth-Access` header with a session token for subsequent calls (#aauth-access).

~~~ ascii-art
Agent                                        Resource
  |                                             |
  | HTTP Sig w/ agent_token                     |
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
  | HTTP Sig w/ agent_token                     |
  | Authorization: AAuth session-token          |
  |-------------------------------------------->|
  |                                             |
  | 200 OK                                      |
  |<--------------------------------------------|
~~~
Figure: Resource-Managed Access (Two-Party) {#fig-resource-managed}

### Person Identity Access {#overview-person-identity}

The agent obtains a person token for the resource from its PS (#person-token-endpoint) and signs requests with it in place of its agent token. The resource verifies the token, learns which person the agent acts for, and applies its own access control on that identity. No resource token, no auth token, and the PS is not in the path of any call.

~~~ ascii-art
Agent                                 Resource       PS
  |                                      |            |
  | HTTP Sig w/ agent_token              |            |
  | POST person_token_endpoint           |            |
  |-------------------------------------------------->|
  |                                      |            |
  | person_token (aud = resource)        |            |
  |<--------------------------------------------------|
  |                                      |            |
  | HTTP Sig w/ person_token             |            |
  |------------------------------------->|            |
  |                                      |            |
  | 200 OK                               |            |
  |<-------------------------------------|            |
~~~
Figure: Person Identity Access {#fig-person-identity}

This is federated login for agents. A resource that needs more than identity for a particular operation challenges for it there, with `requirement=auth-token` (#requirement-auth-token), while continuing to serve the rest on the person token.

### PS Authorization Access (Three-Party)

The resource has no access server. It accepts identity and consent asserted by whichever PS issued the person token it verified, and applies its own policy to the claims in the auth token the PS returns (#trust-posture-in-ps-asserted-access). Any PS can assert to any resource without bilateral setup.

~~~ ascii-art
Agent                                 Resource       PS
  |                                      |            |
  | HTTP Sig w/ person_token             |            |
  | POST authorization_endpoint          |            |
  |------------------------------------->|            |
  |                                      |            |
  | resource_token (aud = PS URL)        |            |
  |<-------------------------------------|            |
  |                                      |            |
  | HTTP Sig w/ agent_token              |            |
  | POST auth_token_endpoint             |            |
  | w/ resource_token                    |            |
  | + presented_token                    |            |
  |-------------------------------------------------->|
  |                                      |            |
  | auth_token                           |            |
  |<--------------------------------------------------|
  |                                      |            |
  | HTTP Sig w/ auth_token               |            |
  | GET /api/documents                   |            |
  |------------------------------------->|            |
  |                                      |            |
  | 200 OK                               |            |
  |<-------------------------------------|            |
~~~
Figure: PS Authorization Access (Three-Party) {#fig-ps-asserted}

1. Presenting its person token, the agent requests access at the resource's authorization endpoint, or calls the resource and receives a `401` challenge carrying a resource token (#resource-tokens).
2. The agent sends the resource token to its PS, which returns an auth token (#ps-token-endpoint).
3. The agent presents the auth token to the resource.

### Federated Authorization Access (Four-Party)

The resource has its own access server. The resource token names the AS as its `aud`, and the PS federates with the AS to obtain the auth token (#access-server-federation).

~~~ ascii-art
Agent                                Resource   PS                    AS
  |                                     |       |                      |
  | HTTP Sig w/ person_token            |       |                      |
  | POST authorization_endpoint         |       |                      |
  |------------------------------------>|       |                      |
  |                                     |       |                      |
  | resource_token (aud = AS URL)       |       |                      |
  |<------------------------------------|       |                      |
  |                                     |       |                      |
  | HTTP Sig w/ agent_token             |       |                      |
  | POST auth_token_endpoint            |       |                      |
  | w/ resource_token                   |       |                      |
  | + presented_token                   |       |                      |
  |-------------------------------------------->|                      |
  |                                     |       |                      |
  |                                     |       | HTTP Sig w/ jwks_uri |
  |                                     |       | POST                 |
  |                                     |       | auth_token_endpoint  |
  |                                     |       | w/ resource_token    |
  |                                     |       | + presented_token    |
  |                                     |       |--------------------->|
  |                                     |       |                      |
  |                                     |       | auth_token           |
  |                                     |       |<---------------------|
  |                                     |       |                      |
  | auth_token                          |       |                      |
  |<--------------------------------------------|                      |
  |                                     |       |                      |
  | HTTP Sig w/ auth_token              |       |                      |
  | GET /api/documents                  |       |                      |
  |------------------------------------>|       |                      |
  |                                     |       |                      |
  | 200 OK                              |       |                      |
  |<------------------------------------|       |                      |
~~~
Figure: Federated Access (Four-Party) {#fig-federated}

1. Presenting its person token, the agent requests access at the resource's authorization endpoint, or calls the resource and receives a `401` challenge carrying a resource token (#resource-tokens).
2. The agent sends the resource token to its PS. The PS federates with the AS named by the resource token's `aud` (#ps-as-federation), which returns the auth token to the PS.
3. The PS returns the auth token to the agent, which presents it to the resource.

## Roles {#roles}

Agent, AP, Resource, PS, and AS are **roles**, not deployment units. Each role has its own protocol identity: the Agent by an `aauth:local@domain` URI attested by an agent token, and AP, Resource, PS, and AS each by an HTTPS URL with metadata at that role's well-known path. A single deployment unit MAY fill multiple roles. Server identifiers are scheme and host only (#server-identifiers), so roles hosted under a shared origin share one identifier and are distinguished by the well-known document (`dwk`). The protocol treats each role independently regardless of collocation.

Common collocations:

- **PS + AS**: One server brokers user consent and evaluates resource policy. Federation collapses to a single internal evaluation (#ps-as-collapse).
- **Resource + Agent + AP**: A resource acts as an agent for downstream calls and is its own agent provider (#intermediary-agent-identity).
- **AP + Resource**: An agent provider exposes its own services to the agents it issues tokens to, publishing resource metadata and issuing resource tokens. How the agent obtains the resource token from the agent provider is out of scope.
- **Agent + AP**: A self-hosted agent is its own agent provider, self-issuing agent tokens signed by a key the user controls ([@?I-D.hardt-aauth-bootstrap]).
- **Org-wide bundle**: One organizational server operates AP + PS + AS for employees and internal resources, with federation only at the boundary when an internal agent reaches an external resource.

The **Supervisor** performs supervision (#policy-evaluation-points): the Person by default, or a **supervision server (SS)** the PS MAY delegate to. Supervision is an independent protocol; a companion specification is TBD, and an implementation may treat supervision as internal to the PS. Nothing an agent, resource, or AS sees changes with who supervises.

## Policy Evaluation Points {#policy-evaluation-points}

The Agent is the subject of every policy decision; the four server roles each evaluate the agent's activity from their own vantage point. No single party is the policy decision point.

- **Agent Provider** decides whether to continue treating the agent as authorized, based on device posture, attestation freshness, account status, or any other AP-internal criteria, by issuing or refusing fresh agent tokens.
- **Person Server** decides whether to issue a person token or an auth token, based on user consent and, under a mission, the mission's intent and prior log entries. The Supervisor performs that evaluation.
- **Access Server** decides whether to issue an auth token on behalf of the resource, based on resource policy, the claims the PS has provided, and any further requirements it gathers.
- **Resource** decides what is required when it issues a resource token, and enforces the resulting auth token at the moment of access.

Every token has a limited lifetime, so each issuance is a re-evaluation point for the party that issues it, and revocation (#token-revocation) ends access between them.

## Agent Governance {#agent-governance}

An agent with a person server can be governed by it: through missions, and through the PS's permission, audit, and interaction endpoints (#person-server). An agent that has a person server MUST carry the `ps` claim in its agent token (#agent-token-structure); it is how a resource learns that a person token can be asked for.

Governance of resource access rides on the person token. The agent names its mission when it obtains one, and `mission_s256` flows from there into the resource token and the auth token, so the PS evaluates every token request against the mission. That reaches the resource in the three modes where a person token is presented; in agent identity and resource-managed access the PS is not in the path. The permission and interaction endpoints do not depend on the mode, or on a mission.

### Missions {#missions-overview}

A mission is a Markdown description of what the agent intends to accomplish, proposed by the agent and approved by the person at the PS. It is identified by the `s256` hash of the approved mission, accumulates context through the mission log, and ends when the person accepts the agent's completion proposal. Missions are OPTIONAL. Section (#missions) defines them.

# Agents {#agent-identity}

This section defines agents: the agent provider that issues their identity, the identifier it assigns, and the agent token that binds that identifier to a signing key. Agent identity is the foundation of AAuth: the agent token binds the agent's identifier to its signing key, and every other token the agent obtains (resource tokens, auth tokens) is issued in response to a request signed by that key. When an agent presents an auth token to a resource, the auth token's `cnf` claim binds it to the same key — so the agent's identity, established by the agent token, ultimately authorizes every signed request whether the `Signature-Key` header carries the agent token or an auth token.

## Agent Provider {#agent-provider}

An agent provider (AP) is the server that issues an agent its identity. An AP is identified by an HTTPS URL (#server-identifiers) and publishes metadata at `/.well-known/aauth-agent.json` (#agent-provider-metadata), where its `jwks_uri` holds the keys that agent tokens are verified against. A resource, PS, or AS trusts an AP's agents by fetching that one JWKS, rather than managing a key per agent (#why-agents-are-under-an-agent-provider).

An AP does four things in the protocol:

- **Issues agent tokens.** An agent MUST obtain an agent token from its agent provider before participating in the AAuth protocol. The agent generates a signing key pair (Ed25519 is RECOMMENDED), proves its identity to the AP through a platform-specific mechanism, and the AP issues an agent token binding the agent's public key to its identifier (#agent-token-structure). The mechanism for proving identity is platform-dependent; see [@?I-D.hardt-aauth-bootstrap] for common patterns, including self-hosted agents, browser-based applications, and mobile applications, and for the key-refresh ceremony.
- **Issues sub-agent tokens.** An AP issues a sub-agent its own identifier and agent token, marked with `parent_agent`, under the rules in (#sub-agents).
- **Evaluates policy.** The AP decides whether to keep treating an agent as authorized, and enforces that decision by issuing or refusing fresh agent tokens (#policy-evaluation-points). Agent tokens SHOULD NOT live longer than 24 hours (#agent-token-structure), so the decision is revisited at least that often.
- **Revokes agent tokens.** When an agent can no longer be trusted, the AP revokes its agent token at the agent's PS (#token-revocation). The PS is the only recipient of an agent token revocation.

An AP MAY be collocated with other roles: a self-hosted agent is its own AP, and a resource that acts as an agent for downstream calls MUST be its own AP (#roles). An AP that supports AAuth Events ([@?I-D.hardt-aauth-events]) also receives event tokens from resources on behalf of its agents.

An AP is named in both things it issues: the `domain` part of each agent identifier it assigns (#agent-identifiers), and the `iss` of each agent token it signs (#agent-tokens).

## Agent Identifiers

An AP assigns each agent an identifier: a URI using the `aauth` scheme, of the form `aauth:local@domain`, where `domain` is the AP's domain. The `local` part MUST consist of ASCII letters (`A-Za-z`), digits (`0-9`), hyphen (`-`), underscore (`_`), plus (`+`), and period (`.`). The `local` part MUST NOT be empty and MUST NOT exceed 255 characters. The `domain` part MUST be a valid domain name conforming to the server identifier requirements (#server-identifiers) (without scheme).

The plus character (`+`) is RESERVED as the sub-agent delimiter (#sub-agents). A top-level agent's `local` part MUST NOT contain `+`. A sub-agent's `local` part MUST be its parent's `local` part, followed by `+`, followed by a non-empty discriminator (for example, `planner.7f3c+search1`). This naming is for operational readability only — a sub-agent's identifier shows its parent at a glance in logs. Parties MUST NOT parse the `local` part for protocol decisions; the `parent_agent` claim (#sub-agents) is the authoritative sub-agent marker and names the parent.

Valid agent identifiers:

- `aauth:assistant-v2@agent.example`
- `aauth:planner.7f3c@vendor.example` (top-level)
- `aauth:planner.7f3c+search1@vendor.example` (sub-agent of `planner.7f3c`)

Invalid agent identifiers:

- `My Agent@agent.example` (space in local part)
- `@agent.example` (empty local part)
- `agent@http://agent.example` (domain includes scheme)

Implementations MUST perform exact string comparison on agent identifiers (case-sensitive): `aauth:Agent@agent.example` and `aauth:agent@agent.example` are different agents, and an implementation MUST NOT case-fold the `local` part.

An agent identifier is stable across key rotations. The agent token binds it to the agent's current signing key.

## Agent Token {#agent-tokens}

### Agent Token Structure {#agent-token-structure}

An agent token is a JWT with `typ: aa-agent+jwt`. Its header and the claims `iss`, `dwk`, `jti`, `iat`, `exp`, and `cnf` are as defined in (#common-claims), with:

- `iss`: Agent provider URL
- `dwk`: `aauth-agent.json`
- `cnf`: `jwk` is the agent's public key
- `exp`: Agent tokens SHOULD NOT have a lifetime exceeding 24 hours.

Required payload claims specific to agent tokens:
- `sub`: Agent identifier (stable across key rotations)

Optional payload claims:
- `ps`: The HTTPS URL of the agent's person server. Configured per agent instance. When present, it tells a resource that the agent has a person server and which one, before the resource has verified a person token — enough to decide whether to challenge for one. The PS of an issued authorization is the `iss` of the person token the resource verified (#person-token-structure), not this claim. This claim is distinct from `iss` (which identifies the agent provider that issued the token).
- `parent_agent`: Sub-agent marker (#sub-agents). When present, the agent is a sub-agent and the value is the identifier of its parent agent. A sub-agent MUST NOT request authorization directly; its parent obtains auth tokens on its behalf (#sub-agents).

Agent providers MAY include additional claims in the agent token. Companion specifications may define additional claims for use by PSes or ASes in policy evaluation — for example, software attestation, platform integrity, secure enclave status, workload identity assertions, or software publisher identity. PSes and ASes MUST ignore unrecognized claims.

### Agent Token Usage

Agents present agent tokens via the `Signature-Key` header ([@!I-D.hardt-httpbis-signature-key]) under the `jwt` scheme:

```http
Signature-Key: sig=jwt;
    jwt="eyJhbGciOiJFZDI1NTE5IiwidHlwIjoiYWEtYWdlbnQrand0Iiwia2lkIjoiYXAta2V5LTEifQ..."
```

### Agent Token Verification

Verify the agent token per (#common-verification), with `typ` `aa-agent+jwt` and `dwk` `aauth-agent.json`, then:

1. Verify `cnf.jwk` matches the key used to sign the HTTP request.
2. If `ps` is present, verify it is a valid HTTPS URL conforming to the Server Identifier requirements.
3. If `parent_agent` is present, verify it is a valid agent identifier — the parent agent. Its presence marks this as a sub-agent's token (#sub-agents); the PS additionally enforces the single-level rule (#sub-agents) when such a token signs a request.

# Resource Access {#resource-tokens}

An agent calls a resource with a signed request. The resource serves it, or answers with an `AAuth-Requirement` header naming what it needs first (#requirement-responses). This section defines the four requirements a resource can raise, in the order they ask more of the agent, followed by the session token, the authorization endpoint, and the resource token.

| Requirement | Status | The resource needs | The agent |
|---|---|---|---|
| `agent-token` | `401` | the agent's identity | presents its agent token (#requirement-agent-token) |
| `interaction` | `202` | the person, at the resource's own page | directs the person there and polls (#resource-managed-auth) |
| `person-token` | `401` | the person's identity | obtains a person token from its PS (#requirement-person-token) |
| `auth-token` | `401` or `202` | consent or policy for a scope | takes the enclosed resource token to its PS (#requirement-auth-token) |

The first two involve no person server: the resource decides on the agent's identity, or runs its own consent and issues a session token (#aauth-access). The last two need the agent's PS. An agent with no PS cannot obtain a person token, so `agent-token` and `interaction` are the whole of what is available to it.

A resource MAY handle authorization itself for any request, regardless of whether the agent has a PS, and MAY apply different requirements to different endpoints.

## Agent Token Required {#requirement-agent-token}

A resource that decides on the agent's identity alone answers a request that did not present an AAuth agent token with `401` and `requirement=agent-token`:

```http
HTTP/1.1 401 Unauthorized
AAuth-Requirement: requirement=agent-token
```

The header carries no parameters. The agent retries, presenting its agent token via the `Signature-Key` header under the `jwt` scheme (#keying-material).

`requirement=agent-token` asks for an AAuth agent token (`typ: aa-agent+jwt`) in particular. An `Accept-Signature-Scheme` challenge ([@!I-D.hardt-httpbis-signature-key]) names schemes, and so would accept any key those schemes can convey; a resource challenging an AAuth agent uses `requirement=agent-token` instead (#scheme-rejection).

## Resource-Managed Authorization {#resource-managed-auth}

A resource that runs its own consent, login, or existing OAuth flow answers with `202 Accepted` and `requirement=interaction`:

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

The agent directs the user to the interaction URL (#user-interaction) and polls the `Location` URL (#deferred-responses). When the interaction completes, the resource returns `200 OK` and MAY include an `AAuth-Access` header (#aauth-access) with a session token for subsequent calls.

A resource MAY also authorize on the agent's identity alone, without any interaction, when the agent's key is already known or its domain is trusted.

## AAuth-Access Response Header {#aauth-access}

The `AAuth-Access` response header carries a **session token** from a resource to an agent. The token is opaque to the agent: the resource wraps its own authorization state, which MAY be an existing OAuth access token or other credential. It is the one AAuth credential a resource issues for its own consumption. The agent returns it in the `Authorization` header on subsequent requests:

```http
GET /api/data HTTP/1.1
Host: resource.example
Authorization: AAuth wrapped-session-token-value
Signature-Input: sig=("@method" "@authority" "@path" \
    "authorization" "signature-key");created=1730217600
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;jwt="eyJhbGc..."
```

The agent MUST include `authorization` in the covered components of its HTTP signature. The token MUST NOT be usable as a standalone bearer token: the resource wraps its state so that the value is meaningless without a valid signature from the agent.

A resource MAY return a new `AAuth-Access` header on any response, replacing the current session token. When the agent receives a new value, it MUST use it on subsequent requests. This is the refresh mechanism; there is no separate refresh flow.

The `AAuth-Access` value, and the credential carried in `Authorization: AAuth`, is a `token68` ([@!RFC9110], Section 11.2). Recipients MUST reject empty values, values containing embedded whitespace or control characters, and responses carrying more than one credential.

## Person Token Required {#requirement-person-token}

A resource that needs to know which person the agent acts for, and has not verified a person token on the request, answers with `401` and `requirement=person-token`:

```http
HTTP/1.1 401 Unauthorized
AAuth-Requirement: requirement=person-token
```

The header carries no parameters. The agent obtains a person token for this resource from its PS (#person-token-endpoint) and retries, presenting it via the `Signature-Key` header in place of its agent token (#person-token-usage). A resource MUST answer a request to its authorization endpoint that carries no person token this way (#authorization-endpoint-request), and MAY use it on any other endpoint where it requires the person's identity before serving a request.

An agent with no person server cannot satisfy this requirement and surfaces it as an error (#requirement-values).

## Auth Token Required {#requirement-auth-token}

A resource that needs consent or policy for a scope answers with `401`, `requirement=auth-token`, and a `resource-token` parameter carrying a resource token JWT (#resource-token-structure):

```http
HTTP/1.1 401 Unauthorized
AAuth-Requirement: requirement=auth-token; resource-token="eyJ..."
```

A resource MUST use `requirement=auth-token` when an auth token is required, and the header MUST include the `resource-token` parameter. The agent MUST extract and verify the resource token (#resource-challenge-verification) and present it to its PS's auth token endpoint (#ps-token-endpoint) to obtain an auth token. It then retries, presenting the auth token via `Signature-Key` (#auth-token-usage).

A resource issues a resource token only after verifying a person token or an auth token on the request (#resource-token). A request that carried neither is answered with `requirement=person-token` instead. A resource MAY also send `402 Payment Required` with the same header when payment is additionally required (#requirement-responses).

A resource MAY return `requirement=auth-token` with a new resource token to a request that already carries an auth token, when the request needs more authorization than the token provides. Agents MUST be prepared for this step-up at any time.

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

The agent obtains an auth token exactly as in the `401` case, then polls the pending URL with signed `GET` requests, presenting the auth token via `Signature-Key` once it holds one. The resource executes the held invocation on the first poll that presents a valid auth token and answers with the invocation's response.

Completion consumes the pending record. The resource MUST retain the record, with the invocation's result, at least until the auth token's `exp`, and MUST answer a repeated presentation of the same auth token at the pending URL from that result rather than executing again: a response can be lost in transit, and the agent cannot otherwise tell "not executed" from "executed, response lost". The record is keyed by the auth token's `jti`. If the resource token expires before the agent obtains an auth token, the resource MAY include a fresh one in the `AAuth-Requirement` header of a later poll response.

Which delivery to use is the resource's choice, per invocation. The `401` needs no state and works on any transport; the `202` suits a resource that can hold the invocation. Agents MUST support both.

## Authorization Endpoint {#authorization-endpoint-request}

A resource MAY publish an `authorization_endpoint` in its metadata (#resource-metadata). It lets an agent request access for a scope before calling the resource, instead of waiting for a challenge. The agent MUST present a person token (#person-tokens) via the `Signature-Key` header, and the resource MUST verify it (#person-token-verification). A request without one is answered per (#requirement-person-token).

**Request parameters:**

- `scope` (REQUIRED): A space-separated string of scope values the agent is requesting (#scopes).
- `account` (OPTIONAL): A string identifying which account at the resource the authorization is for, drawn from the resource's own account namespace (#account-binding).

```http
POST /authorize HTTP/1.1
Host: resource.example
Content-Type: application/json
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "scope": "data.read data.write"
}
```

The resource answers in one of two ways: it handles authorization itself, or it issues a resource token.

### Response without Resource Token

The resource handles authorization itself. If user interaction is needed, it returns a `202 Accepted` deferred response with `requirement=interaction`, as in (#resource-managed-auth). When authorization is complete, or can be granted immediately, it returns `200 OK` and MAY include an `AAuth-Access` header (#aauth-access):

```http
HTTP/1.1 200 OK
AAuth-Access: wrapped-session-token-value
Content-Type: application/json

{
  "status": "authorized",
  "scope": "data.read data.write"
}
```

### Response with Resource Token

The resource returns a resource token (#resource-token-structure), with `aud` set to its AS or to the PS that issued the person token, and `mission_s256` copied from the person token when it carried one:

```json
{
  "resource_token": "eyJhbGc..."
}
```

The agent sends the resource token to its PS's auth token endpoint (#ps-token-endpoint).

### Authorization Endpoint Error Responses {#authorization-endpoint-error-responses}

| Error | Status | Meaning |
|-------|--------|---------|
| `invalid_request` | 400 | Missing or invalid parameters |
| `invalid_scope` | 400 | Requested scope not recognized by the resource |
| `invalid_account` | 400 | The `account` named is not held by the person the person token identifies |
| `server_error` | 500 | Internal error |

Errors use the error response format (#error-response-format). A person token that fails verification is answered with `401` and `Signature-Error` (#verification), not with a code from this table.

## Resource Token {#resource-token}

A resource token is what a resource hands the agent to carry to the agent's PS. It binds the resource's identity, the person's identity, the agent's signing key, and the requested scope, so that the PS or AS issuing the auth token knows exactly what was asked, by whom, for whom.

A resource MUST verify a person token (#person-token-verification) or an auth token (#auth-token-verification) on the request before it issues a resource token: the token's `ps`, `sub`, and `presented_jti` are copied from the token the request carried. On the authorization endpoint that is the person token; on any other endpoint it is whichever the request carried. A resource that has verified neither MUST challenge with `requirement=person-token` (#requirement-person-token) instead.

The resource sets `aud` to the party that will redeem the token:

- `aud` = the AS URL when the resource has its own access server (four-party)
- `aud` = the `iss` of the person token the resource verified when it has none (three-party)

### Resource Token Structure

A resource token is a JWT with `typ: aa-resource+jwt`. Its header and the claims `iss`, `dwk`, `jti`, `iat`, and `exp` are as defined in (#common-claims), with `iss` the resource URL and `dwk` `aauth-resource.json`. A resource token carries no `cnf`; `agent_jkt` binds it to the agent's key.

Required payload claims specific to resource tokens:

- `aud`: The PS URL or the AS URL, as above.
- `ps`: The person server whose namespace `sub` belongs to: the `iss` of the person token the request carried, or the `ps` of the auth token it carried.
- `sub`: The `sub` of the token the request carried.
- `presented_jti`: The `jti` of the token the request carried: the person token on the first challenge of a grant, or the auth token on a step-up or per-call challenge. The agent passes that token to the PS as `presented_token` (#ps-token-endpoint). Binding the resource token to one presented token is what makes mission stripping detectable (#why-presented-jti).
- `agent_jkt`: JWK Thumbprint ([@!RFC7638]) of the agent's current signing key.

A resource token carries no agent identifier. The recipient learns the agent's identity from the agent token that signs the token request.

Optional payload claims:

- `scope`: Requested scopes, as a space-separated string. Present unless a companion specification defines an authorization claim that replaces it, as R3 does ([@?I-D.hardt-aauth-r3]).
- `account`: Echoes the `account` parameter of the request that produced this token (#account-binding).
- `login_hint`: A hint about who the authorization is for, per [@!OpenID.Core] Section 3.1.2.1, for a resource that knows it. The agent passes the value to its PS as the `login_hint` parameter of the token request (#ps-token-endpoint) and MUST NOT alter it. The PS MAY ignore it. A resource MUST check the claims in the auth token it receives against what it asked for rather than assuming the hint was honored.
- `mission_s256`: REQUIRED when the presented token carried one, copied unchanged.
- `tenant`: Copied from the presented token when it carried one.
- `interaction`: Present when the resource requires its own user-facing flow, such as an OAuth authorization at a third-party service, before the PS can issue an auth token (#resource-initiated-interaction). Contains `url`, the HTTPS URL of the resource's interaction endpoint, and `code`, the interaction code to present there.

Resource tokens SHOULD NOT have a lifetime exceeding 5 minutes. A resource token's lifetime is independent of any mission it names: the PS verifies that the mission is active when it acts on the token. If a resource token expires before it is redeemed, the agent MUST obtain a fresh one from the resource and submit a new token request. The PS SHOULD remember prior consent decisions within a mission so the user is not re-prompted for the same resource and scope. ASes are not required to enforce replay detection on resource tokens.

### Resource Token Verification

Verify the resource token per (#common-verification), with `typ` `aa-resource+jwt` and `dwk` `aauth-resource.json`, then:

1. Verify `aud` matches the recipient's own identifier (the PS in three-party, or the AS in four-party).
2. Verify `agent_jkt` matches the JWK Thumbprint of the key used to sign the HTTP request. For a parent-mediated sub-agent authorization (#sub-agents), verify it against the `subagent_token`'s `cnf.jwk` instead, since the parent signs the request.
3. Verify the `presented_token` from the token request (#ps-token-endpoint) and (#ps-to-as-token-request) by its `typ`: a person token (`aa-person+jwt`) per (#person-token-verification) or an auth token (`aa-auth+jwt`) per (#auth-token-verification), with two substitutions: `aud` MUST equal the resource token's `iss` rather than the verifier's own identifier, and `cnf.jwk` MUST match the resource token's `agent_jkt` rather than the key that signed the request. The resource's record check on `sub` does not apply. A token that fails is rejected with `invalid_presented_token`, or `expired_presented_token` when only `exp` fails. Then verify that the presented token's `jti` equals `presented_jti`, that its `iss` (person token) or `ps` (auth token) equals the resource token's `ps`, and that its `sub`, `mission_s256`, and `tenant` match the resource token's exactly, rejecting the resource token with `invalid_resource_token` on any mismatch or omission. A mismatch against a token that verifies is evidence of tampering and SHOULD be surfaced to operators. A PS MUST verify that `ps` names itself; an AS MUST verify that `ps` names the PS that sent the token request.
4. If `mission_s256` is present, a PS MUST verify the mission is active and that the current time precedes its `expires_at` where one is set.

### Resource Challenge Verification

When an agent receives `requirement=auth-token`:

1. Extract the `resource-token` parameter.
2. Decode and verify the resource token JWT.
3. Verify `iss` matches the resource the agent sent the request to.
4. Verify `agent_jkt` matches the JWK Thumbprint of the agent's signing key.
5. Verify `ps` matches the agent's own person server, `sub` the value in the token the agent presented, and `presented_jti` that token's `jti`.
6. Verify `exp` is in the future.
7. Send the resource token, with the token the agent presented as `presented_token`, to the agent's PS's auth token endpoint.

# Person Server {#person-server}

A person server represents the person to the rest of the protocol. This section defines what it serves to agents, in the order an agent meets them: the two token endpoints, the consent that issuing tokens may require, the endpoints an agent uses to reach the person or to be governed, and what an agent does when tokens expire.

Every PS endpoint is published in its metadata (#ps-metadata) and authenticates callers by HTTP Sig with an agent token (#http-message-signatures-profile); all use the same requirement responses (#requirement-responses) and deferred responses (#deferred-responses).

| Endpoint | Metadata field | Purpose |
|---|---|---|
| Person token (#person-token-endpoint) | `person_token_endpoint` (REQUIRED) | issues a person token identifying the person to one resource |
| Auth token (#ps-token-endpoint) | `auth_token_endpoint` (REQUIRED) | takes a resource token and returns an auth token, directly or by federating with the resource's AS |
| Interaction (#interaction-endpoint) | `interaction_endpoint` (OPTIONAL) | the agent's channel to the person through the PS |
| Permission (#permission-endpoint) | `permission_endpoint` (OPTIONAL) | permission for actions not governed by a remote resource |
| Audit (#audit-endpoint) | `audit_endpoint` (OPTIONAL) | a record of actions performed |
| Mission (#missions) | `mission_endpoint` (OPTIONAL) | where the agent proposes, updates, and completes its missions |
| Mission control (#mission-management) | `mission_control_endpoint` (OPTIONAL) | the control plane for principals other than the owning agent; defined by a companion specification |
| Revocation (#token-revocation) | `revocation_endpoint` (RECOMMENDED) | where an agent provider revokes an agent token, and a resource a resource token this PS holds |

The two REQUIRED endpoints, with `issuer` and `jwks_uri`, are the conformance floor (#ps-metadata). A PS MAY also maintain a direct channel to the person, such as email, push notification, or messaging, for out-of-band approvals, notifications, and revocation alerts. The PS evaluates every request against the mission when one is in force, handles consent when it is needed, and issues tokens bounded by what it has verified.

## Person Token Endpoint {#person-token-endpoint}

The first thing an agent needs from its PS is a person token for a resource (#person-tokens). Every PS MUST publish a `person_token_endpoint` in its metadata and MUST issue person tokens from it.

The agent MUST make a signed POST with an HTTP Sig (#http-message-signatures-profile), presenting its agent token via the `Signature-Key` header under the `jwt` scheme.

**Request parameters:**

- `resource` (REQUIRED): The HTTPS URL of the resource the person token is for, conforming to the server identifier requirements (#server-identifiers). Becomes the `aud` of the issued token. The PS MUST validate it against those requirements.
- `mission_s256` (OPTIONAL): The mission the agent is operating under (#missions). The PS MUST verify the mission exists, is active, and belongs to this agent, and MUST reject the request otherwise. When present, the PS includes it in the issued token. Not sent with `upstream_token`, which carries the mission itself.
- `subagent_token` (OPTIONAL): A sub-agent's agent token, present when a parent agent obtains a person token on behalf of one of its sub-agents (#sub-agents). The signing agent MUST be named by the `subagent_token`'s `parent_agent`. The issued token's `cnf` is the sub-agent's key.
- `upstream_token` (OPTIONAL): The person token or auth token the calling agent presented to the requester, present when a resource acting as an agent needs a person token for a downstream resource (#call-chaining). The PS MUST verify it per (#upstream-token-verification).

The request also takes the OPTIONAL parameters of the auth token request (#ps-token-endpoint), with the same definitions: `capabilities`, `login_hint`, `tenant`, `domain_hint`, `prompt`, `justification`, `platform`, and `device`. This is where a PS first decides which person the agent acts for and whether it has to reach them, so these matter here first. `capabilities` tells the PS whether the agent can drive an interaction; without it, a PS that must reach the person answers `user_unreachable` (#token-endpoint-error-codes). Within a mission the PS uses the capabilities captured at approval (#mission-approval) when `capabilities` is omitted.

```http
POST /person HTTP/1.1
Host: ps.example
Content-Type: application/json
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "resource": "https://resource.example",
  "mission_s256": "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk",
  "capabilities": ["interaction"]
}
```

**Response** (`200`):

```json
{
  "person_token": "eyJhbGc...",
  "expires_in": 3600
}
```

The PS MAY require user interaction before issuing and return a `202 Accepted` deferred response with `requirement=interaction` (#interaction-required). Because a resource MAY serve requests on identity alone, the question put to the person is whether this agent may act at the resource as them, not merely whether it may name them. A PS SHOULD fetch the resource's metadata (#resource-metadata) before issuing for a resource the person has not used, and present its `name`, `description`, and `access_mode`.

Errors use the token endpoint error codes (#token-endpoint-error-codes); `invalid_request` covers a missing or malformed `resource` or `mission_s256`.

**Which person.** Without `upstream_token` the PS issues for the person bound to the requesting agent (#agent-person-binding). With it, the PS issues for the person the upstream token was issued for. The upstream token MUST name this PS (as `iss` in a person token, as `ps` in an auth token), and its `sub` is the directed identifier this PS minted for that person at the upstream token's `aud` (#directed-identifiers). The PS resolves the person from its own record for that resource and `sub`; a PS that holds no such record MUST reject the request. When the upstream token carries `mission_s256`, the PS evaluates the request against that mission (#call-chaining) and copies `mission_s256` into the person token it issues, so the mission's `expires_at` and termination reach the chain. The intermediary does not send `mission_s256` of its own.

**Retention.** A PS MUST record, for each person token it issues, the `jti`, the `aud`, and the `exp`, and, once it has presented the token to an access server (#ps-to-as-token-request), which one, and MUST keep the record until the token's `exp` plus clock skew. The record serves revocation (#token-revocation), not verification. A PS SHOULD rate-limit the number of distinct `resource` values it accepts from one agent, since each obliges it to derive and retain a directed `sub`.

**Caching.** An agent SHOULD cache a person token for a resource until it expires rather than requesting one per call. A person token is scoped to one resource and, when it carries `mission_s256`, to one mission, so an agent holds one per combination. Rotating the signing key invalidates all of them, since each binds the key through `cnf`; the agent SHOULD re-request lazily, on next use of each resource.

### Person Token {#person-tokens}

A person token is a PS-issued JWT that identifies the person an agent acts for to a single resource. It is not a bearer credential — `cnf` binds it to the agent's signing key — its `aud` is one resource, and it lives at most one hour. It carries no authorization from the PS: no scope, no account, no permission. Whether identity alone is sufficient to serve a request is the resource's decision, and a resource that decides it is (#overview-person-identity) serves whatever it serves on identity — so holding a person token is, at such a resource, effectively access. What a person token MUST NOT do is stand in for an auth token where one is required (#person-token-not-authorization).

A person token asserts that its issuer recognizes this person and that this agent acts for them. It carries no statement about how the person server established the person's identity, and a resource MUST NOT treat it as evidence of identity proofing, of legal identity, or of any assurance level. What it guarantees is continuity: the same `(iss, sub)` is the same person at this resource over time (#continuity-not-proofing).

The agent presents it via the `Signature-Key` header in place of its agent token (#keying-material). A resource MUST have verified a person token before it issues a resource token (#resource-tokens), so the identity and mission a resource records are PS-asserted rather than agent-asserted.

### Person Token Structure {#person-token-structure}

A person token is a JWT with `typ: aa-person+jwt`. Its header and the claims `iss`, `dwk`, `jti`, `iat`, `exp`, and `cnf` are as defined in (#common-claims), with:

- `iss`: PS URL
- `dwk`: `aauth-person.json`
- `cnf`: `jwk` is the agent's public key
- `exp`: Person tokens MUST NOT have a lifetime exceeding 1 hour, and MUST NOT outlive the agent token presented when the token was requested, the `upstream_token` when the request carried one (#call-chaining), or, when `mission_s256` is present, the mission's `expires_at` (#mission-approval).

Required payload claims specific to person tokens:

- `aud`: The URL of the resource this token identifies the person to
- `sub`: Directed user identifier, with the same value the PS uses in the `sub` claim of auth tokens it issues for this `aud` (#auth-token-structure)

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

### Person Token Usage {#person-token-usage}

Agents present person tokens via the `Signature-Key` header ([@!I-D.hardt-httpbis-signature-key]) under the `jwt` scheme, in place of the agent token:

```http
Signature-Key: sig=jwt;
    jwt="eyJhbGciOiJFZDI1NTE5IiwidHlwIjoiYWEtcGVyc29uK2p3dCJ9..."
```

The person token's `cnf.jwk` is the same key that signed the request, so HTTP Message Signature verification proceeds identically to the agent-token case. Once an auth token has been issued for a resource, the agent presents the auth token on subsequent requests to that resource (#auth-token-usage).

An agent refreshes a person token before it expires, within the margin of (#refresh-margin), and re-obtains resource tokens and auth tokens against it, so that no token in the chain lapses mid-task. The refresh runs through the resource's authorization endpoint (#authorization-endpoint-request) presenting the fresh person token, which is also what restores a full-length chain: a resource token issued on a step-up names the auth token the request carried, and the auth token issued against it inherits that token's `exp` (#auth-token-structure). This parallels the agent-token guidance in (#re-authorization).

### Person Token Verification {#person-token-verification}

Verify the person token per (#common-verification), with `typ` `aa-person+jwt` and `dwk` `aauth-person.json`, then:

1. Verify `aud` matches the resource's own identifier.
2. `cnf.jwk` is REQUIRED. Verify it matches the key used to sign the HTTP request, applying the same structural checks as auth token verification (#request-context-binding).

A recipient MUST reject an `aa-person+jwt` wherever an auth token is required. Only `typ` distinguishes the two (#person-token-not-authorization).

`sub` is unique within the issuer, not globally. A resource MUST treat `(iss, sub)` as the identifier, MUST treat the value as opaque, and MUST NOT match a `sub` received from one issuer against a record established under another, however the values compare.

## Auth Token Endpoint {#ps-token-endpoint}

Once a resource has issued a resource token, the agent brings it here. The PS evaluates the request, handles user consent if needed, and either issues the auth token itself or federates with the resource's AS (#ps-as-federation). The resource token's `aud` decides which.

| Mode | Key Parameters | Use Case |
|------|----------------|----------|
| PS authorization | `resource_token` (`aud` = PS) | PS asserts identity and consent; resource applies its own policy (three-party) |
| AS-federated | `resource_token` (`aud` = AS) | PS federates with the resource's AS, which evaluates resource policy (four-party) |
| Call chaining | `resource_token` + `upstream_token` | Resource acting as agent (#call-chaining) |

### Auth Token Request

The agent MUST make a signed POST to the PS's `auth_token_endpoint` with an HTTP Sig (#http-message-signatures-profile), presenting its agent token via the `Signature-Key` header under the `jwt` scheme.

**Request parameters:**

- `resource_token` (REQUIRED): The resource token.
- `presented_token` (REQUIRED): The token the agent presented to the resource that issued `resource_token`, whose `jti` the resource token's `presented_jti` names (#resource-token-structure): the person token on the first challenge of a grant, or the auth token on a step-up or per-call challenge. The PS verifies it against the resource token (#resource-token-verification) and, in four-party, passes it to the AS (#ps-to-as-token-request). Its `exp` bounds the auth token issued (#auth-token-structure).
- `upstream_token` (OPTIONAL): The person token or auth token the calling agent presented to the requester, used in call chaining (#call-chaining). The PS MUST verify it per (#upstream-token-verification).
- `subagent_token` (OPTIONAL): A sub-agent's agent token, present when a parent agent requests authorization on behalf of one of its sub-agents (#sub-agents). The signing agent (the parent) MUST be named by the `subagent_token`'s `parent_agent`.
- `justification` (OPTIONAL): A Markdown string declaring why access is being requested. The PS SHOULD present it to the user during consent, MUST present it as agent-asserted content (#consent-presentation), and MUST sanitize it before rendering. The PS MAY log it. It is also the text the user's clarification questions are asked about (#clarification-chat). This document does not yet define a section structure for the value (#terminology).
- `login_hint` (OPTIONAL): Hint about who to authorize, per [@!OpenID.Core] Section 3.1.2.1. When the resource token carries a `login_hint` (#resource-token-structure) the agent sends that value unchanged.
- `tenant` (OPTIONAL): Tenant identifier, per OpenID Connect Enterprise Extensions 1.0 [@OpenID.Enterprise].
- `domain_hint` (OPTIONAL): Domain hint, per OpenID Connect Enterprise Extensions 1.0 [@OpenID.Enterprise].
- `prompt` (OPTIONAL): Space-delimited, case-sensitive list of values specifying whether the PS prompts the user for reauthentication and consent, per [@!OpenID.Core] Section 3.1.2.1. Defined values: `none`, `login`, `consent`, `select_account`.
- `platform` (OPTIONAL): Identifier for the runtime platform the agent runs on. The value MUST be from the AAuth Platform Value Registry (#aauth-platform-value-registry). Describes where the agent runs, not what security measures apply there. For display at the consent screen and the connected-agents dashboard. Agent-attested.
- `device` (OPTIONAL): Short human-readable string identifying the device or browser, for display so users can distinguish entries in their connected-agents dashboard (e.g., `Chrome on macOS`, `Pixel 8 (App)`). Opaque to receivers. MUST consist of UTF-8 printable characters only and MUST NOT exceed 64 characters. Agents MUST NOT include personally identifying information beyond what the user has chosen. Agent-attested.
- `capabilities` (OPTIONAL): An array of capability values (#aauth-capabilities) the agent can handle for this request, the body equivalent of the `AAuth-Capabilities` header, which is not used on PS endpoints. Within a mission, if omitted, the PS uses the values captured at approval (#mission-approval); if present, it refreshes them for this request.

**Example request:**

```http
POST /token HTTP/1.1
Host: ps.example
Content-Type: application/json
Prefer: wait=45
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "resource_token": "eyJhbGc...",
  "presented_token": "eyJhbGc...",
  "justification": "Find available meeting times"
}
```

### PS Response

The PS returns one of:

**Direct grant response** (`200`):

```json
{
  "auth_token": "eyJhbGc...",
  "expires_in": 3600
}
```

**User interaction required** (`202`): a deferred response with `requirement=interaction` (#interaction-required), of the same shape as (#resource-managed-auth). In four-party mode the PS may also pass a clarification from the AS through to the agent this way (#as-token-endpoint).

An agent MAY have several token requests pending at the PS at once, for example when a mission needs several resources. Each has its own pending URL and lifecycle, and the PS MUST handle them independently. How the PS manages concurrent user interactions, by batching consent prompts or serializing them, is its own choice.

### Resource-Initiated Interaction {#resource-initiated-interaction}

When the resource token carries an `interaction` claim (#resource-token-structure), the resource needs its own user-facing flow, typically an OAuth authorization at a third-party service, before the PS can issue an auth token. The PS resolves the resource's interaction before presenting its own consent: if the user declines at the resource, PS consent is moot.

1. The PS returns `202` to the agent with its own interaction URL, as for any consent interaction.
2. The user arrives at the PS's interaction page. The PS shows an interstitial explaining that the resource requires additional permissions.
3. The PS redirects the user to the resource's interaction endpoint using the standard callback pattern, where `ps_callback_url` is a PS-generated, per-flow URL: `{interaction.url}?code={interaction.code}&callback={ps_callback_url}`
4. The resource completes its own flow. The resource MUST redirect the user to the `callback` URL when its flow completes, successfully or with an error per (#interaction-callback-errors).
5. If the callback carries an `error` parameter, the PS abandons the authorization and returns the mapped polling error to the agent. Otherwise it continues with its own consent step.
6. On user approval, the PS issues the auth token and resolves the agent's pending request.

A resource's interaction endpoint MUST support the `?code=...&callback=...` pattern whether the redirect comes from an agent or from a PS; it need not distinguish the two. The `interaction.url` MUST be an HTTPS URL; the PS MUST validate this before redirecting and MUST apply its egress admission policy to it.

## User Interaction {#user-interaction}

Issuing a token may require the person. When a server responds with `202` and `requirement=interaction`, the agent directs the user to the interaction `url` with the `code`, optionally relaying through its PS first, using the mechanics defined in (#interaction-required) and (#interaction-relay). Two details apply when the agent directs the user itself.

When the agent has a browser, it MAY append a `callback` parameter, constructed from its `callback_endpoint` metadata:

```
{url}?code={code}&callback={callback_url}
```

When present, the server redirects the user's browser to the `callback` URL after the user completes the action. Without it, the server displays a completion page and the agent relies on polling.

The `code` is single-use: once the user arrives with a valid code, it is consumed. The server hosting the interaction URL MAY instead complete the interaction over a channel it already controls, such as a notification the person taps, without the person visiting `url` or presenting `code`; the code is consumed at that completion, and the pending URL returns the terminal response (#deferred-responses). Only the host of `url` can complete an interaction this way.

### Interaction Callback Errors {#interaction-callback-errors}

When an interaction cannot be completed, the server MUST redirect to the `callback` URL with an `error` query parameter:

```
{callback_url}?error={error_code}
```

| Error | Meaning |
|---|---|
| `access_denied` | The user explicitly declined the interaction. |
| `user_abandoned` | The user opened the interaction but did not complete it. |
| `server_error` | The party handling the interaction encountered an internal failure. |
| `temporarily_unavailable` | The interaction service is temporarily unavailable; the caller MAY retry. |
| `interaction_expired` | The interaction session expired before the user completed the flow. |

Recipients of a callback with an `error` parameter MUST NOT treat the pending request as completable and MUST surface the error to the caller. In the resource-initiated interaction flow (#resource-initiated-interaction), the PS maps the callback error to a polling error (#polling-error-codes): `access_denied` to `denied`, `user_abandoned` to `abandoned`, `interaction_expired` to `expired`, and `server_error` and `temporarily_unavailable` to `server_error`.

## Consent Presentation {#consent-presentation}

A consent surface carries content from two sources, and the person deciding needs to know which is which.

**Resource-asserted** content comes from the party that will carry out the access: the `name`, `description`, `logo_uri`, and `scope_descriptions` in the resource's metadata (#resource-metadata), any claim in the resource token (#resource-tokens), and the `display` section of an R3 document ([@?I-D.hardt-aauth-r3]).

**Agent-asserted** content comes from the party asking for the access: the `justification`, `platform`, and `device` parameters of the token request (#ps-token-endpoint), and the agent's clarification responses (#clarification-chat). The agent chooses the words and gains from being believed.

A PS MUST visually distinguish resource-asserted content from agent-asserted content when rendering a consent surface, and MUST attribute agent-asserted content to the agent. A PS MUST NOT base an authorization decision solely on agent-asserted content where resource-asserted content covering the same operation is available.

Neither requirement suppresses the justification: it is presented, as the agent's claim. Where the Supervisor (#roles) is a supervision server rather than a person reading a screen, the PS MUST convey the same distinction in whatever form that context takes.

## Clarification Chat {#clarification-chat}

During consent, the user may ask questions about the agent's stated justification. The PS delivers the question to the agent and the agent responds, giving the person a consent dialog without the agent needing a direct channel to them.

Agents that support clarification chat declare it with the `clarification` capability (#aauth-capabilities).

### Clarification Required {#requirement-clarification}

A server MUST use `requirement=clarification` with a `202 Accepted` response when it needs the recipient to answer a question before proceeding. The body MUST include a `clarification` field containing the question and MAY include `timeout` and `options`.

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

The recipient MUST respond with one of the actions in (#agent-response-to-clarification). This requirement is used by PSes (delivering user questions to agents) and by ASes (requesting clarification from PSes).

### Agent Response to Clarification {#agent-response-to-clarification}

The agent MUST respond to a clarification with one of:

1. **Clarification response**: POST an `action` of `clarification_response` to the pending URL.
2. **Updated request**: POST an `action` of `updated_request` with a new `resource_token` to the pending URL.
3. **Cancel request**: DELETE the pending URL.

A POST body MUST include an `action` member. A server MUST reject a POST with a missing or unrecognized `action` with `400 Bad Request`.

#### Clarification Response

```http
POST /pending/abc123 HTTP/1.1
Host: ps.example
Content-Type: application/json
Signature-Key: sig=jwt;jwt="eyJhbGc..."

{
  "action": "clarification_response",
  "clarification_response":
    "I need to create a meeting invite
     for the participants you listed."
}
```

The `clarification_response` value is a Markdown string, presented as agent-asserted content (#consent-presentation). After posting, the agent resumes polling with `GET`.

#### Updated Request

The agent MAY obtain a new resource token from the resource, for example with reduced scope, and POST it to the pending URL together with the `presented_token` it used at the resource to obtain it:

```json
{
  "action": "updated_request",
  "resource_token": "eyJ...",
  "presented_token": "eyJ...",
  "justification": "I've reduced my request to read-only access."
}
```

`presented_token` is REQUIRED. The PS verifies the pair per (#resource-token-verification), including step 3, before replacing the pending request, with the errors of that section. The new resource token MUST have the same `iss`, `ps`, `sub`, `agent_jkt`, `mission_s256`, and `tenant` as the original; its `presented_jti` MAY differ, and MUST equal the `jti` of the `presented_token` sent with it. The PS presents the updated request to the user. A PS answering an AS clarification with `updated_request` sends the same body to the AS pending URL, and the AS verifies the pair the same way (#ps-to-as-token-request). A `justification` is OPTIONAL but RECOMMENDED.

#### Cancel Request

The agent MAY cancel by sending a signed `DELETE` to the pending URL. The PS terminates the consent session and informs the user that the agent withdrew its request. Subsequent requests to the pending URL return `410 Gone`.

### Clarification Limits

PSes MUST enforce a maximum number of clarification rounds; five is RECOMMENDED. Clarification responses are untrusted input and MUST be sanitized before display (#untrusted-input).

## Interaction Endpoint {#interaction-endpoint}

The interaction endpoint lets the agent reach the user through the PS, which may have a better channel to them (an active session, a registered app) than the agent has. The agent uses it to relay interaction requirements from resources (#interaction-relay), to relay payment approvals, and to ask the user questions. Proposing mission completion is not among these; it belongs at the `mission_endpoint` (#mission-completion). The endpoint MAY be used with or without a mission.

### Interaction Request

The agent MUST make a signed POST to the PS's `interaction_endpoint` with an HTTP Sig (#http-message-signatures-profile), presenting its agent token via the `Signature-Key` header.

**Request parameters:**

- `type` (REQUIRED): One of `interaction`, `payment`, or `question`.
- `description` (OPTIONAL): A Markdown string providing context for the user.
- `url` (OPTIONAL): The interaction URL to relay to the user (`interaction` and `payment` types).
- `code` (OPTIONAL): The interaction code associated with the URL.
- `max_wait` (OPTIONAL): Maximum seconds the PS SHOULD hold the relay's deferred response before resolving it (`interaction` and `payment` types). When the interaction URL is resource-hosted, the PS resolves once the user has engaged or this window elapses, whichever comes first (#interaction-response-poll-authority). Absent `max_wait`, the PS resolves when the user has engaged or it can make no further progress.
- `question` (OPTIONAL): A Markdown string containing a question for the user (`question` type).
- `mission_s256` (OPTIONAL): The mission this request belongs to.

```http
POST /interaction HTTP/1.1
Host: ps.example
Content-Type: application/json
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

When the interaction URL is hosted by the **PS itself**, the PS's deferred response is authoritative: the agent polls it until the user completes the interaction.

When the interaction URL is hosted by a **resource**, the user completes the interaction at the resource, and the agent holds two pending URLs: the resource's original `Location` and the PS's relay `Location`. The **resource's** pending URL is authoritative. The PS's relay reports only that the relay reached the user: it returns `status: "interacting"` once the user has engaged, and a terminal response when the PS has done all it can. The agent MUST treat the resource's pending URL as the signal that the interaction is complete, and continues polling it after the PS relay resolves.

If the PS has no channel available to relay this interaction, it returns `interaction_unavailable` (#interaction-endpoint-errors), and the agent falls back to directing the user itself (#interaction-relay). If the PS cannot reach the user and the agent did not declare the `interaction` capability, it returns `user_unreachable` (#token-endpoint-error-codes), which is terminal.

For `question` type, the PS delivers the question to the user and returns the answer:

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "answer": "Yes, go ahead with the refundable option."
}
```

If the mission is no longer active, the PS returns a mission status error (#mission-status-errors). The PS SHOULD record all interaction requests and responses; within a mission it records them in the mission log.

### Interaction Endpoint Errors {#interaction-endpoint-errors}

Errors use the error response format (#error-response-format).

| Error | Status | Meaning |
|-------|--------|---------|
| `interaction_unavailable` | 424 | The PS has no channel available to relay this `interaction` or `payment` to the user. Non-terminal: the agent directs the user to the `url`/`code` itself (#interaction-relay). Distinct from the terminal `user_unreachable` (#token-endpoint-error-codes). |

## Permission Endpoint {#permission-endpoint}

The permission endpoint lets an agent ask the PS before an action no remote resource governs: a tool call, a file write, a message sent on the user's behalf. It gives the person governance over the agent before any resource supports AAuth. It MAY be used with or without a mission. When a mission is active, its approval MAY list pre-approved tools in `approved_tools` (#mission-approval); the agent calls the permission endpoint only for actions not covered by them.

### Permission Request

The agent MUST make a signed POST to the PS's `permission_endpoint` with an HTTP Sig (#http-message-signatures-profile), presenting its agent token via the `Signature-Key` header.

**Request parameters:**

- `action` (REQUIRED): A string identifying the action the agent wants to perform (e.g., a tool name).
- `description` (OPTIONAL): A Markdown string describing what the action will do and why.
- `parameters` (OPTIONAL): A JSON object containing the parameters the agent intends to pass to the action.
- `mission_s256` (OPTIONAL): The mission this request belongs to. When present, the PS evaluates the request against the mission and its log.

```http
POST /permission HTTP/1.1
Host: ps.example
Content-Type: application/json
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
- `denied`: The agent MUST NOT proceed. The response MAY include a `reason` field with a Markdown string.

If the PS requires user input, it returns a deferred response (#deferred-responses) and the agent polls until a final response. If the mission is no longer active, the PS returns a mission status error (#mission-status-errors). The PS SHOULD record all permission requests and responses; within a mission it records them in the mission log.

## Audit Endpoint {#audit-endpoint}

The audit endpoint lets an agent log an action after performing it, so the PS has a complete record of the mission. It requires a mission; there is no audit outside a mission context.

### Audit Request

The agent MUST make a signed POST to the PS's `audit_endpoint` with an HTTP Sig (#http-message-signatures-profile), presenting its agent token via the `Signature-Key` header.

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

The audit endpoint is fire-and-forget; the agent SHOULD NOT block on the response. The PS records the entry in the mission log and MAY use audit records to detect anomalous behavior, alert the user, or revoke the mission. If the mission is no longer active, the PS returns a mission status error (#mission-status-errors).

## Re-authorization {#re-authorization}

AAuth has no refresh token. When an auth token expires, the agent obtains a fresh resource token from the resource and submits it to the PS, the same flow as the initial authorization. This gives the resource a voice in every re-authorization: it can adjust scope, require step-up, or deny on current policy.

When an agent rotates its signing key, every auth token bound to the old key stops working. The agent MUST re-authorize by obtaining fresh resource tokens and submitting them to the PS.

Auth tokens MUST NOT have an `exp` later than the agent token used to obtain them. An agent refreshes its agent token, and the tokens obtained with it, within the margin below.

### Expiry and the Refresh Margin {#refresh-margin}

A token is expired the moment a verifier's clock passes its `exp`, at every party that verifies it (#common-verification). A person token or auth token that a resource names in `presented_jti` is verified by the resource, then by the PS, and in four-party by the AS, with a possible interaction in between, so a token valid at the resource can be expired by the time the AS sees it. And expiry propagates downward: a person token cannot outlive the agent token presented when it was requested, and an auth token cannot outlive the presented token (#auth-token-structure), so a token presented with thirty seconds left buys a thirty-second token.

The agent is the party to absorb this: it holds every token in the chain. An agent SHOULD refresh an agent, person, or auth token when fewer than five minutes remain before its `exp`, and SHOULD NOT present one inside that margin. The margin does not apply to a resource token, whose recommended lifetime is five minutes or less (#resource-token-structure) and which the agent redeems at once. Five minutes is RECOMMENDED because it equals the recommended maximum lifetime of a resource token: a presented token with five minutes left is still valid whenever a resource token issued against it is redeemed.

Refresh runs from the top of the chain: the agent token first (#agent-tokens), then the person token (#person-token-endpoint), then the resource token and auth token against it. Refreshing in the other order produces a token capped by one about to expire.

Refresh is not required when the agent will present the token no further. An agent MAY also renew reactively, presenting an auth token until the resource answers `401` with `expired_jwt` ([@!I-D.hardt-httpbis-signature-key]) and then re-authorizing, for a request that is idempotent and can bear the extra round trip. The margin matters most for a token another party will name and pass on: presenting one inside the margin risks `expired_presented_token` downstream (#token-endpoint-error-codes) after the resource has already accepted it.

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

The agent creates a mission by sending a proposal to the PS's `mission_endpoint`. The agent MUST make a signed POST with an HTTP Sig (#http-message-signatures-profile), presenting its agent token via the `Signature-Key` header under the `jwt` scheme.

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
  "mission": "eyJhZ2VudCI6ImFhdXRoOmFzc2lzdGFudEBhZ2VudC5leGFtcGxlIiwiYXBwcm92...",
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

- `agent`: The agent identifier (`aauth:local@domain`).
- `approved_at`: ISO 8601 timestamp of when the mission was approved. Ensures the `s256` is globally unique.
- `description`: Markdown string describing the approved mission scope.

The mission blob MAY include:

- `expires_at`: ISO 8601 timestamp after which the PS treats the mission as terminated. When absent, the mission runs until it is completed or revoked. Every PS decision path that acts on a mission MUST compare the current time to `expires_at` and MUST treat a mission past it as terminated (#mission-status-errors). The PS caps the person tokens and auth tokens it issues at `expires_at` (#person-token-structure) and (#auth-token-structure), and the presented token carries that bound to an AS (#ps-to-as-token-request); a resource token's lifetime is independent of it (#resource-token-structure).
- `approved_tools`: Array of tool objects (each with `name` and `description`) that the agent may use without per-call permission at the PS's permission endpoint (#permission-endpoint). Nothing in the protocol enforces this list; see (#why-tools-are-not-enforced).
- `approved_resources`: Array of resource identifiers the person approved for this mission, drawn from the `resources` the proposal named. It records which resources were pre-approved, so an audit of the mission shows what the person agreed to before the agent began. It is not a limit: the agent MAY obtain person tokens for other resources during the mission, subject to the PS's policy, and those accesses appear in the mission log rather than in the blob.

The member lists above are a floor, not a closed set. A PS MAY include additional members, and a companion specification MAY define them; a reader MUST ignore members it does not recognize (#aauth-capabilities). Because `s256` covers the bytes the PS persists, a blob carrying an additional member has a different identifier from one without — which is correct, since they are different missions. Member names in the mission blob are governed by this specification; a companion specification defining one SHOULD coordinate the name to avoid collision.

### Mission Identifier {#mission-identifier}

`s256` identifies the mission everywhere it appears — as the `mission_s256` claim of person, resource, and auth tokens, and as the `mission_s256` parameter of PS requests. The PS that approved the mission is named beside it: by the `iss` of a person token, the `ps` claim of a resource or auth token, and the PS a request is made to. The pair is the mission's identity; the blob carries no approver member, since the approver is always the PS.

It is a hash rather than an opaque identifier so that it is provable. An opaque identifier would name the mission but leave the PS free to attach it to any text afterwards. A digest binds every token carrying `mission_s256` to one specific mission, so the mission in the PS's log and the mission those tokens authorized are demonstrably the same. Verification is available to the agent at approval and to anyone holding the blob later.

The PS MUST compute `s256` over the exact bytes it persists as the mission blob, MUST return those same bytes as `mission`, and MUST serve them wherever it later exposes the mission for audit.

The approved description MAY differ from the proposal — the PS or user may refine, constrain, or expand the mission during review. The approved tools MAY be a subset of the proposed tools. The agent uses `s256` as `mission_s256` when requesting further person tokens (#person-token-endpoint).

## Mission Log {#mission-log}

The approved mission description is immutable — the `s256` hash binds it permanently. Missions do not change; they accumulate context.

All agent interactions with the PS within a mission context form the **mission log**: token requests (with justifications), accepted updates (#mission-update), permission requests and responses, audit records, interaction requests, and clarification chats. The PS maintains this log as an ordered record of the agent's actions and the supervision decisions made. The mission log gives the PS the full history it needs to evaluate whether each new request is consistent with the mission's intent.

The agent names the mission when it requests a person token (#person-token-endpoint); the PS validates it and stamps `mission_s256` into the token, from where it flows into the resource token and the auth token. When the agent sends a resource token to its PS, the PS evaluates the request against the mission context and log history before federating with the resource's AS.

## Mission Update {#mission-update}

Work changes. When what the agent is doing no longer matches the description the person approved, it records the change rather than proceeding silently:

```http
POST /mission/dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk HTTP/1.1
Host: ps.example
Content-Type: application/json
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

This section defines auth tokens and the mechanisms by which they are issued. The auth token is the end result of the authorization flow — a JWT issued by an access server, or by a PS in three-party access, that grants an agent access to a specific resource. This section covers the AS token endpoint, PS-AS federation, and the auth token structure.

## AS Token Endpoint {#as-token-endpoint}

The AS evaluates resource policy and issues auth tokens. It accepts JSON POST requests.

### PS-to-AS Token Request {#ps-to-as-token-request}

The PS MUST make a signed POST to the AS's `auth_token_endpoint`. The PS authenticates via an HTTP Sig (#http-message-signatures-profile).

**Request parameters:**

- `resource_token` (REQUIRED): The resource token issued by the resource.
- `agent_token` (REQUIRED): The agent's agent token. For a parent-mediated sub-agent authorization, this is the parent (top-level) agent's token.
- `presented_token` (REQUIRED): The token named by the resource token's `presented_jti`, passed through from the agent's token request (#ps-token-endpoint). A person token carries the identity the resource saw — `sub`, `tenant`, and `mission_s256` when present — under the PS's signature; an auth token carries it under the signature of the server that issued it, which on a step-up in four-party is this AS. Its `exp` bounds the auth token the AS issues (#auth-token-structure). A PS MUST NOT present an expired token; it rejects the agent's token request with `expired_presented_token` (#token-endpoint-error-codes), and the agent obtains a fresh person token and a fresh resource token.
- `subagent_token` (OPTIONAL): A sub-agent's agent token, present when the PS federates a parent-mediated sub-agent authorization (#sub-agents). When present, the AS binds the issued auth token to the sub-agent, verifying `resource_token`'s `agent_jkt` against the `subagent_token`'s `cnf.jwk`.
- `upstream_token` (OPTIONAL): The `upstream_token` of the agent's token request, passed through (#call-chaining). The AS MUST verify it per (#upstream-token-verification). `agent_token` is then the intermediary's agent token.

The resource token carries the person's identity as `ps` and `sub` (#resource-token-structure), and the presented token carries the same identity under its issuer's signature, so the AS needs no separate identity parameter and `requirement=claims` (#requirement-claims) is reserved for claims beyond it.

The AS MUST verify `presented_token` against the resource token per step 3 of (#resource-token-verification), which is the same check the PS made. A person token's `iss` and an auth token's `ps` MUST be the PS that signed this request. The errors are those of that step: `invalid_presented_token`, `expired_presented_token`, and `invalid_resource_token` for a mismatch.

`agent_token` remains REQUIRED even though the resource never sees an agent identifier. A resource deploys an AS because it wants policy evaluated, and an agent token MAY carry claims bearing on that decision — software attestation, platform integrity, secure enclave status, workload identity (#agent-token-structure). The resource enforces; the AS evaluates; posture goes to the evaluator.

**Example request:**
```http
POST /token HTTP/1.1
Host: as.resource.example
Content-Type: application/json
Signature-Key: sig=jwks_uri;id="https://ps.example";
    dwk="aauth-person.json";kid="key-1"

{
  "resource_token": "eyJhbGc...",
  "agent_token": "eyJhbGc...",
  "presented_token": "eyJhbGc..."
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

- **`requirement=claims`** (#requirement-claims): The AS needs identity claims. The body includes `required_claims`. The PS MUST provide the requested claims by POSTing to the `Location` URL. The AS cannot know what claims it needs until it has processed the resource token.
- **`requirement=clarification`** (#requirement-clarification): The AS needs a question answered. The PS triages who answers: itself (if mission context has the answer), the user, or the agent. The PS MAY pass the clarification down to the agent via a `202` response.
- **`requirement=interaction`** (#requirement-responses): The AS requires user interaction — for example, the user must authenticate at the AS to bind their PS, or the resource owner must approve access. The PS directs the user to the AS's interaction URL, or passes the interaction requirement back to the agent.
- **`requirement=approval`** (#requirement-responses): The AS is obtaining approval without requiring user direction.

**Payment required** (`402`):

The AS MAY return `402 Payment Required` when a billing relationship is required before it will issue auth tokens. The `402` response includes payment details per an applicable payment protocol such as x402 [@x402] or the Payment scheme ([@?I-D.ryan-httpauth-payment]). The response MUST include a `Location` header for the PS to poll after payment is settled.

```http
HTTP/1.1 402 Payment Required
Location: https://as.resource.example/token/pending/xyz
WWW-Authenticate: Payment id="x7Tg2pLq", method="stripe",
    request="eyJhbW91bnQiOiIxMDAw..."
```

The PS settles payment per the indicated protocol and polls the `Location` URL. When payment is confirmed, the AS continues processing the token request — which may result in a `200` with an auth token, or a further `202` requiring claims, interaction, or approval.

The PS caches the billing relationship per AS. Future token requests from the same PS to the same AS skip the billing step. The payment protocol, settlement mechanism, and billing terms are out of scope for this specification.

### Auth Token Delivery {#auth-token-delivery}

When the AS issues an auth token (`200` response), the PS MUST verify the auth token before returning it to the agent:

1. Verify the auth token JWT signature using the AS's JWKS (#jwks-discovery).
2. Verify `iss` matches the AS the PS sent the token request to.
3. Verify `aud` matches the resource identified by the resource token's `iss`.
4. Verify `cnf.jwk` matches the agent's signing key.
5. Verify `sub` matches the directed identifier the PS issues for this person at this resource.
6. Verify `scope` is consistent with what was requested — not broader than the scope in the resource token.
7. Verify `exp` does not exceed the `exp` of the `presented_token` the PS presented (#ps-to-as-token-request).

After verification, the PS returns the auth token to the agent. The agent presents the auth token to the resource via the `Signature-Key` header (#auth-token-usage). The resource verifies the auth token against the AS's JWKS (#auth-token-verification).

When the AS answers with a well-formed terminal error, the PS relays it: the response to the agent carries the AS's `error` value and status in the PS's own problem+json body (#error-response-format), so that an AS denial and a federation failure are distinguishable. When the PS cannot obtain a verifiable auth token at all — the AS is unreachable, times out, returns a malformed response, or returns an auth token that fails the verification above — the PS returns `as_unreachable` (#token-endpoint-error-codes). Either outcome reaches the agent on its pending request when the token request was deferred.

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

The recipient MUST provide the requested claims by POSTing to the `Location` URL. The person is already identified by the presented token (#ps-to-as-token-request): `sub` is a claim of every person token and auth token, never a requested one. An AS MUST NOT request it, and a PS MUST NOT include it in the response. The recipient MUST include an HTTP Sig (#http-message-signatures-profile) on the POST. Claims not recognized by the recipient SHOULD be ignored. This requirement is used by ASes to request identity claims from PSes during token issuance.

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
  |  agent_token,           |                       |
  |  presented_token        |                       |
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
  |  {email, tenant}        |                       |
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

### PS-AS Collapse {#ps-as-collapse}

When the agent's PS and the resource's chosen AS are the same server (an instance of role collocation, see (#roles)), federation collapses to a single internal evaluation. This is operationally similar to three-party access — no cross-server hop — but structurally different:

- **Three-party (PS authorization)**: the resource has no AS; the resource token's `aud` is the PS, and the auth token has `dwk: aauth-person.json`. The resource trusts identity claims and applies its own policy.
- **PS-AS collapse**: the resource has chosen an AS that also operates as the agent's PS; the resource token's `aud` is the AS, and the auth token has `dwk: aauth-access.json`. The resource trusts the AS's policy verdict.

The server applies user consent (its PS responsibility) and resource policy (its AS responsibility) in a single evaluation. Trust between PS and AS is implicit because they are the same entity. This is the common shape for an organization: its agents share one PS and its internal resources one AS, the PS gives centralized audit across every agent and mission, and federation is incurred only at the boundary, when an internal agent reaches an external resource.

## Auth Token {#auth-tokens}

### Auth Token Structure

An auth token is a JWT with `typ: aa-auth+jwt`. Its header and the claims `iss`, `dwk`, `jti`, `iat`, `exp`, and `cnf` are as defined in (#common-claims), with:

- `iss`: The URL of the server that issued the auth token — an AS (four-party) or a PS (three-party)
- `dwk`: `aauth-access.json` when issued by an AS, `aauth-person.json` when issued by a PS
- `cnf`: `jwk` is the agent's public key
- `exp`: Auth tokens MUST NOT have a lifetime exceeding 1 hour, MUST NOT expire later than the agent token used to obtain them (#re-authorization), and MUST NOT expire later than the `presented_token` of the token request (#ps-token-endpoint) and (#ps-to-as-token-request) — a person token, which the PS capped at the mission's `expires_at` when `mission_s256` is present (#person-token-structure), or an auth token bounded the same way in its turn. When the token request carried `upstream_token` (#call-chaining), the auth token MUST NOT expire later than that token either. A PS-issued auth token carrying `mission_s256` MUST NOT expire later than the mission's `expires_at` (#mission-approval).

Required payload claims specific to auth tokens:
- `aud`: The URL of the resource the agent is authorized to access.
- `ps`: The person server the person is represented by. Equal to `iss` when a PS issued the token. An intermediary acting as an agent routes its downstream token request here (#call-chaining).
- `sub`: Directed user identifier, copied from the resource token. An opaque string, unique within `iss`, that identifies the person. The PS SHOULD derive a pairwise pseudonymous value per resource (`aud`), so different resources see different values for the same person (#directed-identifiers).
An auth token carries no agent identifier and no delegation chain. `cnf` binds it to one key, and the resource enforces against `sub` and `scope`.

Optional payload claims:
- `scope`: Authorized scopes, as a space-separated string of scope values consistent with [@!RFC9068] Section 2.2.3
- `account`: The account the authorization is for, copied from the resource token (#account-binding).
- `mission_s256`: Copied from the resource token when it carried one. Present when the auth token was issued in the context of a mission.
- `tenant`: Tenant identifier per OpenID Connect Enterprise Extensions 1.0 [@OpenID.Enterprise], declaring the organization the person belongs to. `(iss, tenant)` identifies the organization. It is not part of the person's identifier, which is `(iss, sub)`.

The auth token MAY include additional claims registered in the IANA JSON Web Token Claims Registry [@!RFC7519] or defined in OpenID Connect Core 1.0 [@!OpenID.Core] Section 5.1.

### Auth Token Usage

Agents present auth tokens via the `Signature-Key` header ([@!I-D.hardt-httpbis-signature-key]) under the `jwt` scheme:

```http
Signature-Key: sig=jwt;
    jwt="eyJhbGciOiJFZDI1NTE5IiwidHlwIjoiYWEtYXV0aCtqd3QiLCJraWQiOiJhcy1rZXktMSJ9..."
```

Once an auth token has been issued for a resource, the agent presents the auth token (not the agent token) via `Signature-Key` on subsequent requests to that resource. The auth token's `cnf.jwk` is the same key that signed the request, so HTTP Message Signature verification proceeds identically to the agent-token case.

### Auth Token Verification

A valid JWT signature alone is not a complete AAuth authorization check — both JWT trust and request-context binding must pass.

#### JWT Trust Verification

1. Verify the token per (#common-verification), with `typ` `aa-auth+jwt` and `dwk` `aauth-access.json` (auth token from an AS) or `aauth-person.json` (auth token from a PS).

#### Request-Context Binding

2. Verify `aud` matches the resource's own identifier.
3. `cnf.jwk` is REQUIRED. If it is absent, or if its JWK is missing `kty` or the members required for that key type (e.g., `crv` and `x` for OKP keys; `crv`, `x`, and `y` for EC keys; `n` and `e` for RSA keys), reject the token as structurally incomplete before attempting key decoding. If present but not parseable as a supported public key, reject it as invalid key material. Otherwise verify `cnf.jwk` matches the key used to sign the HTTP request.
4. Verify `sub` is present, and that `(iss, sub)` matches or establishes the resource's record for this person (#trust-posture-in-ps-asserted-access).

### Auth Token Response Verification {#auth-token-response-verification}

When an agent receives an auth token:

1. SHOULD verify the auth token JWT signature using the issuer's JWKS (the AS in four-party, or the PS in three-party). The agent trusts its PS, so signature verification is not required but is RECOMMENDED to detect errors early.
2. Verify `iss` matches the resource token's `aud` claim.
3. Verify `aud` matches the resource the agent intends to access.
4. Verify `cnf.jwk` matches the agent's own signing key.
5. Verify `sub` matches the value in the token it presented to that resource.

### Upstream Token Verification {#upstream-token-verification}

An `upstream_token` is a person token or an auth token. The recipient reads `typ` to tell which, and rejects any other `typ` with `invalid_upstream_token`. Accepting a person token here does not stand it in for an auth token (#person-token-not-authorization): the parameter is evidence of who the intermediary is acting for, and grants nothing by itself.

The intermediary's agent token is the one that signed the request at the PS, presented in the `Signature-Key` header, and the `agent_token` parameter at the AS, where the PS signed the request (#ps-to-as-token-request). When the PS or AS receives an `upstream_token` parameter in a call chaining request:

1. Verify the upstream token per Person Token Verification (#person-token-verification) or Auth Token Verification (#auth-token-verification), with these substitutions: `aud` MUST equal the intermediary's identifier rather than the verifier's own; `cnf.jwk` is the calling agent's key and is not compared with the key that signed this request, which is the intermediary's; and for an auth token the resource's record check on `sub` does not apply. A token that fails is rejected with `invalid_upstream_token`, `expired_upstream_token` when only `exp` fails, or `revoked_upstream_token` when the recipient holds a revocation for it (#token-revocation).
2. Verify the issuer. At the PS: a person token's `iss` MUST be this PS; an auth token's `ps` MUST be this PS, and its `iss` MUST be this PS or an AS this PS presented a person token to for that token's `aud` and `sub` (#ps-to-as-token-request). At the AS: a person token's `iss`, or an auth token's `ps`, MUST be the PS that signed the request. The AS does not check an auth token's `iss` beyond verifying its signature; the PS has already done so.
3. Verify the upstream token's `aud` equals the `iss` of the intermediary's agent token. The intermediary is its own agent provider (#intermediary-agent-identity), so this is the one comparison that ties the token the calling agent presented to the party now making the downstream request. A mismatch is rejected with `invalid_upstream_token`.
4. At the PS, identify the calling agent from its own records: the agent it issued the upstream person token to, or the one it issued the person token to that the upstream auth token was obtained with. If the PS has revoked that agent's agent token or its binding to the person (#agent-person-binding), it MUST reject the request with `revoked_upstream_token`, whether or not it has revoked the upstream token itself. A PS that cannot identify the calling agent MUST reject the request with `invalid_upstream_token`.
5. The PS evaluates the request against the mission and its supervision policy, based on the upstream token's claims and mission context. The resulting downstream authorization is not required to be a subset of any upstream authorization — see (#call-chaining).

# Agent Delegation {#agent-delegation}

Agent delegation covers the scenarios where more than one agent is involved in fulfilling a request: a resource that acts as an agent to call a downstream resource (call chaining), and an orchestrating agent that spawns sub-agents.

## Multi-Hop Resource Access {#multi-hop}

This section defines how resources act as agents (an instance of role collocation, see (#roles)) to access downstream resources on behalf of the original caller. In multi-hop scenarios, a resource that receives an authorized request needs to access another resource to fulfill that request. The resource acts as an agent — it has its own agent identity and signing key — and routes the downstream authorization to obtain an auth token for the downstream resource.

### Call Chaining {#call-chaining}

When a resource needs to access a downstream resource on behalf of the caller, it acts as an agent — the intermediary. The upstream token is a token the calling agent presented in the `Signature-Key` header of a request the intermediary served: a person token when the intermediary served on the person's identity (#overview-person-identity), an auth token when it required authorization. A person token the intermediary answered with a challenge for an auth token is not one: the request it came on was not served (#person-token-not-authorization).

An intermediary MAY present the same upstream token for any number of downstream requests until it expires. Downstream access does not outlive it: a person token issued with `upstream_token` expires no later than the upstream token (#person-token-structure), and so does an auth token issued on a request carrying one (#auth-token-structure). Once the upstream token has expired the intermediary uses a later token from the calling agent, which it receives on the agent's next request. A pending downstream request (#deferred-responses) whose upstream token expires before it completes ends with `expired` (#polling-error-codes), and the intermediary starts over with a later upstream token.

The intermediary routes the downstream token requests to the person server the upstream token names: the `iss` of a person token, the `ps` of an auth token. The `ps` claim in the intermediary's own agent token, if it has one, is NOT used for this routing — it names the intermediary's person server, not the person's.

The intermediary first obtains a person token for the downstream resource, presenting the upstream token as `upstream_token` (#person-token-endpoint). It then presents that person token at the downstream resource, receives a resource token, and sends it to the same person server's auth token endpoint, along with the person token as `presented_token` and the upstream token as `upstream_token` (#ps-token-endpoint). The PS evaluates the downstream request against the mission context when the upstream token carries `mission_s256`.

In every case the intermediary signs the downstream token request with its **own** key, presenting its own agent token via the `Signature-Key` header (#http-message-signatures-profile). The `upstream_token` is a body parameter — it is neither presented via `Signature-Key` nor used as the signing key. Its `aud` is the intermediary and its `cnf` is the calling agent's key, not the intermediary's, and it serves only as evidence of who the intermediary is acting for. The signature the recipient verifies is therefore always the intermediary's, over its own key.

The recipient evaluates the downstream request per (#upstream-token-verification).

#### Intermediary Agent Identity {#intermediary-agent-identity}

An intermediary MUST be its own agent provider. It MUST publish agent metadata at `/.well-known/aauth-agent.json` on its own origin, with `issuer` equal to the `issuer` of its resource metadata (#resource-metadata), and MUST sign downstream token requests with an agent token it issued to itself. That agent token's `iss` is therefore the intermediary's resource identifier, and its `sub` is an agent identifier whose `domain` is the intermediary's host (#agent-identifiers).

This is how a recipient knows the intermediary is the party the calling agent presented the upstream token to. The upstream token's `aud` is a resource identifier, and the only resource-scoped identifier a signed downstream request carries is the `iss` of the agent token that signed it; step 3 of (#upstream-token-verification) compares the two. Resolving the agent token's signing key from `{iss}/.well-known/aauth-agent.json` proves that the key belongs to that origin. An agent token issued by any other agent provider names the provider, not the resource, and nothing in it ties the signer to the upstream token's `aud`, so a recipient rejects the request with `invalid_upstream_token`.

An intermediary acts for every person whose requests it fulfills, so its agent token is not bound to one person (#agent-person-binding). The PS issues for the person the upstream token identifies (#person-token-endpoint), never for a person bound to the intermediary. An intermediary MAY use one agent identifier for all the requests it chains; the PS does not key person resolution or policy on it.

#### Directed Identifiers Across a Chain {#directed-sub-chaining}

The `sub` of an auth token is a directed identifier: a PS SHOULD issue a pairwise pseudonymous value per resource, so that two resources serving the same person cannot correlate them by comparing tokens (#auth-tokens) and (#directed-identifiers). Identity is the pair `(iss, sub)` — a `sub` minted by one issuer for one audience carries no meaning under a different issuer for a different audience.

A downstream issuer sees the upstream `sub` in the `upstream_token` it is handed. It MUST NOT carry that value forward:

1. An issuer MUST NOT copy a directed `sub` from an upstream token into a token it issues.
2. The `sub` it issues is the directed identifier for the person at the downstream resource, taken from the downstream resource token, which the resource copied from the person token the PS issued for that resource.

Because the intermediary obtains a person token for the downstream resource before calling it (#person-token-endpoint), the PS has already minted a downstream-directed identifier by the time the resource token exists. The chain never needs to carry a `sub` forward, and never leaves a downstream token without one.

Copying instead would fail in both directions at once. The value would be meaningless under the new issuer, so the downstream resource would either misidentify the person or key state to an identifier no one can resolve; and the same string appearing at two resources is exactly the correlation handle pairwise identifiers exist to prevent, handed to a party the user never consented to share it with.

Note that downstream authorization is not required to be a subset of the upstream scopes. A downstream resource may have capabilities that are orthogonal to the upstream resource — for example, a flight booking API that calls a payment processor needs the payment processor to charge a card, an operation the user and original agent could never perform directly. The downstream resource's scope is constrained by its own AS policy and the PS's evaluation of the mission context, not by the upstream token's scope. The PS provides the supervision constraint — it evaluates each hop independently and can deny requests that fall outside the mission or the user's intent — where a formal subset rule would prevent legitimate delegation chains.
### Interaction Chaining {#interaction-chaining}

When the PS or AS requires user interaction for the downstream access, it returns a `202` with `requirement=interaction`. Resource 1 chains the interaction back to the original agent by returning its own `202`.

When a resource acting as an agent receives a `202 Accepted` response with `AAuth-Requirement: requirement=interaction`, and the resource needs to propagate this interaction requirement to its caller, it MUST return a `202 Accepted` response to the original agent with its own `AAuth-Requirement` header containing `requirement=interaction` and its own interaction code. The resource MUST provide its own `Location` URL for the original agent to poll. When the user completes interaction and the resource obtains the downstream auth token, the resource completes the original request and returns the result at its pending URL.

## Sub-Agents {#sub-agents}

Agent platforms increasingly spawn short-lived sub-agents — workers or tool-specific helpers — under an orchestrating parent agent. AAuth represents a sub-agent as an agent whose agent token carries a `parent_agent` claim identifying its parent. The user consents to the parent; sub-agents operate under that consent without per-spawn re-prompting, while remaining individually identifiable for audit and revocation.

### Sub-Agent Identity

A sub-agent has its own agent identity — its own `aauth:local@domain` identifier and signing key, issued by its parent's agent provider, exactly like a top-level agent. The `iss` of a sub-agent's agent token MUST equal the `iss` of its parent's, and a PS MUST reject a `subagent_token` whose `iss` differs from that of the signing agent's token with `invalid_subagent_token`. Two things distinguish it:

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
3. The parent POSTs to the PS's `auth_token_endpoint`, signing the request with its own key and presenting its own agent token via the `Signature-Key` header. The request body includes `resource_token` (the sub-agent's resource token), `presented_token` (the token the sub-agent presented to the resource: the person token from step 1, or the sub-agent's auth token on a step-up), and `subagent_token` (the sub-agent's agent token).
4. The PS processes this as an authorization request from the parent (#ps-token-endpoint):
   - It verifies the HTTP Message Signature against the parent's `cnf.jwk`.
   - It verifies the `subagent_token` (#agent-token-verification) and that its `parent_agent` names the parent — the agent that signed the request.
   - It verifies the `resource_token` is bound to the sub-agent's key: `agent_jkt` matches the `subagent_token`'s `cnf.jwk`, not the signing key (#resource-token-verification).
   - It evaluates the parent's grant for the requested scope, exactly as for a direct request from the parent. If the user has already consented, the response is immediate; otherwise consent surfaces for the parent as usual.
5. On success the issuer — the PS in three-party, or the AS in four-party — issues an auth token bound to the sub-agent's key (`cnf` = the sub-agent's `jwk`). In four-party, the PS federates by passing the parent as `agent_token` and the sub-agent as `subagent_token` to the AS (#as-token-endpoint), so the AS records the parent authoritatively from those tokens. The parent passes the auth token to the sub-agent, which presents it to the resource signing with its own key.

The sub-agent relationship is recorded by the PS, which issued both tokens and holds the `parent_agent` binding. It does not appear in the tokens the resource sees.

Because every sub-agent authorization passes through the parent, the parent retains control — it can refuse, attenuate, or rate-limit — and revocation propagates naturally: revoking the parent's grant causes the next sub-agent authorization to fail, while existing auth tokens expire normally (≤1 hour).

# Protocol Primitives {#protocol-primitives}

This section is the normative reference for the mechanisms the preceding sections use: identifiers, metadata documents, HTTP message signatures, key discovery, the common JWT profile, requirement responses, capabilities, deferred responses, error responses, scopes, account binding, and token revocation. Context for each is given where it is first used.

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

### Endpoint and Other URLs

The `auth_token_endpoint`, `person_token_endpoint`, `authorization_endpoint`, `mission_endpoint`, and `callback_endpoint` values MUST use the `https` scheme and MUST NOT contain a query string or a fragment. The `jwks_uri`, `tos_uri`, `policy_uri`, `logo_uri`, and `logo_dark_uri` values MUST use the `https` scheme.

One exception: when `localhost_callback_allowed` is `true` in the agent's metadata, the agent MAY use a loopback callback URL with the `http` scheme (`http://localhost` or `http://127.0.0.1`, any port) as the `callback` parameter to the interaction endpoint, in place of its `callback_endpoint`.

## Metadata Documents {#metadata-documents}

Participants publish metadata at well-known URLs ([@!RFC8615]).

When fetching a metadata document, implementations MUST verify that it contains an `issuer` member, and that the `issuer` value matches the URL the document was retrieved from (the URL minus the `/.well-known/{dwk}` suffix), compared by byte equality. A document with no `issuer` MUST be rejected with `issuer_missing`; one whose `issuer` does not match MUST be rejected with `issuer_mismatch` ([@!I-D.hardt-httpbis-signature-key]). This is the check [@!RFC8414], Section 3.3 requires of authorization server metadata, and it prevents a document hosted at one domain from claiming the `issuer` of another.

The following fields are defined identically across all four metadata documents (`aauth-agent.json`, `aauth-resource.json`, `aauth-person.json`, `aauth-access.json`):

| Field | Requirement | Description |
|-------|-------------|-------------|
| `issuer` | REQUIRED | The server's HTTPS URL. MUST match the URL the document was fetched from. Placed in the `iss` claim of JWTs issued by this server. |
| `jwks_uri` | REQUIRED (see per-role) | URL to the server's JSON Web Key Set. |
| `accept_signature_algs` | OPTIONAL | JSON array of fully-specified JWS algorithm identifiers the server's verifier accepts, exactly the set. Same semantics as the `Accept-Signature-Alg` response header ([@!I-D.hardt-httpbis-signature-key]). One list per server, covering every endpoint. A server MAY omit it. |
| `name` | OPTIONAL | Human-readable display name. |
| `description` | OPTIONAL | Markdown string describing the server, for display at consent screens or dashboards. Implementations MUST sanitize before rendering. |
| `logo_uri` | OPTIONAL | URL to the server's logo. MUST use `https`. |
| `logo_dark_uri` | OPTIONAL | URL to the server's logo for dark backgrounds. MUST use `https`. |
| `documentation_uri` | OPTIONAL | URL with developer documentation. MUST use `https`. |
| `tos_uri` | OPTIONAL | URL to terms of service. MUST use `https`. |
| `policy_uri` | OPTIONAL | URL to privacy policy. MUST use `https`. |

AAuth uses `issuer` rather than the `resource` field of RFC 9728, and unprefixed field names rather than RFC 9728's `resource_`-prefixed forms (#why-issuer-not-resource).

The per-role sections below list role-specific fields and role-specific requirement differences.

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

Role-specific fields:

- `issuer` (REQUIRED): The agent provider's HTTPS URL (the `domain` in agent identifiers it issues). Placed in the `iss` claim of agent tokens.
- `jwks_uri` (REQUIRED): URL to the agent provider's JSON Web Key Set.
- `callback_endpoint` (OPTIONAL): The agent's HTTPS callback endpoint URL (#user-interaction).
- `event_endpoint` (OPTIONAL): HTTPS URL at which the AP receives event tokens from resources. Required if the AP supports AAuth Events ([@?I-D.hardt-aauth-events]).
- `localhost_callback_allowed` (OPTIONAL): Boolean. Default: `false`.

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

Role-specific fields:

- `issuer` (REQUIRED): The PS's HTTPS URL. Placed in the `iss` claim of JWTs issued by the PS.
- `jwks_uri` (REQUIRED): URL to the PS's JSON Web Key Set.
- `auth_token_endpoint` (REQUIRED): URL where agents send token requests (#ps-token-endpoint).
- `person_token_endpoint` (REQUIRED): URL where agents request a person token for a resource (#person-token-endpoint).
- `mission_endpoint` (OPTIONAL): URL where an agent proposes, updates, and completes the missions it owns (#missions). A mission's own URL is `{mission_endpoint}/{mission_s256}`.
- `permission_endpoint` (OPTIONAL): URL where agents request permission for actions not governed by a remote resource (#permission-endpoint).
- `audit_endpoint` (OPTIONAL): URL where agents log actions performed (#audit-endpoint).
- `interaction_endpoint` (OPTIONAL): URL where agents relay interactions to the user through the PS (#interaction-endpoint).
- `mission_control_endpoint` (OPTIONAL): URL of the PS's mission control plane, where parties other than the owning agent read and manage missions (#mission-management). Its authentication model, operations, and responses are out of scope for this document. A PS MAY also use it for a deployment's human-facing administrative interface. **Editor's note:** a mission control companion specification is TBD.
- `revocation_endpoint` (RECOMMENDED): URL where an agent provider revokes an agent token it issued, and where a resource revokes a resource token this PS holds (#token-revocation).
- `scopes_supported` (RECOMMENDED): Array of scope values the PS supports, including identity scopes (e.g., `openid`, `profile`, `email`) and enterprise scopes (e.g., `tenant`, `groups`, `roles`).
- `claims_supported` (RECOMMENDED): Array of identity claim names the PS can provide (e.g., `sub`, `email`, `name`, `tenant`).

The four REQUIRED fields (`issuer`, `jwks_uri`, `auth_token_endpoint`, `person_token_endpoint`) are the whole of what a conformant PS publishes. The OPTIONAL endpoints add missions, permission checks, audit, and the relay channel to the person; they do not add conformance.

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

Role-specific fields:

- `issuer` (REQUIRED): The AS's HTTPS URL. Placed in the `iss` claim of auth tokens.
- `jwks_uri` (REQUIRED): URL to the AS's JSON Web Key Set.
- `auth_token_endpoint` (REQUIRED): URL where PSes send token requests (#as-token-endpoint).
- `revocation_endpoint` (RECOMMENDED): URL where a PS revokes a person token it presented to this AS, and where a resource revokes a resource token whose `aud` is this AS (#token-revocation).

### Resource Metadata {#resource-metadata}

Published at `/.well-known/aauth-resource.json`. A resource MAY publish this document, and SHOULD point agents at it from pages they reach first (#resource-metadata-link). A resource that publishes none can still verify identity-based access and issue resource tokens and interaction requirements via `401` responses.

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

Role-specific fields:

- `issuer` (REQUIRED): The resource's HTTPS URL. Placed in the `iss` claim of resource tokens.
- `jwks_uri` (REQUIRED when the resource issues resource tokens or makes signed calls): URL to the resource's JSON Web Key Set. A resource that only verifies agent signatures has no keys to publish and MAY omit it.
- `access_mode` (OPTIONAL): The credential flow the resource expects, so an agent can plan its first call. Values defined by this document: `agent-token` (the agent signs with its agent token), `person-token` (the agent signs with a person token), `session-token` (the agent completes the resource's interaction flow and receives a session token via `AAuth-Access`), and `auth-token` (the agent obtains an auth token from its PS using a resource token; the initial call MUST present a person token). Default: `agent-token`. Extensions MAY define further values, recorded in the AAuth Access Mode Value Registry (#aauth-access-mode-value-registry); R3 ([@?I-D.hardt-aauth-r3]) defines `per-call`. An agent that does not recognize a value proceeds as with no declaration. The declaration is advisory: a resource MAY return any `AAuth-Requirement` at runtime (#requirement-responses) and MAY apply different modes to different endpoints. An agent MAY use `access_mode` to skip resources its setup cannot satisfy, for example a PS-less agent and `auth-token`.
- `authorization_endpoint` (OPTIONAL): URL where agents request authorization (#authorization-endpoint-request). When absent, the resource issues resource tokens and interaction requirements via `401` responses.
- `scope_descriptions` (OPTIONAL): Object mapping scope values to Markdown strings for consent display (#scopes).
- `signature_window` (OPTIONAL): Integer. The signature validity window in seconds for the `created` timestamp (#verification). Default: 60. A resource MAY advertise a larger value for agents with poor clock synchronization, or a smaller one.
- `additional_signature_components` (OPTIONAL): Array of HTTP message component identifiers ([@!RFC9421]) that agents MUST include in the `Signature-Input` covered components when signing requests to this resource, in addition to the base components (#covered-components).
- `revocation_endpoint` (RECOMMENDED for a resource that accepts person tokens): URL where the issuer of an auth token or person token for this resource revokes it (#token-revocation). A resource that accepts only agent tokens receives no revocations and need not publish one.

### Resource Metadata Link Relation {#resource-metadata-link}

The `aauth-resource` link relation ([@!RFC8288]) lets any HTTP response, and any HTML page, name the resource metadata document that governs what the response describes. It serves an agent that has reached a developer portal or an API host and does not yet have the resource identifier to append `/.well-known/aauth-resource.json` to.

A server MAY include a `Link` header field in any response:

```http
Link: <https://api.example/.well-known/aauth-resource.json>;
    rel="aauth-resource"
```

An HTML document MAY carry the same relation as a `link` element in its `head`:

```html
<link rel="aauth-resource"
      href="https://api.example/.well-known/aauth-resource.json">
```

The target MUST be a server identifier (#server-identifiers) followed by `/.well-known/aauth-resource.json`. An agent MUST NOT fetch a target of any other form. Having fetched it, the agent verifies the document as any metadata document (#metadata-documents): its `issuer` MUST equal the target minus the well-known suffix.

A resource SHOULD include the relation on the page at its `documentation_uri`. A response MAY carry more than one `aauth-resource` link when it describes several resources, each a resource identifier of its own. The relation says nothing about the response that carries it: a `401` from a resource endpoint still carries its requirement in `AAuth-Requirement`, and an agent MUST NOT treat the link as a substitute for it.

Verifiers do not use this relation. A party verifying a token or a signature discovers keys from the signer's `iss` and `dwk` ([@!I-D.hardt-httpbis-signature-key]), never from a link in content (#link-relation-security).

## HTTP Message Signatures Profile {#http-message-signatures-profile}

This section profiles HTTP Message Signatures ([@!RFC9421]) for AAuth. Signing requirements (the agent's) and verification requirements (the server's) are specified separately.

### Signature Algorithms {#signature-algorithms}

Every party MUST support `Ed25519` ([@!RFC8032]) and SHOULD support `ES256`. Algorithm identifiers are values from the IANA "JSON Web Signature and Encryption Algorithms" registry [@!IANA.JOSE.Algorithms], carried in the `alg` member of the JWK ([@!RFC7517]).

Every key AAuth conveys or references is subject to the Algorithm Determination rules of the HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]). In particular:

- The `alg` member MUST be present and MUST be a fully-specified identifier, one that determines the signature operation completely, including curve and hash. A verifier MUST reject a key whose `alg` is absent.
- The polymorphic `EdDSA` identifier MUST NOT be used. Use `Ed25519` (or `Ed448`), which [@!RFC9864] registered as its fully-specified replacements.
- `none`, any algorithm whose JOSE Implementation Requirement is `Prohibited`, and symmetric algorithms (the `oct` key type and the `HS256`, `HS384`, and `HS512` identifiers) MUST NOT be used.
- A verifier MUST reject a key whose `kty` or, where present, `crv` disagrees with its `alg`.

`ES256` is RECOMMENDED where a platform's keys are ECDSA on P-256, such as hardware-backed keys whose secure enclave does not offer Ed25519. The ML-DSA identifiers registered by [@!RFC9964] are fully specified and are used directly as the `alg` value.

### Keying Material {#keying-material}

The signing key is conveyed in the `Signature-Key` header ([@!I-D.hardt-httpbis-signature-key]). Agents MUST use the `jwt` scheme, presenting a token that carries their public key in `cnf`; agents MUST NOT use the `jwks_uri` or `hwk` scheme for AAuth resource, PS, or AS requests. Which token the agent presents depends on what the recipient needs to know. All three carry the same key in `cnf`, so signature verification is identical.

| Token | Presented to | Asserts |
|---|---|---|
| Agent token (#agent-tokens) | the PS and the AP always; a resource for agent identity and resource-managed access | which agent |
| Person token (#person-tokens) | a resource, at its authorization endpoint or where it requires the person's identity | which person |
| Auth token (#auth-tokens) | a resource, once it has authorized the agent | what is authorized |

A PS, AS, AP, or resource making a signed AAuth request in its own right, such as a PS-to-AS token request (#ps-to-as-token-request) or a revocation (#token-revocation), MUST use the `jwks_uri` scheme. The `id` parameter MUST be the server's `issuer` as published in its metadata (#metadata-documents), and `dwk` MUST be that metadata document's well-known name: `aauth-person.json`, `aauth-access.json`, `aauth-agent.json`, or `aauth-resource.json`.

```http
Signature-Key: sig=jwks_uri;id="https://ps.example";
    dwk="aauth-person.json";kid="key-1"
```

The recipient resolves `id` to the caller's identity, which is the `iss` of every token that server mints. A resource that acts as an agent to reach a downstream resource (#multi-hop) signs as an agent: it presents its own agent token under the `jwt` scheme.

AAuth does not use the `hwk` scheme; the agent token is the minimum AAuth credential. The `jkt-jwt` scheme is used only in the agent provider's key-refresh ceremony ([@?I-D.hardt-aauth-bootstrap]).

### Signing (Agent)

The agent creates an HTTP Message Signature ([@!RFC9421]) on each request, including the `Signature-Key`, `Signature-Input`, and `Signature` headers.

#### Covered Components {#covered-components}

The signature MUST cover the following derived components and header fields:

- `@method`: The HTTP request method ([@!RFC9421], Section 2.2.1)
- `@authority`: The target host ([@!RFC9421], Section 2.2.3)
- `@path`: The request path ([@!RFC9421], Section 2.2.6)
- `signature-key`: The Signature-Key header value

On a request carrying a body to a PS or AS endpoint, or to any revocation endpoint (#token-revocation), the signature MUST additionally cover:

- `content-digest`: The Content-Digest header value ([@!RFC9530])
- `content-type`: The Content-Type header value

A resource declares any further components it requires through `additional_signature_components` (#resource-metadata). Servers MAY require further covered components; the agent learns of them from server metadata or from an `invalid_input` error response that includes `required_input`. See (#why-covered-components).

The following example shows a fully bound request carrying a session token. Token and key values are placeholders.

```http
GET /api/documents HTTP/1.1
Host: resource.example
Authorization: AAuth session-token-placeholder
Signature-Input: sig=("@method" "@authority" "@path"
    "authorization" "signature-key");created=1730217600
Signature: sig=:BASE64URL-SIGNATURE-PLACEHOLDER:
Signature-Key: sig=jwt;jwt="eyJhbGciOiJFZDI1NTE5IiwidHlwIjoiYWEtYWdlbnQrand0Iiwia2lkIjoiYXAta2V5LTEifQ.PLACEHOLDER.PLACEHOLDER"
```

#### Signature Parameters

The `Signature-Input` header ([@!RFC9421], Section 4.1) MUST include:

- `created`: Signature creation timestamp as an Integer (Unix time). The agent MUST set this to the current time.

Agents MUST NOT include the `alg` signature parameter, and verifiers MUST ignore it if present, per [@!RFC9421], Section 3.3.7; the algorithm is determined from the key (#signature-algorithms).

Agents SHOULD NOT include the `keyid` parameter ([@!RFC9421], Section 5.1). If `keyid` is present for a label that also appears in `Signature-Key`, the two MUST identify the same key, and the verifier MUST take the key from `Signature-Key`.

### Verification (Server) {#verification}

When a server receives a signed request, it MUST perform the following steps. Any failure MUST result in a `401` response with the appropriate `Signature-Error` header ([@!I-D.hardt-httpbis-signature-key]).

1. Extract the `Signature`, `Signature-Input`, and `Signature-Key` headers. If any are missing, return `invalid_signature`.
2. Verify that the `Signature-Input` covers the required components (#covered-components) and any additional components the server requires. If not, return `invalid_input` with `required_input`.
3. Verify the `created` parameter is present and within the server's signature validity window of the server's current time. The default window is 60 seconds; servers MAY advertise a different window via metadata (`signature_window` in resource metadata). Return `invalid_signature` if `created` is older than the window, and `clock_skew` if it is further ahead of the server's clock than the window. Servers and agents SHOULD synchronize their clocks using NTP ([@RFC5905]).
4. Select the `Signature-Key` dictionary member for the label being verified and read its scheme. If the scheme is not one the server implements, including any scheme this profile does not use (#keying-material) and any unregistered value, return `unsupported_scheme` with an `Accept-Signature-Scheme` header naming the schemes the server accepts. A server MUST NOT fail in a scheme-specific or undefined manner on an unrecognized scheme.
5. Obtain the public key from the `Signature-Key` header according to the scheme ([@!I-D.hardt-httpbis-signature-key]). Return `invalid_key` if the key cannot be parsed, `unknown_key` if the key is not found at the `jwks_uri`, `invalid_jwt` if a JWT scheme fails verification, `expired_jwt` if the JWT has expired, `clock_skew` if the server applies the OPTIONAL bound on `iat` (#common-verification) and the JWT's `iat` is further ahead of the server's clock than the validity window, `revoked_jwt` if the JWT verifies and is unexpired but the server holds a revocation for it (#token-revocation), or `issuer_missing` / `issuer_mismatch` if the issuer's metadata document fails the checks in (#metadata-documents).
6. Determine the signature algorithm from the `alg` member of the obtained key (#signature-algorithms). Return `unsupported_algorithm` if `alg` is absent, is a polymorphic identifier, or names an algorithm or key type the server does not implement, and include an `Accept-Signature-Alg` header naming the algorithms the server accepts. Return `invalid_key` if the key's `kty` or `crv` disagrees with its `alg`.
7. Verify the HTTP Message Signature ([@!RFC9421]) using the obtained public key and determined algorithm. Return `invalid_signature` if verification fails.

An `Accept-Signature-Alg` header names exactly the algorithms the server accepts. A server MAY omit either `Accept-Signature-*` header where enumerating what it accepts to an unauthenticated caller is judged a disclosure risk.

This profile uses `401` for every signature failure, where the HTTP Signature Keys specification uses `400` for most of them (#why-401-signature-failures). A `403` response denies access after the signature verified. Per ([@!I-D.hardt-httpbis-signature-key]), such a response MUST NOT include a `Signature-Error`, `Accept-Signature-Scheme`, or `Accept-Signature-Alg` header. This applies to the AAuth errors returned with `403` (#token-endpoint-error-codes) and (#polling-error-codes).

#### Signature-Key Scheme Rejection {#scheme-rejection}

AAuth requires the `jwt` scheme of agents (#keying-material), so a request presenting any other scheme is rejected under step 4:

```http
HTTP/1.1 401 Unauthorized
Signature-Error: error=unsupported_scheme
Accept-Signature-Scheme: jwt
```

A resource that also serves clients outside AAuth MAY accept further schemes and MUST then list all of them. `Accept-Signature-Scheme` states what the server accepts from any caller; `AAuth-Requirement: requirement=agent-token` (#requirement-agent-token) states that an AAuth agent token in particular is required.

#### Freshness and Replay {#freshness-and-replay}

The `created` parameter is the primary replay defense: a captured signature becomes unusable once the validity window closes. `expires` is OPTIONAL; servers MUST honor it when present and MUST reject requests where `expires` is in the past.

Within the validity window, a verifier MAY maintain a short-lived cache keyed by `(signing-key-thumbprint, created, @method, @authority, @path)` for the duration of the window, rejecting duplicate tuples. PSes and ASes are NOT required to maintain replay caches for resource tokens (#resource-tokens), which are consumed in a single token request. This profile defines no nonce mechanism.

A verifier that first sees a signed artifact after a delay, such as a batch pipeline or store-and-forward, uses the signed `created` as the signing-time anchor: it verifies that the presented token was valid at `created`, and applies its own policy for how much `created`-to-verification skew it accepts. A replay cache at such a verifier MUST span the skew it accepts.

## JWKS Discovery and Caching {#jwks-discovery}

All AAuth token verification requires discovering the issuer's signing keys via the `{iss}/.well-known/{dwk}` pattern defined in the HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]).

Every key an AAuth server publishes at its `jwks_uri` MUST carry a fully-specified `alg` member (#signature-algorithms), even though [@!RFC7517] makes the member OPTIONAL; the `Signature-Key` header identifies a key without describing it, so the JWKS is the only channel for the algorithm. Deployments reusing an existing JWKS need only ensure that the keys AAuth selects by `kid` carry `alg`.

A verifier MUST select the key matching `kid` without requiring any other member of the JWKS to be usable, and MUST NOT fail because an unselected member names a key type or algorithm it does not implement.

Implementations MUST cache JWKS responses and SHOULD respect HTTP cache headers (`Cache-Control`, `Expires`). On an unknown `kid` in a JWT header, an implementation SHOULD refresh the cached JWKS for that issuer. Implementations MUST NOT fetch a given issuer's JWKS more frequently than once per minute. If a JWKS fetch fails, implementations SHOULD use the cached JWKS if available and SHOULD retry with exponential backoff. Cached JWKS entries SHOULD be discarded after a maximum of 24 hours regardless of cache headers.

If a cached key matching the JWT `kid` fails signature verification, the verifier SHOULD refresh the issuer's JWKS once and retry before returning `unknown_key` (if the key is then absent) or `invalid_jwt` (if verification still fails), subject to the once-per-minute floor.

Before fetching any issuer metadata or `jwks_uri`, verifiers MUST apply egress admission per ([@!I-D.hardt-httpbis-signature-key]).

## AAuth Tokens {#aauth-tokens}

Agent tokens (#agent-tokens), person tokens (#person-tokens), resource tokens (#resource-tokens), and auth tokens (#auth-tokens) are JWTs ([@!RFC7519]) that share the header and claims below. Each token's own section states the values these take for it and the claims specific to it.

### Common JWT Claims {#common-claims}

Header:

- `alg`: Signing algorithm, per (#signature-algorithms). A fully-specified identifier is REQUIRED; `Ed25519` is RECOMMENDED. Implementations MUST NOT accept `none`, the polymorphic `EdDSA` identifier, or any symmetric algorithm.
- `typ`: The token type, `aa-<type>+jwt`. A recipient MUST check `typ` before acting on any AAuth JWT (#person-token-not-authorization).
- `kid`: Key identifier of the issuer's signing key in its JWKS.

Payload:

- `iss`: The issuer's server identifier (#server-identifiers).
- `dwk`: The issuer's well-known metadata document name, for key discovery ([@!I-D.hardt-httpbis-signature-key]).
- `jti`: Unique token identifier for replay detection, audit, and revocation (#token-revocation).
- `iat`: Issued-at timestamp. REQUIRED. Not a validity check (#common-verification).
- `exp`: Expiration timestamp. Lifetime limits are stated per token type.
- `cnf`: Confirmation claim ([@!RFC7800]) with `jwk` containing the public key the token is bound to. The JWK MUST carry a fully-specified `alg` member (#signature-algorithms). A resource token carries `agent_jkt` in place of `cnf` (#resource-token-structure).

### Common JWT Verification {#common-verification}

Verify per [@!RFC7515] and [@!RFC7519]:

1. Decode the JWT header. Verify `typ` is the expected type.
2. Verify `dwk` is the expected metadata document name. Discover the issuer's JWKS via `{iss}/.well-known/{dwk}` per the HTTP Signature Keys specification ([@!I-D.hardt-httpbis-signature-key]) and (#jwks-discovery). Locate the key matching the JWT header `kid` and verify the JWT signature.
3. Verify `exp` is in the future, judged by the verifier's own clock. This document defines no tolerance for clock skew on `exp`.
4. Verify `iss` is a valid server identifier (#server-identifiers).

`iat` is not a validity check. A verifier MAY refuse a token whose `iat` is ahead of its clock by its own policy; the bound SHOULD be its signature validity window (#verification), 60 seconds by default. A verifier that refuses answers `clock_skew`: in the body for a token carried as a request parameter (#token-endpoint-error-codes), and as `Signature-Error: error=clock_skew` ([@!I-D.hardt-httpbis-signature-key]) for the token in the `Signature-Key` header. A verifier MAY use `iat` to bound the age of a token by its own policy; this document defines no such bound. `exp` minus `iat` MUST NOT exceed the one-hour ceiling of a person token (#person-token-structure) or an auth token (#auth-token-structure), and SHOULD NOT exceed the recommended lifetime of an agent token (#agent-tokens) or a resource token (#resource-token-structure).

The token's own section adds the checks specific to it. A token presented in the `Signature-Key` header that fails any of these steps is a signature failure and is answered per (#verification); a token carried as a request parameter that fails is answered with the parameter's own error code (#token-endpoint-error-codes).

## Requirement Responses {#requirement-responses}

Servers use the `AAuth-Requirement` response header to tell an agent what the request needs before it can be served. The header MAY be sent with `401 Unauthorized`, `202 Accepted`, or `402 Payment Required`. A `401` says authorization is required. A `202` says the request is pending and further action is required. A `402` says authorization and payment are both required; the payment requirement is conveyed separately, by x402 [@x402] or the Payment scheme ([@?I-D.ryan-httpauth-payment]).

`AAuth-Requirement` and `WWW-Authenticate` are independent header fields; a response MAY include both, and neither invalidates the other. AAuth never conveys its own requirements via `WWW-Authenticate`.

### AAuth-Requirement Header Structure

The `AAuth-Requirement` header field is a Dictionary ([@!RFC9651], Section 3.2). It MUST contain the following member:

- `requirement`: A Token ([@!RFC9651], Section 3.3.4) indicating the requirement type.

Requirement-specific data are conveyed as parameters on the `requirement` member (for example, `resource-token`, `url`, `code`). Recipients MUST ignore unknown parameters.

```http
AAuth-Requirement: requirement=auth-token; resource-token="eyJ..."
```

### Requirement Values {#requirement-values}

The `requirement` value is an extension point. This document defines the following values:

| Value | Status Code | Meaning | Resource | PS | AS |
|-------|-------------|---------|:--------:|:--:|:--:|
| `agent-token` | `401` | AAuth agent token required (#requirement-agent-token) | Y | | |
| `person-token` | `401` | Person token required (#requirement-person-token) | Y | | |
| `auth-token` | `401` | Auth token required (#requirement-auth-token) | Y | | |
| `interaction` | `202` | User action required at an interaction URL (#interaction-required) | Y | Y | Y |
| `approval` | `202` | Approval pending, poll for result (#approval-pending) | Y | Y | Y |
| `clarification` | `202` | Question posed to the recipient (#requirement-clarification) | Y | Y | Y |
| `claims` | `202` | Identity claims required (#requirement-claims) | | | Y |

An agent that does not recognize the `requirement` value MUST NOT treat the response as satisfiable, and surfaces the unsupported requirement to the caller as an error. For a `202` response with an unrecognized `requirement`, the agent MAY continue polling the `Location` URL in case a later response carries a requirement it does understand.

### Interaction Required {#interaction-required}

When a server requires user action, such as authentication, consent, or payment approval, it returns a `202 Accepted` response:

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

The `code` is a Structured Field String ([@!RFC9651], Section 3.3.3). The user reads it out of band and compares it against the code shown on the interaction page, so it MUST be both unguessable and unambiguous to a human.

**Alphabet.** The code MUST be generated from Crockford base32 ([@?I-D.crockford-davis-base32-for-humans]), the symbol set `0123456789ABCDEFGHJKMNPQRSTVWXYZ`. Every symbol is URL-safe, so the code requires no escaping when appended as `{url}?code={code}`. Servers MUST NOT emit codes containing characters outside this set, other than the optional grouping hyphen.

**Entropy and length.** A code MUST carry at least 40 bits of entropy, at least 8 Crockford base32 symbols, drawn from a cryptographically secure random source. Servers MAY use longer codes for higher-value interactions.

**Hyphens.** A server MAY insert hyphen (`-`) characters into the displayed code for visual grouping (for example, `A1B2-C3D4`). The hyphen carries no entropy and is not part of the code's value. Before comparison, both the server and any party validating the code MUST strip all hyphens.

**Case.** Comparison MUST be case-insensitive. A server MUST accept the code regardless of the case the user enters, and on input MUST fold the Crockford decode aliases (`I`/`L` → `1`, `O` → `0`) before comparison.

**Correlation only.** The code is a correlation identifier that ties the user's browser session to the pending interaction. It is NOT an authorization credential. The person's approve/deny decision MUST be recorded via an authenticated channel at the PS; how the PS authenticates the person is out of scope. Because the agent relays the code to the user, the code is visible to the agent, and the code alone MUST NOT authorize the decision.

**Single use.** A code MUST be single-use. Once the user arrives at the interaction URL with a valid code and the code is consumed, the server MUST reject any later presentation of the same code with `invalid_code` (#polling-error-codes). A code consumed by out-of-band completion (#user-interaction) is rejected the same way.

**Rate-limiting.** The server MUST rate-limit code-validation attempts at the interaction URL. After a small number of failed attempts the server MUST treat the pending interaction as terminally failed and return `invalid_code` (#polling-error-codes) on subsequent attempts.

**Lifetime.** A code MUST expire no later than the pending interaction it is bound to (#deferred-responses). Once the pending request has expired, presenting the code MUST fail with `expired` (#polling-error-codes); the agent MAY initiate a fresh request to obtain a new code.

#### Relaying Through the Person Server {#interaction-relay}

When the agent has a PS, it SHOULD relay the interaction to the PS's `interaction_endpoint` (#interaction-endpoint) before directing the user itself. To relay, the agent POSTs `{ "type": "interaction", "url": "...", "code": "..." }` to the interaction endpoint. The PS responds:

- **PS can relay**: it returns a `202` deferred response, and the agent polls for completion as described in (#interaction-endpoint).
- **PS cannot relay**: it returns `interaction_unavailable` (#interaction-endpoint-errors). This is non-terminal; the agent falls back to directing the user itself.

The agent directs the user itself when it has no PS, or when the PS returns `interaction_unavailable`. It constructs a user-facing URL by appending the code as a query parameter, `{url}?code={code}`, and directs the user to it by one of:

- **Browser redirect**: The agent opens the URL in the user's browser.
- **Display code**: The agent displays the `url` and `code` for the user to enter manually. The agent MAY also render the constructed URL as a QR code.

After directing the user, the agent polls the `Location` URL with GET requests, respecting the `Retry-After` interval. A `202` response means the request is still pending. A non-`202` response is terminal: `200` indicates success, `403` denial, and `408` timeout.

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

### Approval Pending {#approval-pending}

When a server is obtaining approval from another party without requiring the agent to direct a user, for example via push notification, email, or administrator review:

```http
HTTP/1.1 202 Accepted
AAuth-Requirement: requirement=approval
Location: /pending/f7a3b9c
Retry-After: 30
```

The response MUST include `Location` and `Retry-After`. The agent polls the `Location` URL with GET requests until a terminal response is received. No user action is required at the agent side. The same terminal response codes apply as for `interaction`.

## AAuth-Capabilities Request Header {#aauth-capabilities}

Agents use the `AAuth-Capabilities` request header to declare which protocol capabilities they can handle, so a resource knows which requirements it can raise. The header field is a List ([@!RFC9651], Section 3.1) of Tokens.

```http
AAuth-Capabilities: interaction, clarification, payment
```

This specification defines the following capability values:

| Value | Meaning |
|-------|---------|
| `interaction` | Agent can get a user to a URL, either directly or via its PS's interaction endpoint |
| `clarification` | Agent can engage in clarification chat (#clarification-chat) |
| `payment` | Agent can handle `402` payment flows, either directly or via its PS's interaction endpoint |

The agent's capabilities are the union of what it can do directly and what its PS can do on its behalf. When a mission approval response includes a `capabilities` array (#mission-approval), the agent unions those with its own.

Agents SHOULD include the `AAuth-Capabilities` header on signed requests to resources. The header is not used on requests to PS endpoints, which take a `capabilities` request parameter instead (#person-token-endpoint) and (#ps-token-endpoint). Recipients MUST ignore unrecognized capability values. When the header is absent, recipients MUST NOT assume any capabilities.

Capability values are Tokens and currently carry no parameters. A future capability value MAY define parameters; recipients MUST ignore parameters they do not recognize rather than rejecting the header. Recipients ignore what they do not recognize throughout AAuth, and no document carries a version or schema identifier. An extension that defines a member a recipient must understand states that requirement, and the behaviour on failure, itself.

## Deferred Responses {#deferred-responses}

Any AAuth endpoint MAY return a `202 Accepted` response ([@!RFC9110]) when it cannot immediately resolve a request. Agents MUST handle `202` responses regardless of the nature of the original request.

### Initial Request

The agent makes a request and signals its willingness to wait using the `Prefer` header ([@!RFC7240]):

```http
POST /token HTTP/1.1
Host: auth.example
Content-Type: application/json
Prefer: wait=45
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

- `Location` (REQUIRED): The pending URL. MUST be on the same origin as the responding server.
- `Retry-After` (REQUIRED): Seconds the agent SHOULD wait before polling. `0` means retry immediately.
- `Cache-Control: no-store` (REQUIRED).
- `AAuth-Requirement` (OPTIONAL): Present when user interaction or approval is required (#requirement-responses).

Body fields:

- `status` (REQUIRED): `"pending"` while the request is waiting. `"interacting"` when the user has arrived at the interaction endpoint. Agents MUST treat unrecognized `status` values as `"pending"` and continue polling.

Additional body fields may be present depending on the `AAuth-Requirement` value, for example `clarification` and `timeout` with `requirement=clarification`, or `required_claims` with `requirement=claims`.

### Polling with GET

After receiving a `202`, the agent switches to `GET` for all subsequent requests to the `Location` URL and does not resend the original request body. **Exception**: during clarification chat, the agent uses `POST` to deliver a clarification response (#agent-response-to-clarification).

The agent MUST respect `Retry-After` values. If a `Retry-After` header is not present, the default polling interval is 5 seconds. If the server responds with `429 Too Many Requests`, the agent MUST increase its polling interval by 5 seconds (linear backoff, following [@RFC8628], Section 3.5). The `Prefer: wait=N` header ([@!RFC7240]) MAY be included on polling requests.

### Deferred Response State Machine

The following state machine applies to any AAuth endpoint that returns `202 Accepted`. A non-`202` response terminates polling.

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
    +-- 502 --> as_unreachable — fresh resource token, retry after backoff
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
               +-- 502 --> as_unreachable — fresh resource token, retry after backoff
               +-- 503 --> temporarily unavailable
                           back off per Retry-After
```

## Error Responses {#error-responses}

### Authentication Errors

A `401` response from any AAuth endpoint uses the `Signature-Error` header as defined in ([@!I-D.hardt-httpbis-signature-key]). The header, not the response body, is the machine-readable carrier; agents MUST NOT depend on the body for signature error handling. A server returning `unsupported_scheme` SHOULD include `Accept-Signature-Scheme`, and one returning `unsupported_algorithm` SHOULD include `Accept-Signature-Alg` (#verification).

### Error Response Format {#error-response-format}

Error response bodies use the HTTP problem details format ([@!RFC9457]) with `Content-Type: application/problem+json`. The body is a JSON object with the following members:

- `error` (REQUIRED): String. A single error code, as defined by the endpoint returning the error. This is an RFC 9457 extension member; receivers MUST determine how to proceed from this member.
- `detail` (OPTIONAL): String. A human-readable explanation specific to this occurrence of the error.

Other RFC 9457 members (`type`, `title`, `status`, `instance`) MAY be present with their RFC 9457 semantics. AAuth does not define problem type URIs; receivers MUST NOT rely on `type` to identify AAuth errors.

### Token Endpoint Error Codes {#token-endpoint-error-codes}

| Error | Status | Meaning |
|-------|--------|---------|
| `invalid_request` | 400 | Malformed JSON, missing required fields |
| `invalid_resource_token` | 400 | Resource token malformed or signature verification failed |
| `expired_resource_token` | 400 | Resource token has expired |
| `revoked_resource_token` | 400 | The resource that issued the resource token has withdrawn it (#token-revocation). Terminal for that token: the agent MUST NOT resubmit it, and MAY call the resource again. |
| `invalid_presented_token` | 400 | Presented token malformed, signature verification failed, or its `typ` is neither a person token nor an auth token (#resource-token-verification) |
| `expired_presented_token` | 400 | The presented token has expired. The agent obtains a fresh person token, then a fresh resource token. |
| `revoked_presented_token` | 400 | The presented token has been revoked by the server that issued it (#token-revocation). The agent obtains a fresh person token, then a fresh resource token. |
| `invalid_upstream_token` | 400 | Upstream token malformed, signature verification failed, or its `aud` is not the requesting intermediary (#upstream-token-verification) |
| `expired_upstream_token` | 400 | The upstream token has expired. The calling agent must re-authorize at the intermediary. |
| `revoked_upstream_token` | 400 | The upstream token has been revoked, or the PS has revoked the calling agent's agent token or its binding to the person (#upstream-token-verification). Terminal for that token. |
| `invalid_subagent_token` | 400 | Sub-agent token malformed, signature verification failed, its `parent_agent` does not name the signing agent, or its `iss` is not the signing agent's (#sub-agents) |
| `expired_subagent_token` | 400 | The sub-agent token has expired. The parent obtains a fresh one. |
| `revoked_subagent_token` | 400 | The sub-agent token has been revoked by its agent provider (#token-revocation). Terminal for that token. |
| `clock_skew` | 400 | A token carried as a request parameter has an `iat` further ahead of the verifier's clock than the signature validity window (#common-verification). A fresh token from the same issuer carries the same skew, so the agent does not refresh; it MAY present the same token again once its `iat` is within the window, using the response's `Date` header to judge, or surfaces the error. |
| `user_unreachable` | 403 | Terminal. The PS has no channel to reach the user and the agent did not declare the `interaction` capability. |
| `as_unreachable` | 502 | PS token endpoint only. The PS could not obtain an auth token from the access server named by the resource token's `aud`: connection failure, timeout, a malformed response, or an auth token that fails delivery verification (#auth-token-delivery). The agent MAY retry with a fresh resource token after a backoff. Distinct from an AS denial, which the PS relays. |
| `server_error` | 500 | Internal error |

Token-specific codes exist only for tokens carried as request parameters, and follow the pattern `<invalid|expired|revoked>_<parameter>_token`. The token in the `Signature-Key` header has no codes in this table: when it fails, the response is `401` with `Signature-Error` (#verification).

Example:

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
| `revoked` | 403 | A token the pending request depends on was revoked (#token-revocation): the resource token it was started for, the upstream token of a chained request (#call-chaining), or the agent token of the agent that started it. `detail` SHOULD say which |
| `invalid_code` | 410 | Interaction code not recognized or already consumed |
| `slow_down` | 429 | Polling too frequently; increase interval by 5 seconds |
| `server_error` | 500 | Internal error |

Example:

```http
HTTP/1.1 403 Forbidden
Content-Type: application/problem+json

{
  "error": "denied",
  "detail": "The user declined the request."
}
```

## Scopes {#scopes}

Scopes define what an agent is authorized to do at a resource. AAuth uses two categories of scope values:

- **Resource scopes**: Resource-specific authorization grants (e.g., `data.read`, `data.write`, `data.delete`). Each resource defines its own scope values and publishes human-readable descriptions in its metadata (`scope_descriptions`). Resources that already define OAuth scopes SHOULD use the same scope values in AAuth.
- **Identity scopes**: Requests for user identity claims following [@!OpenID.Core] (e.g., `openid`, `profile`, `email`, `address`, `phone`). When identity scopes are present, the auth token includes the corresponding identity claims. Enterprise extensions include the `tenant` claim from [@OpenID.Enterprise] and the `groups` and `roles` claims from [@!RFC9068] (originally defined by SCIM [@RFC7643]).

A resource token MUST only include resource scopes that the resource has defined in its `scope_descriptions` metadata, and identity scopes that the PS has declared in its `scopes_supported` metadata.

Scopes appear in three places:

1. **Authorization endpoint request** (`scope`): The scope the agent is requesting from the resource.
2. **Resource token** (`scope`): The scope the resource is willing to grant.
3. **Auth token** (`scope`): The scope actually granted. MUST NOT be broader than the resource token's scope.

The PS evaluates requested scopes against mission context (if present) and user consent. The AS evaluates scopes against resource policy. Either party may narrow the granted scope.

## Account Binding {#account-binding}

A resource may hold more than one account for the same person: an AAuth-to-OAuth proxy where a user has connected several accounts, a SaaS product where someone belongs to several workspaces. Scope says what the agent may do; `account` says which account it may do it to.

The OPTIONAL `account` parameter of the authorization endpoint request (#authorization-endpoint-request) binds an authorization to one account. Its value is a string from the resource's own account namespace, such as an email address, a workspace identifier, or a tenant id. This specification gives it no structure and no meaning; only the resource interprets it.

When the request carried `account`, the resource echoes it as the `account` claim of the resource token, the PS or AS copies it into the auth token, and the resource enforces per-account access from the token it receives. Different accounts yield different auth tokens. `account` is not `login_hint` (#why-account-not-login-hint).

## Token Revocation {#token-revocation}

A PS and an AS SHOULD provide a revocation endpoint, and so SHOULD a resource that accepts person tokens. A resource that accepts only agent tokens receives no revocations. Revocation endpoints are advertised in server metadata as `revocation_endpoint`. A server without one honors a revoked token until its `exp`.

### Revocation Request

The endpoint accepts a signed POST. The caller signs as a server (#keying-material), and recipients MUST verify the caller's identity via HTTP Message Signatures. The signature MUST cover `content-digest` and `content-type` along with the base components (#covered-components), at a resource's revocation endpoint as much as a PS's or an AS's.

```http
POST /revoke HTTP/1.1
Host: resource.example
Content-Type: application/json
Signature-Key: sig=jwks_uri;id="https://ps.example";
    dwk="aauth-person.json";kid="key-1"

{
  "jti": "unique-token-identifier",
  "exp": 1788727813
}
```

- `jti` (REQUIRED): The token to revoke, within the caller's namespace.
- `exp` (REQUIRED): The revoked token's own expiration, which bounds how long the recipient has to remember the revocation.

The issuer is not a request parameter. The recipient takes it from the identity it verified on the signature: a caller revokes only its own tokens. Recipients maintaining revocation state MUST key it by `(iss, jti)`, where `iss` is the verified identity of the caller. A recipient MAY discard an entry once the current time is past `exp` plus its clock skew tolerance, and MAY reject a revocation whose `exp` is further in the future than the longest lifetime it accepts for any token.

### Who Revokes What

| Token | Revoked by | At |
|---|---|---|
| Agent token | the agent provider that issued it | the PS only. A resource that accepts an agent token directly has no revocation path; that access is bounded by the agent token's lifetime, which is why it SHOULD NOT exceed 24 hours (#agent-tokens). |
| Person token | the PS that issued it | the resource named in its `aud`, and each AS the PS presented it to (#ps-to-as-token-request) |
| Auth token | the PS (three-party) or AS (four-party) that issued it | the resource it was issued for. A PS that federated to an AS revokes the person token at the AS instead, and the AS revokes what it issued. |
| Resource token | the resource that issued it | the party named in its `aud`, and in four-party the `ps` as well |

### Revocation Response

The recipient records the revocation before it calls anyone, then makes every downstream revocation it is going to make (#revocation-cascade), and answers `200 OK` once each has a terminal outcome. A `200` says the cascade is finished, not that it was started. Whether the recipient holds a record of the token does not enter into it: a recipient that verifies tokens statelessly still answers `200 OK`, having recorded the pair. There is no "not found" response (#why-revocation-no-not-found). A recipient with nothing downstream, such as a resource, or a PS or AS receiving a resource token revocation, answers at once.

A downstream revocation is terminal when it was recorded there, or when it ended in one of two ways:

- `revocation_unsupported`: the downstream party publishes no `revocation_endpoint`, or answered `unsupported_iss`. That party honors the tokens until their `exp`.
- `revocation_unavailable`: the downstream party did not respond, timed out, or returned a `5xx` or a malformed response. The caller MAY revoke again later.

**Body.** An AS reports to the PS: its `200` carries a `downstream` array with one entry per resource it revoked at, each with `recipient` (the resource identifier) and `error` (one of the two values above when the revocation there did not succeed, absent when it did). A PS does not report to the agent provider: its `200` to an AP carries an empty body (#why-ps-reports-nothing-to-ap). A recipient with nothing downstream answers with an empty body. A PS MAY report the outcome of a revocation the person initiated to that person, per recipient.

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "downstream": [
    {
      "recipient": "https://resource.example",
      "error": "revocation_unavailable"
    }
  ]
}
```

A `200` MAY carry no body, and then carries no `Content-Type`. A non-empty body MUST be `application/json` and MUST be a JSON object, whose `downstream` member is OPTIONAL. A caller reads an absent body as the revocation recorded with nothing reported, and a non-empty body it cannot parse as `revocation_unavailable`.

**Deferred completion.** If the cascade takes longer than the recipient will hold the connection, or a downstream recipient itself answered `202`, the recipient returns a `202 Accepted` deferred response (#deferred-responses) and the caller polls the pending URL for the terminal response. The caller MAY say how long it will wait with `Prefer: wait` ([@!RFC7240]). Absent `Prefer: wait`, the recipient SHOULD hold at least long enough for one round trip to each downstream party it will call, on the order of 20 seconds for a PS or an AS. A recipient MAY hold for less than the caller asked for and answer `202` at its own cap.

The poller is a server: it polls the pending URL with a signed `GET`, signing under the same identity that made the revocation, and sends no body. The recipient MUST verify that identity and MUST answer `404` to a poll from any other. `Retry-After` and `Prefer: wait` apply as on any other pending URL. The terminal response is what the synchronous path would have returned, or an error from the table below. No `AAuth-Requirement` is used. A recipient with nothing downstream MUST NOT answer `202`.

**Idempotence.** A recipient answering a repeated revocation for the same `(iss, jti)` records nothing new, re-attempts each downstream revocation that did not succeed, and reports the current outcome. A PS that received `revocation_unavailable` MAY therefore revoke the person token at the AS again later.

**Errors** use the format in (#error-response-format):

| Error | Status | Meaning |
|-------|--------|---------|
| `invalid_request` | 400 | Malformed JSON, or a missing or malformed `jti` or `exp` |
| `unsupported_iss` | 403 | The recipient does not accept revocations from this caller |
| `rate_limited` | 429 | The caller has sent more revocations than the recipient will accept from it for now. `Retry-After` is REQUIRED. Distinct from polling `slow_down` (#polling-error-codes) |
| `server_error` | 500 | Internal error |

A request whose signature does not verify is answered with `401` and the `Signature-Error` header (#error-responses).

**What a recipient will accept.** A recipient MAY restrict revocations to issuers it holds tokens from, or has a record of exchanging tokens with, and answer `unsupported_iss` to the rest. A recipient that accepts any verified issuer SHOULD bound what one issuer can hold, in entries and in rate, and answer `rate_limited` beyond either.

### Revocation Cascade {#revocation-cascade}

- **PS revokes an auth token it issued** (three-party): The PS calls the resource's revocation endpoint.
- **AS revokes an auth token it issued**: The AS calls the resource's revocation endpoint.
- **PS terminates access it federated** (four-party): The PS revokes the person token it presented with the token request (#ps-to-as-token-request), and the AS cascades to the auth tokens it issued against that person token.
- **PS revokes a person token it issued**: The PS calls the revocation endpoint of the resource named in the token's `aud`, and of every AS it presented that person token to. The resource MUST refuse subsequent requests presenting the person token and MUST NOT issue a resource token naming it. The AS MUST NOT issue further auth tokens against it, and MUST revoke the auth tokens it already issued against it by calling the revocation endpoint of the resource each names in `aud`. The PS MUST NOT present a revoked person token to an AS, and rejects a token request whose `presented_token` is one with `revoked_presented_token` (#token-endpoint-error-codes). Where the revoked person token, or an auth token issued against it, was later presented as an `upstream_token` (#call-chaining), the PS SHOULD revoke the person tokens it issued from it in the same cascade, at their resources and at the ASes it presented them to.
- **Resource revokes a resource token it issued**: The resource calls the revocation endpoint of the party named in the token's `aud`, and in four-party that of the `ps` as well. The recipient MUST NOT issue an auth token against that resource token, rejects a token request naming it with `revoked_resource_token` (#token-endpoint-error-codes), and SHOULD terminate a pending request it started for it, which the agent reads as `revoked` (#polling-error-codes). The recipient records the `(iss, jti)` whether or not it has seen the token, and MAY discard the entry once the current time is past the `exp` the revocation named plus clock skew.
- **PS revokes a mission**: The PS marks the mission as revoked. All subsequent token requests referencing that mission's `s256` are denied. The PS SHOULD revoke outstanding auth tokens issued under the mission.
- **Agent provider revokes an agent token it issued**: The agent provider calls the PS's revocation endpoint. The PS MUST deny subsequent requests presenting that agent token, and SHOULD revoke the person tokens and auth tokens it issued for that agent, and terminate what it federated by the four-party path above. The cascade is by agent identity: the PS revokes every person token and auth token it issued to that agent's `sub`, whichever agent token the agent presented when it asked. The revocation does not alter the agent-person binding (#agent-person-binding). An agent token the same provider issues later is verified on its own terms. The PS answers the agent provider with an empty `200` once its cascade is terminal.
- **Agent provider stops issuing agent tokens**: Existing agent tokens expire naturally.

**Records.** The parties that cascade retain what they issued. A PS records, for each agent token it accepts, that token's `(iss, jti)` and the `sub` it carried, until the agent token's `exp` plus clock skew. A PS records each person token it issues (#person-token-endpoint), and for each auth token it issued or federated against that person token, the `jti`, the resource it was for, and the `exp`. An AS records the same for each auth token it issues, along with the `presented_jti` it was issued against. A person token issued with an `upstream_token` is recorded with the upstream token's `(iss, jti)`, so a revocation of the earlier person token walks the chain from the PS's own records; an AS records nothing of the chain. An entry MAY be discarded once the current time is past the token's `exp` plus clock skew.

### Presenting a Revoked Token

A recipient MUST say that a revoked token was revoked, not that it is malformed or expired. Where it says so depends on how the token was carried:

- **Agent, person, or auth token in the `Signature-Key` header**: `401` with `Signature-Error: error=revoked_jwt` ([@!I-D.hardt-httpbis-signature-key]). A resource refusing a revoked auth token SHOULD also include `AAuth-Requirement: requirement=person-token` (#requirement-person-token). It MUST NOT answer with `requirement=auth-token` and a resource token, since the PS or AS would reject a resource token naming a revoked token with `revoked_presented_token`. For a revoked agent token no requirement repairs it; the agent obtains a fresh one from its provider.
- **A token carried as a request parameter**: the signature verified, so this is not a `401`. The recipient returns `revoked_<parameter>_token` in the response body (#token-endpoint-error-codes). A pending request already started against a withdrawn resource token, or whose upstream token or agent's agent token is revoked while it waits, terminates with `revoked` (#polling-error-codes), with `detail` saying which.

Verifying a token does not ask the issuer about that token, so a resource learns of a revocation only when one reaches its revocation endpoint. A party that no revocation reaches is bounded by token lifetime alone: at most one hour for an auth token or a person token, five minutes for a resource token, and 24 hours for an agent token presented directly to a resource. Deployments requiring immediate termination should issue shorter-lived tokens rather than rely on revocation reaching every holder.

# Incremental Adoption {#incremental-adoption}

AAuth is designed for incremental adoption. Each party — agent, resource, PS, AS — can independently add support. The system works at every partial adoption state. No coordination is required between parties.

## Drop-In Replacement for API Keys and OAuth {#drop-in-migration}

The first two resource steps require neither a person server nor an access server. They map directly onto what resources already do today:

- **Agent identity access drops in where you use API keys.** A resource that verifies the agent's HTTP Message Signature gets a cryptographic, per-agent identity in place of a shared secret — nothing to copy and leak, no pre-registration, no authorization flow. The agent signs, the resource recognizes who it is and applies its existing access control. This is identity-based access (#overview-identity-access); it involves no PS and no AS.
- **Resource-managed access drops in where you use OAuth.** A resource keeps its existing authorization — consent screens, OAuth access tokens, or session tokens — and wraps it: it returns its existing token opaquely via the `AAuth-Access` header (#aauth-access), bound to the agent's signature so it cannot be stolen and replayed as a standalone bearer token. The resource talks directly to the agent. This is resource-managed (two-party) access (#overview-resource-managed); it too involves no PS and no AS.

Both modes are complete and useful on their own. Adding a PS (PS authorization, three-party) and an AS (federated authorization, four-party) is additive — it brings cross-domain identity assertion and policy federation — but neither is a prerequisite for the value a resource gets from the first two steps.

### Consuming a Resource End to End {#consuming-a-resource}

A resource that wants agents to discover and use it with no prior integration SHOULD publish two things in its `aauth-resource.json` (#resource-metadata):

- **`access_mode`** — the credential flow the agent should expect: `agent-token`, `person-token`, `session-token`, or `auth-token`.
- **An R3 vocabulary.** Resources SHOULD advertise an R3 vocabulary (`r3_vocabularies`, [@?I-D.hardt-aauth-r3]) describing their operations, so that an agent that knows only the resource's hostname can learn the API and begin using it. The R3 document itself is fetched only by the AS and PS, not the agent; the vocabulary (an OpenAPI, MCP, gRPC, or similar API description) is the agent-facing surface.

An agent onboards as follows:

1. Fetch `aauth-resource.json` — from the resource identifier's well-known URL, or from an `aauth-resource` link on the page the agent reached first (#resource-metadata-link); read `access_mode` and the advertised vocabulary.
2. Fetch the vocabulary to learn the resource's operations, then construct calls.
3. If `access_mode` is `auth-token` and the agent has no PS, it cannot complete that flow and SHOULD skip the resource.
4. Make the call and satisfy whatever the resource requires, bringing the user in only where the mode calls for it:
   - **`agent-token`** — the agent signs with its agent token and calls. If the resource needs to bind the agent to a user account (the equivalent of associating an API key with an account), it returns a `202` with `requirement=interaction` (#requirement-responses) pointing at a login or account-link page; the agent brings the user there, directly or via the PS's interaction endpoint (#interaction-endpoint). Once bound, subsequent calls with the same agent token are recognized with no further interaction. No token is issued — the account-bound agent token is the durable credential.
   - **`session-token`** — the agent's call, or a request to the `authorization_endpoint`, triggers a `202` with `requirement=interaction` pointing at the resource's existing consent or login flow. After the user completes it, the resource returns an opaque token via the `AAuth-Access` header (#aauth-access); the agent presents that token in `Authorization: AAuth ...`, bound to its signature, on subsequent calls.
   - **`auth-token`** — the resource issues a resource token via the `authorization_endpoint` or a `401` (#requirement-auth-token). The agent sends it to its PS, which runs consent — bringing the user in at the PS, not the resource — and returns an auth token the agent signs with. Whether the PS asserts identity directly (three-party) or federates with the resource's AS (four-party) is invisible to the agent.

Throughout, the agent runs a single loop: make the request, read any `AAuth-Requirement`, satisfy it — bringing in the user where the requirement directs — and retry. The `access_mode` declaration lets the agent anticipate the flow; the runtime `AAuth-Requirement` remains authoritative, so a resource can mix modes across endpoints or escalate at any time.

## Agent Adoption Path

Each step builds on the previous one. An agent that adopts any step gains immediate value.

1. **Obtain an agent token and sign requests** (the `jwt` scheme, `typ: aa-agent+jwt`): The agent has a full AAuth identity with an `aauth:local@domain` identifier issued by an agent provider. It signs requests using HTTP Message Signatures ([@!RFC9421]) per the Signature-Key specification ([@!I-D.hardt-httpbis-signature-key]) and presents its agent token via the `Signature-Key` header under the `jwt` scheme. Resources that recognize signatures can verify the agent's identity and apply access control. Resources that don't ignore the signature and `Signature-Key` headers — existing auth mechanisms continue to work. This enables identity-based access.
2. **Add a person server** (include `ps` claim in agent token): The agent can obtain auth tokens from its PS directly. Resources in three-party and four-party modes can issue resource tokens targeting the PS. Enables PS-issued auth tokens with user identity, `tenant`, `groups`, and `roles` claims.
3. **Add governance** (create a mission): The agent creates a mission at its PS, gaining permissions, audit, PS-relayed interactions, and consent-managed resource access. The mission can be as simple as the user's prompt.

## Resource Adoption Path

Each step builds on the previous one. A resource that adopts any step works with agents at all identity levels.

1. **Recognize AAuth signatures**: Verify HTTP Message Signatures and respond with `Accept-Signature-Scheme` headers ([@!I-D.hardt-httpbis-signature-key]). Resources that don't recognize AAuth ignore the signature headers — existing auth mechanisms continue to work. This is identity-based access.
2. **Manage authorization**: Handle authorization with interaction, consent, or existing infrastructure — via `401` responses, an authorization endpoint, or both. Return `AAuth-Access` headers (#aauth-access) for subsequent calls. This is resource-managed access (two-party).
3. **Accept identity claims from any PS**: Verify person tokens and issue resource tokens with `aud` = the `iss` of the person token verified. The agent's PS returns an auth token asserting identity claims about the user and consent for the requested scope; the resource applies its own policy. This is PS authorization access (three-party).
4. **Deploy an access server**: Issue resource tokens with `aud` = AS URL. The PS federates with the AS. This is federated access (four-party).

## Adoption Matrix

| Agent | Resource | Mode | What Works |
|-------|----------|------|------------|
| Agent token | Recognizes signatures | Agent identity | Identity verification, access control by agent identity |
| Agent token | Manages authorization | Resource-managed | Resource-handled auth, interaction, `AAuth-Access` |
| Person token | Accepts person tokens | Person identity | Resource knows the person and any mission; applies its own access control |
| Auth token | Issues resource tokens | PS authorization | PS asserts identity and consent for a scope; resource applies its own policy |
| Auth token | AS deployed | Federated authorization | Full federation, AS policy enforcement |
| Agent token + `ps` + mission | Any or none | + governance | Tool-call permissions, audit, PS-relayed interaction, consent-managed access |

# Security Considerations

## Proof-of-Possession

All AAuth tokens are proof-of-possession tokens: the holder must prove possession of the private key corresponding to the public key in the token's `cnf` claim. Agent tokens bind that key to an agent identity and auth tokens bind an authorization grant to it; resource tokens bind the request to the resource's own identity, which is what prevents one resource being substituted for another in the authorization flow.

## Pending URL Security

- Pending URLs MUST be unguessable and SHOULD have limited lifetime
- Pending URLs are on the same origin as the server that issued them (#deferred-responses)
- Servers MUST verify the agent's identity on every poll
- Once a terminal response is returned, the pending URL MUST return `410 Gone`, except where a flow requires a repeated presentation of the same token to be answered from a retained result — deferred auth-token delivery (#deferred-auth-token) and per-call grants ([@?I-D.hardt-aauth-r3]) — in which case the URL answers from the record until its retention ends, and returns `410 Gone` after

## Untrusted Input {#untrusted-input}

All protocol inputs — JSON request bodies, clarification responses, justification strings, mission descriptions, and token claims — are untrusted input from potentially adversarial parties. This is consistent with standard web security practice where HTTP request bodies, headers, and query parameters are always treated as untrusted. Implementations MUST sanitize all values before rendering to users and MUST validate all values before processing. Markdown fields MUST be sanitized before rendering to prevent script injection.

## Agent Control of the Consent Surface {#agent-consent-surface-control}

The `justification` is written by the party requesting the access and rendered on the surface where the person decides whether to grant it. Sanitizing it prevents script injection; it does not prevent the agent from describing the access as something other than what the resource says it is, understating what an operation touches, or asserting a purpose the resource's own `description` and `scope_descriptions` contradict. The same holds for `platform`, `device`, and clarification responses, all of which are agent-attested.

The mitigation is attribution rather than filtering. A PS MUST distinguish resource-asserted from agent-asserted content, and MUST NOT decide on agent-asserted content alone where resource-asserted content covering the same operation is available (#consent-presentation). A PS that renders the agent's text and the resource's text with the same weight has given the agent an equal voice in describing its own request.

## Interaction Code Misdirection

An attacker could attempt to trick a user into approving an authorization request by directing them to an interaction URL with the attacker's code. The PS mitigates this by displaying the full request context — the agent's identity, the resource being accessed, and the requested scope — so the user can recognize requests they did not initiate. A stronger mitigation is for the PS to interact directly with the user via a pre-established channel (push notification, email, or existing session) using `requirement=approval`, which eliminates the possibility of misdirection through attacker-supplied links entirely.

The reverse threat — an attacker who knows a pending request's interaction URL but not its `code` and tries to guess it to drive the interaction — is bounded by the code-format rules in (#interaction-code-format). The minimum 40 bits of entropy make a single guess overwhelmingly likely to fail, and the mandatory rate-limit terminates the pending interaction after a few failed attempts, capping total guesses far below the entropy bound. These entropy and rate-limit requirements are the brute-force defense; they complement the user-recognition and pre-established-channel defenses above, which address misdirection of a legitimate code rather than recovery of an unknown one.

## Link Relation Security {#link-relation-security}

An `aauth-resource` link (#resource-metadata-link) is a statement by whoever controls the response that carries it, not by the resource it names. Two limits keep that harmless. The target is constrained to a well-known URL and the fetched document is verified against the URL it came from, so a link cannot cause an agent to accept metadata the resource did not publish; and the relation plays no part in key discovery, so it cannot affect what any verifier trusts.

What a link can do is steer. A page an attacker controls can point an agent at a resource the person did not intend, and the agent will then request a person token naming that resource and present it there. The answer is the one the protocol already gives for any resource an agent meets for the first time: the person token endpoint puts the question to the person, presenting the resource's own `name` and `description` (#person-token-endpoint), and a person token carries no authorization (#person-token-not-authorization). An agent SHOULD record where it found a link, so that a resource introduced by a third-party page is distinguishable from one the person named. An agent that parses HTML to find the relation is reading untrusted input (#untrusted-input).

## Trust Posture in PS Authorization Access {#trust-posture-in-ps-asserted-access}

In three-party mode, the resource has no AS of its own — it accepts identity claims and consent from whichever PS issued the person token it verified. This is a deliberate trust posture: the resource externalizes identity claim issuance while retaining policy enforcement. Resources MUST apply their own policy on the resulting claims rather than treating the PS-issued auth token as a bearer authorization. Resources that need policy decisions made externally (per-resource scope enforcement, organizational gating, billing) should deploy an AS and use four-party mode.

Because identity assertion does not require pre-registration, the resource follows the same protocol flow whether it is meeting the user for the first time or recognizing a returning one. The auth token's `(iss, sub)` pair is a stable identifier per user per PS — the resource looks up the tuple and creates a new user record on a miss, matches an existing one on a hit. As in many OIDC deployments, registration and login are the same flow; the resource's own logic distinguishes the two outcomes. In multi-tenant deployments the auth token MAY also carry a `tenant` claim ([@OpenID.Enterprise]); `(iss, tenant, sub)` identifies a user within an organization, and `(iss, tenant)` identifies the organization itself — useful for grouping users from the same employer or account.

The PS MUST protect its signing keys with appropriate rigor — compromise of a PS's signing key allows forgery of identity claims for every resource that accepts that PS.

## Person Token Exposure {#person-token-exposure}

A person token identifies the person to a resource before any authorization decision, on every request that carries one including those the resource refuses. A resource therefore learns of people whose agents it never serves.

The directed `sub` bounds the exposure to one `(PS, resource)` pair. The PS bounds it further: it decides whether to issue at all, and SHOULD treat the first person token for a given resource as requiring the person's approval (#person-token-endpoint).

A person token grants nothing from the PS. Disclosure to a party without the signing key leaks a directed identifier and nothing more: `cnf` prevents that party from presenting it. The party that holds the key can present it at the one resource in `aud`, and a resource that serves on identity alone (#overview-person-identity) serves it; that exposure is bounded by the token's single audience and its one-hour lifetime, not by `cnf`.

## Continuity, Not Identity Proofing {#continuity-not-proofing}

A person token proves "the same entity again", not a verified legal identity. The protocol does not state what standard, if any, a PS applied before recognizing a person, and a resource MUST NOT infer one (#person-tokens). Continuity is sufficient for most resource access: authorizing an agent, keeping an account stable across agents and sessions, applying per-person policy. A resource requiring more — an age check, a residency check, regulated onboarding — obtains it out of band or through claims a person server explicitly asserts.

## Organization Identification {#person-token-org-policy}

The OPTIONAL `tenant` claim declares the organization the person belongs to, and unlike `sub` it is not directed — the same value appears at every resource the organization's agents reach.

That is deliberate. It lets a resource apply organizational policy before it issues anything: recognise a contracted customer, or rate-limit and refuse an organization whose agents are abusing it. Without it a resource's only lever at first contact is the person server, which is far too coarse — refusing one would refuse every organization that uses it — and pairwise `sub` otherwise makes one organization's agents indistinguishable from many unrelated people.

`tenant` is organizational context and MUST NOT be treated as part of the person's identifier, which is `(iss, sub)` (#directed-identifiers).

## Person Token Is Not Authorization {#person-token-not-authorization}

A PS-issued auth token and a person token carry the same `iss`, `dwk`, `aud`, `sub`, and `cnf`. Only `typ` distinguishes them. A resource that verifies the signature and reads `sub` without checking `typ` accepts a person token wherever it accepts an auth token.

Implementations MUST check `typ` before acting on any AAuth JWT, and MUST reject `aa-person+jwt` where an auth token is required (#person-token-verification). Deployments SHOULD test this case explicitly; it fails open. `upstream_token` is not such a place: it accepts either type, and the recipient reads `typ` to choose the verification (#upstream-token-verification).

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

A request carrying `upstream_token` (#call-chaining) neither uses nor establishes a binding. The intermediary acts for each person whose upstream token it presents, and the PS issues for the person that token identifies (#intermediary-agent-identity). The binding the invariant protects is the calling agent's, which the PS applied when it issued the person token the chain began with.

This invariant enables:

- **Accountability**: Every authorization decision traces to a single person.
- **Consent integrity**: Consent granted by one person cannot be exercised by a different person through the same agent.
- **Audit**: The PS can provide a complete record of an agent's actions on behalf of its person.
- **Revocation**: Revoking an agent's association with its person immediately prevents the agent from obtaining new auth tokens.

## PS as High-Value Target

The PS is a centralized authority that sees every authorization in a mission. PS implementations MUST apply appropriate security controls including access control, audit logging, and monitoring. Compromise of a PS could affect all agents and missions it manages.

Several architectural properties mitigate this centralization risk. The person chooses their PS — no other party in the protocol imposes a PS, and the person can migrate to a different PS at any time. The PS MAY delegate authentication to an identity provider chosen by the person or organization (e.g., an enterprise IdP via OIDC federation), reducing the PS's role in credential management. The PS MAY also delegate policy evaluation to external services selected by the person, so that consent and authorization decisions are not solely determined by the PS operator. To the rest of the protocol, the PS presents a single interface regardless of how it is composed internally.

## TLS Requirements

All HTTPS connections MUST use TLS 1.2 or later, following the recommendations in BCP 195 [@!RFC9325].

## Non-Repudiation and Audit After Key Rotation

AAuth signatures prove authenticity at request time: a valid HTTP Message Signature shows that the signer held the private key bound to the presented identity when the request was made (proof-of-possession). This is request-time authentication, not long-term non-repudiation. Agent keys are short-lived and agent providers rotate their JWKS; once a key is removed from the issuer's JWKS, a signature made with it can no longer be verified by re-fetching the JWKS later. The persistent identifiers — the agent token's `sub` and the person's directed `sub` — do not by themselves cryptographically prove that a specific key signed a specific request at a specific time once that key is gone.

This is partly by design — short-lived keys and directed identifiers (#directed-identifiers) limit long-term linkability. Deployments that require durable audit or non-repudiation beyond a key's lifetime SHOULD capture the evidence at verification time, while the key is still discoverable, rather than relying on re-verification later:

- **Archive the verified artifacts.** At verification time, record the signed request (covered components and signature), the `Signature-Key` value (the presented key or JWT), the verification result, and a trusted timestamp. Optionally snapshot the issuer's JWKS entry (`kid` + JWK) so the key binding can be re-checked independently of later rotation.
- **Use external timestamping or transparency logs** where stronger non-repudiation is needed — for example, RFC 3161 [@?RFC3161] timestamps over the signed request, or appending verification records to a tamper-evident log.
- **Bind audit records to durable identifiers.** Index archived records by `(iss, sub)` for agents and by `jti` for tokens, so later review can attribute activity even though the signing key is no longer live.

These measures trade privacy for durability: archived signatures and keys are correlatable, so deployments MUST balance audit retention against the privacy-preserving properties of short-lived keys and directed identifiers (#privacy-considerations), and apply appropriate retention limits and access controls.

A related case is the verifier that is the first to see the artifact, minutes or hours after it was signed. There the question is not whether evidence survives key rotation but whether the artifact was valid when it was signed, and the signed `created` parameter answers it (#freshness-and-replay).

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

The mission JSON is visible to the PS and, when included in resource tokens and auth tokens via the `s256` hash, its integrity is verifiable by any party that holds it. The approved mission JSON is shared between the agent and PS. Resources and ASes see only the `s256` hash and the PS that approved it, not the full mission content.

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

## Link Relation Type Registration

This specification registers the following link relation type in the IANA Link Relation Types registry per [@!RFC8288], Section 4.2:

- Relation Name: `aauth-resource`
- Description: Refers to the AAuth resource metadata document for the resource that the link context belongs to or describes.
- Reference: This document, (#resource-metadata-link)
- Notes: The target MUST be a server identifier followed by `/.well-known/aauth-resource.json`; recipients verify the document against the URL it was fetched from and do not use the relation for key discovery.

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
| `presented_jti` | The `jti` of the person token or auth token a resource token is bound to | IETF | This document |
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
  - Restructured for readability: sections follow the order an implementer meets them, each normative statement is made once, and rationale moved from Protocol Primitives to the Design Rationale appendix. Agent Identity is now Agents, with an Agent Provider subsection; Person Token moved under the Person Token Endpoint.
  - A revocation request's signature MUST cover `content-digest` and `content-type` at every recipient. Issue #165.
  - Token Revocation: a PS cascades an agent token revocation by agent identity; a recipient records revoked resource tokens it has not seen; added `rate_limited`; the polling `revoked` code covers any token a pending request depends on. Issues #178, #179, #180, #182, #185.
  - Token Revocation: defined polling of a `202`, the `200` body, and how long a recipient holds the connection. Issues #181, #183, #184.
  - A resource token MAY carry `login_hint`, which the agent passes to its PS. Issue #163.
  - Adoption Matrix: the Agent column names the auth token in the PS authorization and federated authorization rows. Issue #161.
  - The person token request takes the OPTIONAL parameters of the auth token request. Issues #175, #177.
  - Call chaining accepts a person token as `upstream_token`; downstream tokens expire no later than the upstream token and carry its `mission_s256`. A sub-agent's agent token `iss` MUST equal its parent's.
  - An intermediary MUST be its own agent provider.
  - A revocation recipient answers once its cascade is terminal, and an AS reports the outcome to the PS in `downstream`. A person token revocation reaches call chains. Issue #173.
  - The agent identifier `local` part accepts uppercase letters. Issue #164.
  - Added the person token (`aa-person+jwt`), `person_token_endpoint`, and `requirement=person-token`. Issues #87, #97.
  - Five resource access modes and the AAuth Access Mode Value Registry. Renamed `token_endpoint` to `auth_token_endpoint`; the resource-managed credential is the session token.
  - A resource MUST verify a person token or auth token before issuing a resource token. No token a resource reads carries an agent identifier; `act` removed. Auth tokens carry `ps` and a directed `sub`.
  - Added `presented_jti` and the `presented_token` parameter. Issues #95, #152.
  - Missions: `mission_s256` replaces the `mission` object; `AAuth-Mission` and `approver` removed; the mission endpoint takes propose, update, and completion; added `mission_terminated`.
  - Call chaining routes on the auth token's `ps` claim.
  - Token Revocation reworked: the request is `jti` and `exp`, each token type has one recipient, and a revoked token is answered `revoked_jwt` or `revoked_<parameter>_token`. Issues #146, #154.
  - Expiry: `exp` has no tolerance, `iat` is REQUIRED, and the agent refreshes with five minutes left.
  - A server signing in its own right uses the `jwks_uri` scheme. Requests with a body to a PS or AS MUST cover `content-digest` and `content-type`. Added `accept_signature_algs`. Issue #94.
  - Consent Presentation: resource-asserted and agent-asserted content MUST be visually distinguished.
  - Added the Supervisor role, the PS conformance floor, and the Minimal Person Server appendix. Removed Third-Party Login and `login_endpoint`. Issue #155.
  - `requirement=auth-token` MAY be delivered as a `202` deferred response. Added `as_unreachable` and the `aauth-resource` link relation. Issue #92.
  - Consistency pass: common JWT claims and verification stated once, typed error codes only for tokens passed as parameters, and every party MUST support `Ed25519`.

- draft-hardt-oauth-aauth-protocol-10
  - Adopted `Ed25519` ([@!RFC9864]) in place of `EdDSA`; `alg` is REQUIRED and fully specified. Issue #57.
  - A `cnf` JWK and every key at an AAuth server's `jwks_uri` MUST carry `alg`.
  - Aligned verification and error codes with [@!I-D.hardt-httpbis-signature-key].
  - Revocation identifies a token by `(iss, jti)`; an agent provider revokes an agent token at the PS. Issues #59, #60.
  - A downstream issuer MUST NOT copy a directed `sub` from an upstream token. Issue #41.
  - Added the OPTIONAL `account` authorization endpoint parameter. Issue #52.

- draft-hardt-oauth-aauth-protocol-09
  - Clarification chat: added the `action` discriminator.
  - Errors use RFC 9457 problem details.

- draft-hardt-oauth-aauth-protocol-08
  - Call chaining: upstream token `aud` MUST equal the intermediary's agent token `iss`; routing follows the upstream auth token.
  - The interaction code is a correlation identifier, not a credential.

- draft-hardt-oauth-aauth-protocol-07
  - Added Interaction Callback Errors. Added Joshua Gay to Acknowledgments.

- draft-hardt-oauth-aauth-protocol-06
  - Interoperability clarifications from Joshua Gay's feedback. The interoperability demo profile moved to a separate document.

- draft-hardt-oauth-aauth-protocol-05
  - `act` is OPTIONAL; `act.agent` names the immediate upstream agent.

- draft-hardt-oauth-aauth-protocol-04
  - Replaced `act.sub` with `act.agent`. Issue #47.

- draft-hardt-oauth-aauth-protocol-03
  - Metadata: added a common-fields table and documented the RFC 9728 divergences.
  - Metadata: added `documentation_uri`.
  - Updated the Crockford base32 citation.

- draft-hardt-oauth-aauth-protocol-02
  - Added sub-agents.
  - Renamed `interaction_required` to `user_unreachable`; added `interaction_unavailable` and `max_wait`.
  - Added `capabilities` and `prompt` to the PS token endpoint.
  - Added `requirement=agent-token`.
  - Added the `access_mode` resource metadata field and two walkthroughs.
  - Added a Markdown `description` to each metadata document.
  - The returned `issuer` MUST match the metadata URL.
  - Call chaining: the intermediary signs with its own key.
  - Added rationale for the mandated covered components.
  - Added a Security Consideration on non-repudiation after key rotation.
  - Added a pointer to AAuth Bootstrap.
  - Diagrams use snake_case token names.
  - Named the mission reference.
  - AAuth never uses `WWW-Authenticate`.
  - Specified the interaction `code` format.
  - Editorial consistency pass.

- draft-hardt-oauth-aauth-protocol-01
  - Renamed PS-managed access to PS-asserted access.
  - Renamed Agent Server to Agent Provider.
  - Added Roles.
  - Added Policy Evaluation Points.
  - Added PS-AS Collapse.
  - Added Trust Posture in PS-Asserted Access.
  - Added the `platform` and `device` request parameters and the AAuth Platform Value Registry.
  - Replaced `org` with the `tenant` claim.
  - Consistency pass.
  - The AAuth Bootstrap reference is informative.

- draft-hardt-oauth-aauth-protocol-00
  - Initial draft. Replaces [draft-hardt-aauth-protocol-02](https://datatracker.ietf.org/doc/draft-hardt-aauth-protocol/02/); no technical changes.

# Acknowledgments

The author would like to thank reviewers for their feedback on concepts and earlier drafts, and contributors who raised issues and pull requests: Aaron Parecki, Ben McAdams, Christian Posta, Danny Fuhriman, Dasith Wijesiriwardena, David Brossard, Frederik Krogsdal Jacobsen, He Gu, Jared Hanson, Jeoffrey Haeyaert, João André Marques, Joi Ito, Joshua Gay, Karl McGuinness, Ken Huang, Lukas Friman, Mark Hendrickson, Mayur Agnihotri, Nate Barbettini, Nick Gamb, Paul Carleton, Rohan Harikumar, Sanjay Dalal, Scott Motte, Wils Dawson, Yolanda Cao, Zeeshan Khan.

{backmatter}

# Detailed Flows {#detailed-flows}

This appendix provides flow diagrams for the chaining patterns defined in the main specification, where the choreography is hard to follow from prose alone.

## Four-Party: Call Chaining {#flow-call-chaining}

See (#call-chaining) for normative requirements. Resource 1 acts as an agent, sending the downstream resource token, the person token it presented to Resource 2, its own agent token, and the upstream token to the PS. The flow shows an agent that presented an auth token to Resource 1; one that presented a person token, to a Resource 1 serving on identity, is the same with the person token as `upstream_token`.

~~~ ascii-art
Agent        Resource 1       Resource 2          PS
  |              |                |                 |
  | HTTP Sig w/  |                |                 |
  | auth_token   |                |                 |
  |------------->|                |                 |
  |              |                |                 |
  |              | HTTP Sig w/    |                 |
  |              | R1 person_token|                 |
  |              |--------------->|                 |
  |              |                |                 |
  |              | 401            |                 |
  |              | + resource_tok |                 |
  |              |<---------------|                 |
  |              |                |                 |
  |              | POST auth_token_endpoint         |
  |              | resource_token from R2           |
  |              | presented_token                  |
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
  |              | HTTP Sig w/    |                 |
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
  |         | HTTP Sig req |               |          |
  |         |------------->|               |          |
  |         |              |               |          |
  |         |              | HTTP Sig w/   |          |
  |         |              | R1 person_tok |          |
  |         |              |-------------->|          |
  |         |              |               |          |
  |         |              | 401           |          |
  |         |              | + resource_tok|          |
  |         |              |<--------------|          |
  |         |              |               |          |
  |         |              | POST token_ep |          |
  |         |              | resource_tok, |          |
  |         |              | presented_tok,|          |
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
  |         |              | HTTP Sig w/   |          |
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

# A Minimal Person Server {#minimal-ps}

This appendix is informative. It describes how a person server serving one person — self-hosted, or a small service — composes from what this document already defines, and points at the sections that govern each step. It adds no requirement.

**Metadata.** The floor is the four REQUIRED fields (#ps-metadata): `issuer`, `jwks_uri`, `person_token_endpoint`, and `auth_token_endpoint`. A minimal PS publishes those and nothing else. It has no `mission_endpoint`, so agents cannot propose missions to it and every request is evaluated on its own; no `permission_endpoint` or `audit_endpoint`; no `interaction_endpoint`, so an agent that would have relayed an interaction directs the person to it itself (#interaction-relay); and no `mission_control_endpoint`. A `revocation_endpoint` is RECOMMENDED, since it is how the person's agent provider tells the PS to stop honoring an agent (#token-revocation).

**One person.** Every agent that reaches the PS acts for the same person, so agent-person binding (#agent-person-binding) reduces to the first approval: the PS records the agent's `(iss, sub)` on the first token it issues for it, and thereafter recognizes it. The approving party still has to be authenticated (#ps-approval-endpoint-auth): a loopback-only PS relies on the operating system, and one reachable from a network authenticates the person before acting on a tap or a reply.

**Person tokens.** The person token endpoint (#person-token-endpoint) derives one directed `sub` per resource (#directed-identifiers) — a keyed hash of the resource identifier is enough, provided the key is kept — issues the token bound to the agent's key, and records its `jti`, `aud`, and `exp` for revocation (#person-token-endpoint); the agent presents the token itself when it requests an auth token. The first token for a resource the person has not used is the moment to ask them (#person-token-exposure); later ones for the same resource need not be.

**Auth tokens.** At the auth token endpoint (#ps-token-endpoint), a resource token whose `aud` is the PS is answered directly: the PS decides on consent and issues the auth token itself. One whose `aud` is an access server is federated (#ps-as-federation), presenting the resource token, the agent token, and the presented token the agent supplied (#ps-to-as-token-request). A minimal PS that never expects four-party access can decline the second case; one that supports it needs nothing beyond an HTTP client and its own signing key.

**Consent without a consent page.** The PS answers any request that needs the person with a `202` deferred response carrying `requirement=interaction`, a `url`, and a `code` (#requirement-responses) and (#deferred-responses). The `url` can be a page the PS serves, but it need not be visited: the PS MAY complete the interaction over a channel it already has — a notification the person taps, a message they reply to — and the code is consumed at that completion (#user-interaction). The pending URL then returns the terminal response on the agent's next poll. A queue of pending decisions, each resolved by one tap, is the whole of the consent surface; the Consent Presentation rules (#consent-presentation) apply to what the tap shows.

**Long waits.** The person may not answer for hours. The pending record lives as long as the PS chooses (#pending-url-security); the resource token the request carried will have expired by then, and the agent obtains a fresh one and resubmits (#resource-tokens). The PS remembers the decision it already has and applies it to the resubmission without asking again (#resource-tokens).

**Supervision.** The person is the Supervisor (#roles). Every decision the PS cannot make from what it already recorded waits on them, which is the right default for one person and a handful of agents. A PS that wants to answer routine requests without waking the person applies a standing policy on their behalf; how it consults a supervision server for that is left to a companion specification (#roles), and is the one thing a minimal PS grows into rather than starts with.

# Design Rationale

## Identity and Foundation

### Why Per-Instance Agent Identity

OAuth's `client_id` identifies an application — every instance of the same app shares a single identifier and typically a single set of credentials. AAuth's `aauth:local@domain` agent identifier identifies a specific instance with its own signing key. This enables per-instance authorization (grant access to this specific agent process, not all instances of the app), per-instance revocation (revoke one compromised instance without affecting others), and per-instance audit (trace every action to the specific instance that performed it). The agent provider controls which instances receive agent tokens, providing centralized control over a distributed agent fleet.

### Why Agents Are Under an Agent Provider {#why-agents-are-under-an-agent-provider}

Placing agents under an agent provider rather than allowing each agent to self-certify its own identity serves two purposes. First, **scale**: a single agent provider can issue, rotate, and revoke agent tokens across a fleet of thousands of instances. Resources and PSes verify agent tokens by fetching the AP's JWKS — one trust anchor for all agents from that provider — rather than performing individual key management with each instance. Second, **policy enforcement**: the AP is a natural PEP for agents. It controls which agent instances receive tokens, what identity claims they carry, and when tokens are denied or revoked. An agent that is also its own AP would bypass this layer entirely, eliminating the enforcement point without gaining anything: the protocol complexity increases while the security properties weaken. AAuth therefore requires every agent to hold a token issued by a distinct AP, not self-signed.

### Why Every Agent Has a Person

Every agent acts on behalf of a person — the entity accountable for the agent's actions. AAuth enables a person server to maintain this link, making it visible and enforceable across the protocol. When present, the PS ensures there is always an accountable party for authorization decisions, audit, and liability.

### Why Person Tokens

An agent identifier embeds its agent provider's domain, so a person moving to another provider necessarily arrives at a resource as someone new, losing whatever state the resource held for them. The person is the party the resource has a relationship with — the account, the history, and any standing limits are theirs — and keying on `(iss, sub)` makes that relationship survive the change. It also keeps agent providers from becoming gatekeepers: a resource that never learns which agent product is calling cannot condition access on it.

Identifying the person at the authorization endpoint rather than after authorization also lets the resource decide before it commits. Account selection (#account-binding), standing policy for that person, and any per-person limit are all evaluable when the request arrives, instead of after a resource token has been issued and taken to a PS.

### Why a Mission Belongs to an Agent

A person's relationship with a resource survives their changing agents, but a mission does not: it names one agent, and moving to another means proposing a new mission. The two are different things with different lifetimes. `sub` identifies the person, durably, because the resource's account and history are theirs. A mission is a grant of latitude to one agent to pursue one piece of work, and the person server evaluates every request against the record of what that agent has already done under it. Carrying that record across a change of agent would attribute one agent's history to another.

The practical effect is that anything done under a mission identifier was done by the agent the mission names, which is what makes the mission log worth reading.

### Why No Agent Identifier Reaches a Resource {#why-no-agent-identifier}

Naming the agent, or its provider, in a token the resource reads would restore exactly the coupling the person token exists to remove: a resource able to see either can pin policy to it, and the person's relationship stops surviving a change of agent. So neither the person token, the resource token, nor the auth token carries one. `agent_jkt` and `cnf` still bind every request to one key. The consequence for resource policy is stated in (#resource-access-modes): a decision keyed on the agent identifier holds in the two-party modes and nowhere else.

The agent token still reaches the AS, because a resource deploys an AS to have policy evaluated and an agent token MAY carry claims bearing on that — attestation, platform integrity, workload identity. The resource enforces; the AS evaluates; posture goes to the evaluator. The consequence is that agent-provider independence is complete in three-party and partial in four-party, where the resource has explicitly delegated policy to an AS.

### Why Identity Alone Can Authorize

A person token carries no authorization, yet a resource in person-identity mode (#overview-person-identity) serves requests on it. That is not a contradiction: the person server has authorized nothing, and the resource has decided that knowing the person is enough — the same decision it makes after a login it ran itself. Signing in to a site with an identity provider gets whatever that site gives signed-in people, and no one describes the identity assertion as an authorization.

What follows is that issuing a person token is consequential even though it grants nothing. The person server is deciding that this agent may act at this resource as this person, bounded by whatever that resource does on identity. That is why the question put to the person at first issuance is about acting, not naming, and why a person server should know what the resource does with identity before it asks.

### Why the Mission Is Encoded Rather Than Nested

The approval response carries the mission blob base64url-encoded rather than as a JSON object so that `s256` has an unambiguous byte sequence to cover. A nested object has no defined serialization once it is inside an envelope — the receiver would have to re-serialize it to hash it, and any difference in key order, whitespace, or escaping produces a different digest. Encoding makes the string itself the bytes, so the agent decodes, hashes, and compares, which is the operation it already performs on a JWT payload.

An earlier revision avoided the problem by making the response body the mission and putting `s256` in a header, which worked but left no room in the response for anything else. The encoded member restores that room without giving up verifiability.

### Why a Resource Token Names the Person Token {#why-presented-jti}

Binding by `presented_jti` rather than by comparing claims is what makes mission stripping detectable. A resource cannot drop `mission_s256` and present the result as an unscoped request, because the agent hands the person server the token the resource verified, under its issuer's signature, and the person server compares. Comparing claims alone cannot work: an agent running concurrent missions holds several person tokens for the same resource, so "the person token issued for this agent and resource" does not identify one, and a resource that omitted `mission_s256` could not be caught. Naming the token pins which one, and the `jti` check rejects a substitute.

The same reasoning is why the agent carries the token rather than the person server looking it up. The person server issued the person token and could retain it, but on a step-up the resource token names an auth token, which in four-party the access server issued and the person server never held. The resource, for its part, has nothing to look up by: an auth token carries no reference to the person token or the resource token it followed from, and `(ps, sub, agent key)` is the tuple just shown not to identify one. So the resource names the token it just verified, the agent passes that token along, and the person server and the access server run one verification with no record on the request path.

### Why Tool Pre-Approval Is Not Enforced {#why-tools-are-not-enforced}

Tool use is local to the agent. No party the protocol can hold to account observes it, so `approved_tools` is a record of what the person agreed to rather than a control that stops anything. Its value is that a departure from it is visible afterwards, in the mission log and in what the agent reports to the audit endpoint.

The enforcement that does exist sits outside the protocol and is worth naming: the runtime that decides whether to call a tool is built by the agent provider, and the agent provider attests the agent. A person's leverage over local actions is therefore their choice of agent provider, not the tool list. The auth token is the only hard control AAuth offers, and it covers remote resources.

### Why There Is No Delegation Chain Claim

Earlier revisions recorded the upstream chain in an `act` claim. It served no reader. The immediate caller in a chain signs the request with its own key and presents its own credentials, so a downstream resource already knows who is calling; `act` named the parties one and two hops further up, which the downstream has no relationship with and cannot evaluate. Those parties are also the person's tooling, disclosed to a resource that did not need them.

The chain is held by the person server, which authorizes every hop and holds the mission log. The same reasoning that made the resource stop attributing missions makes it stop recording delegation: the resource enforces, the person server attributes.

### Why the `ps` Claim in Agent Tokens

A resource learns the agent's PS from the person token it verifies, but it needs to know the agent has one before that — to decide whether to challenge for a person token at all, and to know that the `auth-token` flow is available. The `ps` claim in the agent token provides that, separately from mission supervision.

## Protocol Mechanics

### Why `.json` in Well-Known URIs

AAuth well-known metadata URIs use the `.json` extension (e.g., `/.well-known/aauth-agent.json`) rather than the extensionless convention used by OAuth and OpenID Connect. The `.json` extension makes the content type immediately obvious — no content negotiation is needed. More importantly, it enables static file hosting: a `.json` file served from GitHub Pages, S3, or a CDN works without server-side configuration. This aligns with AAuth's self-hosted agent model (see [@?I-D.hardt-aauth-bootstrap]), where an agent's metadata can be published as static files with no active server.

### Why No Authorization Code

AAuth eliminates authorization codes entirely. OAuth authorization codes require PKCE ([@RFC7636]) to prevent interception attacks, adding complexity for both clients and servers. AAuth avoids the problem: the user redirect carries only the callback URL, which has no security value to an attacker. The auth token is delivered exclusively via polling, authenticated by the agent's HTTP Message Signature.

### Why `issuer` Rather Than `resource` in Metadata {#why-issuer-not-resource}

AAuth diverges from RFC 9728 on two points. It uses `issuer` as the primary identifier field in every metadata document so that a generic Signature-Key verifier can extract the signer identity uniformly from any `dwk` document without knowing which role it represents. And it uses unprefixed field names (`name`, `tos_uri`, `policy_uri`, `documentation_uri`) rather than the `resource_`-prefixed forms, for consistency across all four roles.

### Why These Covered Components {#why-covered-components}

The four mandated components each close a request-substitution attack, and all four are derivable by the agent at signing time on every platform, including browsers. `@method` prevents a captured signature from being replayed with a different method; `@authority` prevents cross-host replay; `@path` binds it to the endpoint; `signature-key` prevents key substitution.

`content-digest` and `content-type` are mandated at PS and AS endpoints because their request bodies carry members that decide what is authorized (`justification`, `mission_s256`, `resource`, the mission proposal itself), and every such endpoint takes a JSON body of known shape, so a digest costs the sender nothing. Resources serve arbitrary APIs, including bodyless requests and streamed uploads, so they declare what they need through `additional_signature_components` instead. A resource's revocation endpoint is the exception because it is defined by this document, not by the resource's API, and its body selects a token and adds to retained state.

### Why `401` for Every Signature Failure {#why-401-signature-failures}

The HTTP Signature Keys specification uses `400` for most signature failures and permits `401` for the recoverable ones. AAuth requests are authenticated by their signature, so a signature that does not verify is an authentication failure rather than a malformed request, and a single status keeps agent retry logic uniform.

### Why `account` Is Not `login_hint` {#why-account-not-login-hint}

`account` selects; it does not hint. `login_hint` ([@!OpenID.Core], Section 3.1.2.1) is a hint about who to authenticate at the party receiving it, and is consumed during a login. Nobody is being authenticated by `account`: the account is already connected at the resource, and the value has to survive into the issued tokens as a claim. Overloading `login_hint` would also conflate the person logging in at their PS with the account being acted on at the resource, which may belong to different namespaces entirely.

### Why a Revocation Has No "Not Found" {#why-revocation-no-not-found}

A recipient cannot distinguish a token it never saw from one it saw and no longer holds, and an answer that varied with what it holds would disclose that. A `200` says the revocation is recorded and the token will be refused; that is true whether or not the recipient ever held it.

### Why a PS Reports Nothing to the Agent Provider {#why-ps-reports-nothing-to-ap}

Any report to the agent provider, even a count of downstream revocations, would tell it which resources the person uses through that agent, which is what the PS exists to keep from it. The AS's report to the PS discloses nothing, since the PS already knows the resource as the person token's `aud`. The person is the party the rule protects, so a PS MAY report the per-recipient outcome to them.

### In Brief

- **URL-based server identity**: HTTPS URLs as server identifiers, and an agent identifier that names its provider's domain, enable dynamic ecosystems without pre-registration.
- **Standard HTTP async pattern**: `202 Accepted`, `Location`, `Prefer: wait`, and `Retry-After` apply uniformly to every endpoint, align with RFC 7240, replace the OAuth device flow, support headless agents, and carry clarification chat.
- **JSON rather than form encoding**: JSON is the standard format for modern APIs, for request and response bodies alike.
- **The callback URL has no security role**: tokens never pass through the user's browser; the callback is a UX optimization.
- **OpenID Connect vocabulary**: reusing its scope values, identity claims, and enterprise parameters lowers the adoption barrier.

## Architecture

### Why a Separate Person Server

The PS is distinct from the AS because they serve different parties with different concerns. The PS represents the person — it handles consent, identity, mission supervision, and audit. The AS represents the resource — it evaluates policy and issues tokens. Combining these into a single entity would conflate the interests of the requesting party with the interests of the resource owner, which is the same conflation that makes OAuth insufficient for cross-domain agent ecosystems.

### Why Five Resource Access Modes

The modes are not levels of protocol adoption but answers to one question: what does the resource need to know before it serves a request? A resource that only verifies agent signatures can start using AAuth today without deploying a PS or AS. One that needs the person can take a person token and decide for itself. One that wants a scope agreed with the person takes an auth token, and one that wants policy evaluated takes it from its own access server. Each mode is self-contained and useful — not a stepping stone to the "real" protocol — and a resource may use different modes on different endpoints, which is the common case: most calls need only identity, and a few sensitive operations warrant an authorization decision.

Resource-managed and person-identity access are kept separate because the difference is who established the person's identity, and that determines what the resource can rely on. In resource-managed access the resource ran its own flow, so it knows the person on its own terms and needs nothing from a person server. In person-identity access it accepts an identity a person server asserted, which is federated login — cheaper for the resource, and dependent on trusting that person server.

Agent governance (missions plus permission, audit, and interaction relay) works independently of all five.

### Why Resource Tokens {#why-resource-tokens}

In GNAP and OAuth, the resource server is a passive consumer of tokens — it verifies them but never produces signed artifacts. AAuth inverts this: the resource cryptographically asserts what is being requested by issuing a resource token that binds the resource's own identity, the agent's key thumbprint, the requested scope, and the mission context into a single signed JWT. This prevents confused deputy attacks — an attacker cannot substitute a different resource in the authorization flow because the resource token is signed by the resource. It also gives the resource a voice in every authorization and re-authorization, and provides a complete audit artifact linking the request to a specific resource, agent, scope, and mission.

### Why Session Tokens Are Opaque

In two-party mode, the resource returns an opaque wrapped token via the `AAuth-Access` header rather than a JWT auth token. This allows the resource to wrap its existing authorization infrastructure (OAuth access tokens, session tokens, etc.) without exposing internal structure. The token is bound to the AAuth signature — the agent includes it in the `Authorization` header as a covered component — so it cannot be stolen and replayed as a standalone bearer token.

### Why Missions Are Not a Policy Language

Missions are intentionally not a machine-evaluable policy language. AAuth separates two kinds of authorization decisions:

- **Deterministic policy** is handled by scopes, resource tokens, and AS policy evaluation. These are mechanically evaluable — "does this agent have `data.read` scope for this resource?" A policy engine (Cedar, OPA/Rego, or any other) can answer this question consistently and automatically.

- **Contextual supervision** is handled by missions, justifications, and clarification at the PS. These are the contextual decisions that policy engines cannot answer — "is booking a $10,000 flight reasonable for planning a weekend trip?" or "should this agent access the HR database given what it's trying to accomplish?" The mission description, the agent's justification for each resource access, and the clarification dialog between user and agent provide the context for these decisions.

Prior attempts to make authorization semantics machine-evaluable across domains have not scaled. OAuth Rich Authorization Requests (RAR) require clients and servers to agree on domain-specific `type` values and JSON structures — workable within a single API but combinatorially explosive across arbitrary services. UMA attempted cross-domain resource sharing with machine-readable permission tickets, but adoption stalled because resource owners, requesting parties, and authorization servers could not converge on shared semantics for what permissions meant across organizational boundaries. The fundamental problem is that the meaning of "appropriate access" is contextual, evolving, and domain-specific — it cannot be captured in a predefined vocabulary that all parties share.

Missions solve this differently. Rather than requiring all parties to agree on machine-evaluable semantics, AAuth concentrates supervision at the PS — the only party with full context. The PS has the mission description, the user's identity and organizational context, the agent's justification for each request, the history of what the agent has done so far, and a channel to the user for clarification. No other party in the protocol has this context, and no predefined policy language can substitute for it.

This context can be presented to humans or to agents acting as decision-makers. The PS does not need to evaluate missions deterministically — it presents the mission context, the justification, and the resource request to the Supervisor (#roles): the person at a consent screen, or a supervision server deciding on their behalf — an AI agent applying an organization's policy, or an automated system applying heuristics. As AI decision-making matures, supervision can shift from human review to agent evaluation — without changing the protocol. AAuth standardizes how context is conveyed to the decision-maker; it does not prescribe how the decision is made.

The mission's `description` is Markdown because it represents human intent, not machine policy. The `approved_tools` array provides structured machine-evaluable elements where appropriate. Resources and access servers do not need the mission content — they enforce their own deterministic policies independently. The mission is a further restriction applied by the PS, and only the PS has sufficient context to evaluate it. Distributing mission semantics to other parties would be both a privacy leak and a false promise of enforcement, since those parties lack the context to evaluate the mission meaningfully.

### Why Missions Have Only Two States

Missions are either **active** or **terminated**. There is no suspended state. An `expires_at` in the mission blob does not add a state — it declares in advance when the PS will treat the mission as terminated, which the person can see at approval time. A suspended state would require the agent to learn that the mission has resumed, but AAuth has no push channel from the PS to the agent — the agent can only poll. For short pauses (minutes), the deferred response mechanism already provides natural waiting via `202` polling. For long pauses (hours or more), the agent would need to poll indefinitely with no indication of when to stop, making suspension operationally equivalent to termination. Terminating the mission and creating a new one is cleaner — the PS retains the old mission's log for audit, and the new mission can be scoped appropriately for the changed circumstances that prompted the pause. This keeps mission lifecycle simple: a mission is alive until it is done.

## Comparisons with Alternatives

### Why Not mTLS?

Mutual TLS (mTLS) authenticates the TLS connection, not individual HTTP requests. Different paths on the same resource may have different requirements — some paths may require no signature, others a signed request, others verified identity, and others an auth token. Per-request signatures allow resources to vary requirements by path. Additionally, mTLS requires PKI infrastructure (CA, certificate provisioning, revocation), cannot express progressive requirements, and is stripped by TLS-terminating proxies and CDNs. mTLS remains the right choice for infrastructure-level mutual authentication (e.g., service mesh). AAuth addresses application-level identity where progressive requirements and intermediary compatibility are needed.

### Why Not DPoP?

DPoP ([@RFC9449]) binds an existing OAuth access token to a key, preventing token theft. AAuth differs in that agents can establish identity from zero — no pre-existing token, no pre-registration. The agent signs with its own agent token (#agent-tokens), which it obtains from its agent provider without any resource-side registration; no resource- or AS-issued token is needed to make the first identified call. DPoP has a single mode (prove you hold the key bound to this token), while AAuth supports progressive requirements from verified agent identity through authorized access with interactive consent. DPoP is the right choice for adding proof-of-possession to existing OAuth deployments.

### Why Not Extend GNAP

GNAP ([@RFC9635]) shares several motivations with AAuth — proof-of-possession by default, client identity without pre-registration, and async authorization. A natural question is whether AAuth's capabilities could be achieved as GNAP extensions rather than a new protocol. There are several reasons they cannot.

**Resource tokens require an architectural change, not an extension.** In GNAP, as in OAuth, the resource server is a passive consumer of tokens; a resource that signs what is being requested (#why-resource-tokens) changes that core assumption rather than extending it.

**Interaction chaining requires a different continuation model.** GNAP's continuation mechanism operates between a single client and a single access server. When a resource needs to access a downstream resource that requires user consent, GNAP has no mechanism for that consent requirement to propagate back through the call chain to the original user. Supporting this would require rethinking GNAP's continuation model to support multi-party propagation through intermediaries.

**The federation model is fundamentally different.** In GNAP, the client must discover and interact with each access server directly. AAuth's model — where the agent only ever talks to its PS, and the PS federates with resource ASes — is a different trust topology, not a configuration option. Retrofitting this into GNAP would produce a profile so constrained that it would be a distinct protocol in practice.

**GNAP's generality is a liability for this use case.** GNAP is designed to be maximally flexible — interaction modes, key proofing methods, token formats, and access structures are all pluggable. This means implementers must make dozens of profiling decisions before arriving at an interoperable system. AAuth makes these decisions prescriptively: one token format (JWT), one key proofing method (HTTP Message Signatures), one interaction pattern (interaction codes with polling), and one identity model (`local@domain` with HTTPS metadata). For the agent-to-resource ecosystem, this prescriptiveness is a feature — it enables interoperability without bilateral agreements.

In summary, AAuth's core innovations — resource-signed challenges, interaction chaining through multi-hop calls, PS-to-AS federation, mission-scoped authorization, and clarification chat during consent — are architectural choices that would require changing GNAP's foundations rather than extending them. The result would be a heavily constrained GNAP profile that shares little with other GNAP deployments.

### Why Not Extend WWW-Authenticate?

`WWW-Authenticate` ([@!RFC9110], Section 11.6.1) tells the client which authentication scheme to use. Its challenge model is "present credentials" — it cannot express progressive requirements, authorization, or deferred approval, and it cannot appear in a `202 Accepted` response.

`AAuth-Requirement` and the `Accept-Signature-*` headers ([@!I-D.hardt-httpbis-signature-key]) coexist with `WWW-Authenticate`. A `401` response MAY include multiple headers, and the client uses whichever it understands:

```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer realm="api"
Accept-Signature-Scheme: jwt
```

A `402` response MAY include `WWW-Authenticate` for payment (e.g., the Payment scheme ([@?I-D.ryan-httpauth-payment])) alongside `Accept-Signature-Scheme` for authentication or `AAuth-Requirement` for authorization:

```http
HTTP/1.1 402 Payment Required
WWW-Authenticate: Payment id="x7Tg2pLq", method="example",
    request="eyJhbW91bnQiOiIxMDAw..."
Accept-Signature-Scheme: jwt
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
