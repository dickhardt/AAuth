%%%
title = "AAuth Events"
abbrev = "AAuth-Events"
ipr = "trust200902"
area = "Security"
workgroup = "TBD"
keyword = ["agent", "events", "webhooks", "async", "subscribe", "http", "identity"]
category = "standard"

[seriesInfo]
status = "standard"
name = "Internet-Draft"
value = "draft-hardt-aauth-events-latest"
stream = "IETF"

date = 2026-06-24T00:00:00Z

[[author]]
initials = "D."
surname = "Hardt"
fullname = "Dick Hardt"
organization = "Hellō"
  [author.address]
  email = "dick.hardt@gmail.com"

%%%

<reference anchor="I-D.hardt-oauth-aauth-protocol" target="https://github.com/dickhardt/AAuth">
  <front>
    <title>AAuth Protocol</title>
    <author initials="D." surname="Hardt" fullname="Dick Hardt">
      <organization>Hellō</organization>
    </author>
    <date year="2026"/>
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

<reference anchor="I-D.hardt-aauth-r3" target="https://github.com/dickhardt/AAuth">
  <front>
    <title>AAuth Rich Resource Requests (R3)</title>
    <author initials="D." surname="Hardt" fullname="Dick Hardt">
      <organization>Hellō</organization>
    </author>
    <date year="2026"/>
  </front>
</reference>

<reference anchor="I-D.hardt-aauth-bootstrap" target="https://github.com/dickhardt/AAuth">
  <front>
    <title>AAuth Bootstrap Guidance</title>
    <author initials="D." surname="Hardt" fullname="Dick Hardt">
      <organization>Hellō</organization>
    </author>
    <date year="2026"/>
  </front>
</reference>

<reference anchor="AsyncAPI" target="https://www.asyncapi.com/docs/reference/specification/v3.0.0">
  <front>
    <title>AsyncAPI Specification 3.0.0</title>
    <author>
      <organization>AsyncAPI Initiative</organization>
    </author>
    <date year="2023"/>
  </front>
</reference>


.# Abstract

This document defines AAuth Events — an event subscription and delivery mechanism for agents operating under the AAuth Protocol ([@!I-D.hardt-oauth-aauth-protocol]). It specifies the subscribe token that agents use to register callbacks with resources, the event token that resources deliver when events fire, and the delivery path through the Agent Provider (AP). AAuth Events enables agents to receive asynchronous notifications without requiring a public endpoint, using the cryptographic identity established by the AAuth Protocol.

.# Discussion Venues

*Note: This section is to be removed before publishing as an RFC.*

Discussion of this document takes place on GitHub at https://github.com/dickhardt/AAuth. Issues, comments, and pull requests are welcome there. Source for this draft is in the same repository.

{mainmatter}

# Introduction

## Agents Cannot Receive Webhooks

Agents are often not servers with a routable endpoint. Whether running as a workload, a mobile app, or a single-page application, agents typically cannot receive inbound HTTP connections. Existing event delivery mechanisms — webhooks, WebSub, callback URLs — all assume the receiver is always-on and reachable. This assumption fails for agents that run intermittently, execute behind NAT, or live inside a platform that does not expose inbound HTTP.

At the same time, many interactions agents initiate are inherently asynchronous. An agent books a medical appointment and needs to know if an earlier slot opens. An agent monitors inventory and needs to know when a product becomes available. An agent submits an order and needs confirmation when it ships. In each case, the agent initiates a synchronous request, the resource accepts it, and then the resource needs to reach back to the agent when something changes — potentially hours or days later.

Existing approaches each fall short:

- **Webhooks** require the agent to have a public URL. Agents do not.
- **Polling** is wasteful and imprecise. For time-sensitive events like waitlist slots, polling is too slow and too expensive.
- **Server-Sent Events / WebSocket** require a persistent outbound connection, which conflicts with intermittent agent workloads.
- **Message queues** (SQS, Kafka, RabbitMQ) require shared infrastructure, are not web-standard, and have no standardized subscription protocol across trust domains.

## The Agent Provider as Inbox

The AAuth Protocol establishes that every agent has an Agent Provider (AP) — a stable, always-on server that issues the agent's identity token. The AP is already a first-class principal in the AAuth ecosystem: it has its own cryptographic identity, publishes metadata at a well-known URL, and is trusted by all parties that interact with the agent.

AAuth Events uses the AP as the agent's permanent event inbox. A resource that needs to notify an agent does not need to reach the agent directly — it posts the event to the AP's event endpoint. The AP delivers the event to the agent through whatever mechanism the AP and agent have established. The agent does not need a public URL. The AP is the public URL.

## What AAuth Events Provides

- **No public endpoint required**: The AP receives events on the agent's behalf. AP-to-agent delivery is platform-dependent and out of scope for this specification.
- **Cryptographic authorization**: The subscribe token is AP-signed and restricts event delivery to a specific resource. No shared secrets.
- **Agent identity at subscription time**: The resource knows cryptographically which agent subscribed, via the `sub` claim in the subscribe token.
- **Protected and public subscriptions**: Public event channels require only a subscribe token. Protected channels use a pre-authorized subscription URL issued by the resource during a prior authenticated interaction.
- **Event discovery via AsyncAPI**: Resources describe their event channels using AsyncAPI ([@AsyncAPI]) as an AAuth R3 vocabulary ([@!I-D.hardt-aauth-r3]).

## Relationship to Existing Standards

AAuth Events builds on the AAuth Protocol ([@!I-D.hardt-oauth-aauth-protocol]) and HTTP Signature Keys ([@!I-D.hardt-httpbis-signature-key]). It provides the transport and subscription mechanisms that AsyncAPI ([@AsyncAPI]) describes: resources use AsyncAPI to document their event channels and payload schemas, while AAuth Events defines how agents subscribe and how events are delivered.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

# Terminology

Terms defined in [@!I-D.hardt-oauth-aauth-protocol] are used here with the same meaning. In particular: Agent, Agent Provider (AP), Agent Token, Resource, Resource Token, Auth Token, Person Server (PS), Access Server (AS), and HTTP Sig.

This document additionally uses:

- **Subscribe Token**: A JWT issued by the AP to the agent, authorizing a specific resource to deliver events to the AP on the agent's behalf. Contains the Event ID and the agent's current signing key.
- **Event ID (eid)**: An opaque, AP-generated identifier that uniquely identifies a subscription at the AP. The agent maps the `eid` to its own context. The `eid` is the correlation key between the subscribe token, the AP's subscription record, and the event token.
- **Event Token**: A JWT issued and signed by the resource when an event fires, addressed to the agent (`aud` = agent identifier), and delivered to the AP's event endpoint.
- **Event Endpoint**: An endpoint published by the AP in its metadata at which resources deliver event tokens.
- **Subscription Ticket**: An opaque, short-lived value returned by a resource in response to an authenticated interaction, pre-authorizing a subsequent subscription registration call. Used when subscription to a protected channel requires prior authenticated context.

# Protocol Overview

AAuth Events involves four phases: setup, subscription registration, event delivery from resource to AP, and event delivery from AP to agent.

~~~~ ascii-art
Agent          AP                   Resource
  |             |                        |
  | (1) request |                        |
  |  subscribe  |                        |
  |  token      |                        |
  |------------>|                        |
  |             |                        |
  | subscribe   |                        |
  | token       |                        |
  |<------------|                        |
  |             |                        |
  | (2) signed request                   |
  |  w/ subscribe token                  |
  |------------------------------------->|
  |             |                        |
  |           200 OK                     |
  |<-------------------------------------|
  |             |                        |
  |             | ... time passes ...    |
  |             |                        |
  |             |  (3) POST event token. |
  |             |  (+ optional payload)  |
  |             |<-----------------------|
  |             |                        |
  |             |   202 Accepted         |
  |             |----------------------->|
  |             |                        |
  | (4) event   |                        |
  |  token +    |                        |
  |  payload    |                        |
  |<------------|                        |
~~~~
Figure: AAuth Events Protocol Overview {#fig-overview}

1. **Subscribe token acquisition (non-normative)**: The agent requests a subscribe token from its AP. The AP generates an `eid`, creates a subscription record, and issues a subscribe token. This interaction is AP-internal and out of scope for this specification. See (#non-normative-ap-agent) for examples.

2. **Subscription registration**: The agent presents the subscribe token to the resource as the `Signature-Key` JWT on a signed HTTP request to the resource's subscription endpoint. The resource validates the subscribe token, stores the `eid` and the AP's `event_endpoint` (resolved from the AP's metadata), and registers the subscription.

3. **Event delivery — resource to AP**: When an event fires, the resource issues an event token (a JWT signed by the resource) and POSTs it to the AP's `event_endpoint`, presenting the event token as the `Signature-Key` JWT. The optional request body carries the AsyncAPI-defined payload for the event type.

4. **Event delivery — AP to agent (non-normative)**: The AP validates the event, looks up the subscription by `eid`, and delivers the event token and any payload to the agent. This step is platform-dependent and out of scope for this specification. See (#non-normative-ap-agent) for examples.

# AP Metadata {#ap-metadata}

The AP MUST publish an `event_endpoint` claim in its metadata at `/.well-known/aauth-agent.json` if it supports AAuth Events. The `event_endpoint` is an HTTPS URL at which the AP receives event tokens from resources.

```json
{
  "issuer": "https://ap.example",
  "jwks_uri": "https://ap.example/.well-known/jwks.json",
  "event_endpoint": "https://ap.example/events"
}
```

The AP MAY update the `event_endpoint` URL at any time. Resources resolve the AP's `event_endpoint` from the AP's metadata (using the `iss` claim in the subscribe token to locate the AP's well-known document) rather than caching it from the subscribe token.

# Subscribe Token {#subscribe-token}

## Structure

A subscribe token is a JWT with `typ: aa-subscribe+jwt`, issued and signed by the AP, with the following claims:

Header:

- `alg`: Signing algorithm. EdDSA is RECOMMENDED. Implementations MUST NOT accept `none`.
- `typ`: `aa-subscribe+jwt`
- `kid`: Key identifier (AP's signing key)

Required payload claims:

- `iss`: Agent Provider URL. Used by the resource to locate the AP's metadata and `event_endpoint`.
- `dwk`: `aauth-agent.json` — the well-known metadata document name for key discovery ([@!I-D.hardt-httpbis-signature-key]).
- `sub`: Agent identifier. The AAuth agent identifier (`aauth:local@domain`) of the subscribing agent.
- `aud`: Resource URL. The resource that is authorized to deliver events for this subscription. The resource MUST verify that its own URL matches this claim.
- `cnf`: Confirmation claim ([@!RFC7800]) with `jwk` containing the agent's current public signing key. The resource uses this key to verify the HTTP signature on the subscription registration request.
- `eid`: Event ID. An opaque string generated by the AP, unique to the AP. The agent maps the `eid` to its own context (see (#agent-context-mapping)). The resource includes the `eid` in every event token it issues for this subscription.
- `iat`: Issued-at timestamp.
- `exp`: Expiration timestamp. The resource MUST reject subscribe tokens with `exp` in the past.

Optional payload claims:

- `max_uses`: A positive integer. If present, the AP MUST NOT accept more than this many event tokens for this `eid`. If absent, the subscription is unlimited. Enforcement is the AP's responsibility; the AP informs the resource of remaining uses in its `202 Accepted` response (see (#event-delivery)). The resource SHOULD track `remaining_uses` to manage subscription state — for example, prompting the agent to re-subscribe when the subscription is exhausted.

Example subscribe token payload:

```json
{
  "iss": "https://ap.example",
  "dwk": "aauth-agent.json",
  "sub": "aauth:k7q3p9n2@ap.example",
  "aud": "https://resource.example",
  "cnf": { "jwk": { "kty": "OKP", "crv": "Ed25519", "x": "..." } },
  "eid": "evt_8f3k2n9p",
  "iat": 1750000000,
  "exp": 1750086400,
  "max_uses": 1
}
```

## Presentation

The agent presents the subscribe token as the `Signature-Key` JWT on the subscription registration request, using `scheme=jwt`:

```http
POST /appointments/waitlist HTTP/1.1
Host: resource.example
Content-Type: application/json
Signature-Input: sig=("@method" "@authority"
    "@path" "signature-key" "content-type");created=1750000000
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;
    jwt="eyJhbGciOiJFZERTQSIsInR5cCI6ImFhLXN1Yitqd3QiLCJraWQiOiIuLi4ifQ..."

{
  "event_types": ["slot.available"]
}
```

The subscribe token replaces the agent token as the `Signature-Key` JWT for subscription registration requests. The `cnf.jwk` in the subscribe token provides the key the resource uses to verify the HTTP signature. The subscribe token is structurally analogous to the agent token — both are AP-signed JWTs carrying `cnf.jwk` — distinguished by `typ`.

## Verification

The resource MUST verify the subscribe token as follows:

1. Decode the JWT header. Verify `typ` is `aa-subscribe+jwt`.
2. Verify `dwk` is `aauth-agent.json`. Discover the AP's JWKS via `{iss}/.well-known/{dwk}` per ([@!I-D.hardt-httpbis-signature-key]). Locate the key matching `kid` and verify the JWT signature.
3. Verify `exp` is in the future and `iat` is not in the future.
4. Verify `aud` matches the resource's own URL.
5. Verify `cnf.jwk` matches the key used to sign the HTTP request.
6. Verify `eid` is present and non-empty.

After verification, the resource stores the subscription record with sufficient information to deliver events — at minimum `{eid, iss}` (the Event ID and the AP's issuer URL). When an event fires, the resource resolves the AP's `event_endpoint` from `{iss}/.well-known/aauth-agent.json` at delivery time, using standard HTTP caching for the well-known document.

## Agent Context Mapping {#agent-context-mapping}

The `eid` is the agent's correlation key. The agent maintains a local mapping of `eid` values to internal context — for example, "eid `evt_8f3k2n9p` corresponds to the appointment waitlist for Dr. Smith opened as part of mission `mission_xyz`". This mapping is the agent's own concern and is not defined by this specification.

# Subscription Registration {#subscription-registration}

## Public Subscriptions

For event channels that do not require prior authorization, the agent presents the subscribe token (as the `Signature-Key` JWT) on a signed POST to the resource's subscription endpoint. No additional credential is required. The resource validates the subscribe token per (#subscribe-token) and registers the subscription.

## Protected Subscriptions {#protected-subscriptions}

Some event channels require the agent to be authorized before it can register a subscription — for example, subscribing to events for a specific patient's appointments, or events associated with a particular account. In these cases, the resource does not accept subscription registrations from arbitrary agents; only agents that have already been authorized in an earlier interaction may register.

This specification defines a **pre-authorized subscription URL** pattern for protected subscriptions:

1. The agent makes an authenticated request to the resource (using an auth token obtained through one of the AAuth Protocol access modes).
2. The resource, if subscription to events is available for the context established by this interaction, returns a **subscription ticket URL** — an HTTPS URL that encodes a short-lived, single-use authorization to register a subscription. The ticket URL is opaque and is valid only for the specific context (agent, operation, and resource state) established in step 1.
3. The agent obtains a subscribe token from its AP.
4. The agent presents the subscribe token (as the `Signature-Key` JWT) on a signed POST to the subscription ticket URL. No additional auth token is required at this step; the authorization is embedded in the URL. The request body MAY include additional parameters as defined by the resource's AsyncAPI channel schema.
5. The resource validates the subscribe token, verifies the ticket in the URL is valid for the calling agent (by checking `sub` in the subscribe token matches the agent that triggered step 1) and has not been used before, and registers the subscription.

The subscription ticket URL is resource-controlled: the resource issues it, defines its scope and expiry, and enforces its single-use constraint. The ticket is not defined by this specification beyond the pattern above.

Example response from step 2:

```json
{
  "status": "unavailable",
  "next_available": "2026-08-24",
  "waitlist": {
    "subscribe_url": "https://resource.example/waitlist/st_9k2m_abc123",
    "event_types": ["slot.available"],
    "offer_window_seconds": 300
  }
}
```

Example subscription registration from step 4:

```http
POST /waitlist/st_9k2m_abc123 HTTP/1.1
Host: resource.example
Content-Type: application/json
Signature-Input: sig=("@method" "@authority"
    "@path" "signature-key" "content-type");created=1750000000
Signature: sig=:...signature bytes...:
Signature-Key: sig=jwt;
    jwt="eyJhbGciOiJFZERTQSIsInR5cCI6ImFhLXN1Yitqd3QiLCJraWQiOiIuLi4ifQ..."

{
  "event_types": ["slot.available"]
}
```

The HTTP signature covers the request path (including the ticket), cryptographically binding the subscribe token's identity to this specific ticket URL.

The resource SHOULD include the subscription ticket URL in an AsyncAPI channel parameter ([@AsyncAPI]) so that agents that discover the resource's event capabilities through its AsyncAPI document know to obtain the URL from a prior API response.

# Event Token {#event-token}

## Structure

When an event fires, the resource issues an event token: a JWT signed by the resource with the following claims:

Header:

- `alg`: Signing algorithm. EdDSA is RECOMMENDED.
- `typ`: `aa-event+jwt`
- `kid`: Key identifier (resource's signing key)

Required payload claims:

- `iss`: Resource URL.
- `dwk`: `aauth-resource.json` — the well-known metadata document name for key discovery ([@!I-D.hardt-httpbis-signature-key]).
- `aud`: Agent identifier (`aauth:local@domain`). The agent MUST verify this matches its own identifier.
- `eid`: Event ID. MUST match the `eid` from the subscribe token for this subscription. The AP uses the `eid` to look up the subscription record and route to the agent. The agent uses the `eid` to look up its local context mapping.
- `iat`: Issued-at timestamp.
- `exp`: Expiration timestamp. The agent MUST NOT act on an event token with `exp` in the past. The meaning of `exp` is event-specific — for time-sensitive events, it encodes the deadline by which the agent must act.

The event token is the transport and security layer. It carries no event-specific data. Event-specific content is delivered as the POST body alongside the event token (see (#event-delivery)).

Example event token payload:

```json
{
  "iss": "https://resource.example",
  "dwk": "aauth-resource.json",
  "aud": "aauth:k7q3p9n2@ap.example",
  "eid": "evt_8f3k2n9p",
  "iat": 1750200000,
  "exp": 1750200300
}
```

# Event Delivery: Resource to AP {#event-delivery}

## Request

When an event fires for an active subscription, the resource posts to the AP's `event_endpoint`, presenting the event token as the `Signature-Key` JWT. The POST body is the AsyncAPI-defined payload for the event type (OPTIONAL — omitted if the event carries no payload):

```http
POST /events HTTP/1.1
Host: ap.example
Content-Type: application/json
Signature-Input: sig=("@method" "@authority"
    "@path" "signature-key" "content-type" "content-digest");created=1750200000
Signature: sig=:...resource signing key signature bytes...:
Signature-Key: sig=jwt;
    jwt="eyJhbGciOiJFZERTQSIsInR5cCI6ImFhLWV2ZW50K2p3dCIsImtpZCI6Ii4uLiJ9..."

{
  "event_type": "slot.available",
  "slot_time": "2026-07-15T10:00:00Z"
}
```

The event token in `Signature-Key` provides the resource's identity (`iss`) and routing and authorization claims (`eid`, `aud`, `exp`). Unlike agent tokens and subscribe tokens, no `cnf.jwk` is needed: the resource has a stable JWKS discoverable from `{iss}/.well-known/{dwk}`, and the AP uses the same key (identified by `kid` in the JWT header) to verify both the JWT signature and the HTTP signature. This is an extension to the `Signature-Key` JWT scheme: when a JWT has `dwk` but no `cnf`, the verifier resolves the HTTP signing key from `{iss}/.well-known/{dwk}` using `kid` rather than from an inline `cnf.jwk`. The request body structure is defined by the resource's AsyncAPI message schema for the event type (see (#event-discovery)). The AP forwards both the event token and the payload body to the agent.

The resource resolves the AP's `event_endpoint` from `{iss}/.well-known/aauth-agent.json` at delivery time, using standard HTTP caching for the AP's well-known document.

## AP Validation

The AP MUST validate the event delivery request as follows:

1. Extract the event token JWT from the `Signature-Key` header. Verify `typ` is `aa-event+jwt`.
2. Discover the resource's JWKS via `{iss}/.well-known/{dwk}`. Locate the key matching `kid` and verify the JWT signature.
3. Verify the HTTP signature using the same key (matched by `kid`). This applies the `dwk`-without-`cnf` extension to the Signature-Key JWT scheme: the JWT signing key and the HTTP signing key are the same key, discoverable from the resource's well-known document.
4. Look up the subscription record by `eid`. If no active subscription exists for this `eid`, return `404`.
5. Verify `iss` matches the resource recorded at subscription time (the `aud` of the subscribe token for this `eid`).
6. Verify the event token `exp` is in the future.
7. If `max_uses` is set in the subscribe token, verify the use count has not been exceeded. Increment the use count atomically. If the use limit is reached, the AP MAY mark the subscription as complete after delivery.
8. Verify the event token `aud` matches the agent identifier in the subscription record.

If all checks pass, the AP returns `202 Accepted` and proceeds with delivery to the agent. The AP MUST NOT return `202` before the event has been durably recorded for delivery. If `max_uses` was set in the subscribe token, the AP MUST include a JSON response body with a `remaining_uses` field indicating how many more event tokens the AP will accept for this `eid`:

```http
HTTP/1.1 202 Accepted
Content-Type: application/json

{
  "remaining_uses": 0
}
```

When `remaining_uses` is `0`, the subscription is exhausted. The resource SHOULD clean up its subscription record and MAY prompt the agent to re-subscribe on the next interaction. When `max_uses` was not set, the AP returns `202 Accepted` with no body (or an empty JSON object).

The AP returns `400` for malformed requests, `401` if the resource's HTTP signature cannot be verified, `403` if the resource does not match the subscription's authorized resource, `404` if the `eid` is unknown or the subscription has expired, and `429` if `max_uses` has been exceeded.

# Event Delivery: AP to Agent {#ap-to-agent}

How the AP delivers the event token to the agent is platform-dependent and outside the scope of this specification. The AP is the agent's inbox; the internal mechanism is an implementation choice for the AP and agent.

See (#non-normative-ap-agent) for non-normative examples of AP-to-agent delivery for different platforms.

## Agent Verification

Upon receiving an event token (and optional payload) from the AP, the agent MUST:

1. Decode the JWT header. Verify `typ` is `aa-event+jwt`.
2. Discover the resource's JWKS via `{iss}/.well-known/{dwk}` per ([@!I-D.hardt-httpbis-signature-key]). Verify the JWT signature.
3. Verify `aud` matches the agent's own identifier.
4. Verify `exp` is in the future. If `exp` has passed, the agent SHOULD NOT act on the event (the response window has closed).
5. Look up `eid` in the agent's local context mapping to recover the context associated with this subscription.
6. Deduplicate: if the agent has already processed an event with this `eid` from this `iss`, it SHOULD ignore the duplicate. The `eid` is a natural idempotency key.

If a payload was included, the agent MAY use it directly. The payload structure is defined by the resource's AsyncAPI message schema for the event type.

# Event Discovery {#event-discovery}

Resources describe their event capabilities using AsyncAPI ([@AsyncAPI]) as an AAuth R3 vocabulary ([@!I-D.hardt-aauth-r3]).

## R3 Vocabulary Identifier

The vocabulary identifier for AAuth Events is:

```
urn:aauth:vocabulary:asyncapi
```

Resources that support AAuth Events SHOULD declare this vocabulary in their AAuth resource metadata:

```json
{
  "issuer": "https://resource.example",
  "r3_vocabularies": {
    "urn:aauth:vocabulary:openapi": "/openapi.json",
    "urn:aauth:vocabulary:asyncapi": "/asyncapi.json"
  }
}
```

## AsyncAPI Document

The resource's AsyncAPI document describes:

- **Channels**: Event streams the agent may subscribe to. Channels MAY use parameterized addresses (e.g., `/waitlist/{subscriptionTicket}`) when the subscription endpoint URL is dynamic (see (#protected-subscriptions)).
- **Operations**: `receive` operations on channels, with the security requirement and message schema.
- **Messages**: The payload schema for each event type. The AsyncAPI payload schema describes the `payload` field in the event delivery POST body (see (#event-delivery)). The AAuth event token envelope (`iss`, `aud`, `eid`, `exp`) is implicit and not part of the AsyncAPI schema.
- **Security schemes**: The AAuth subscribe token security scheme.

## Security Scheme

Resources MUST declare the AAuth subscribe token security scheme as follows:

```yaml
securitySchemes:
  aauth_subscribe:
    type: http
    scheme: aauth-subscribe
    description: >
      AAuth Subscribe Token (typ: aa-subscribe+jwt), issued by the agent's Agent
      Provider, presented as the Signature-Key JWT with HTTP Message Signatures.
      See draft-hardt-aauth-events.
```

Operations that require only a subscribe token declare:

```yaml
security:
  - aauth_subscribe: []
```

Operations that require a pre-authorized subscription URL (see (#protected-subscriptions)) have no security scheme on the subscription endpoint itself — the subscription ticket in the URL carries the authorization. The resource SHOULD annotate such channels with a description noting that the subscription URL is obtained from a prior authenticated API call.

## Example AsyncAPI Document

```yaml
asyncapi: 3.0.0
info:
  title: Appointments Events
  version: 1.0.0

channels:
  waitlistPublic:
    address: /appointments/waitlist/public
    messages:
      slotAvailable:
        $ref: '#/components/messages/SlotAvailable'

  waitlistProtected:
    address: /appointments/waitlist/{subscriptionTicket}
    description: >
      Subscription URL returned by POST /appointments when no slot is
      immediately available and the calling agent is authorized for
      waitlist access. The subscriptionTicket is embedded in the URL
      and carries the authorization context.
    parameters:
      subscriptionTicket:
        description: Single-use ticket from the POST /appointments response.
    messages:
      slotAvailable:
        $ref: '#/components/messages/SlotAvailable'

operations:
  subscribePublicWaitlist:
    action: receive
    channel:
      $ref: '#/channels/waitlistPublic'
    security:
      - aauth_subscribe: []

  subscribeProtectedWaitlist:
    action: receive
    channel:
      $ref: '#/channels/waitlistProtected'

components:
  messages:
    SlotAvailable:
      contentType: application/jwt
      payload:
        type: object
        properties:
          event_type:
            type: string
            const: slot.available
          slot_time:
            type: string
            format: date-time
          doctor_id:
            type: string
        required:
          - event_type
          - slot_time

  securitySchemes:
    aauth_subscribe:
      type: http
      scheme: aauth-subscribe
      description: AAuth Subscribe Token as Signature-Key JWT
```

# Security Considerations

## Subscribe Token Scope

The `aud` claim in the subscribe token restricts which resource may deliver events to the AP for this `eid`. If a resource attempts to deliver events for an `eid` issued to a different resource, the AP MUST reject the request (#event-delivery). This prevents a compromised resource from hijacking another resource's subscription channel.

## Event Token Forgery

Event tokens are signed by the resource using the resource's own signing key. The agent verifies the event token against the resource's JWKS ([@!I-D.hardt-httpbis-signature-key]). A party without the resource's private key cannot forge a valid event token. There are no shared secrets in AAuth Events.

## Replay Prevention

The AP enforces `max_uses` per `eid` and rejects event tokens with `exp` in the past. The agent additionally deduplicates on `eid` from the same `iss` (#agent-verification). These two layers prevent replay: a captured event token cannot be re-delivered once the AP has tracked its delivery and the agent has processed it.

## Subscribe Token Replay at Registration

A subscribe token with a valid `exp` could in principle be presented to the resource's subscription endpoint more than once. The `eid` is the deduplication key: the resource SHOULD reject subscription registration requests for an `eid` it has already registered. Single-use enforcement of the subscription ticket URL (in protected subscriptions) provides an additional constraint.

## Pre-Authorized Subscription URL Security

The subscription ticket URL (see (#protected-subscriptions)) encodes authorization from a prior authenticated context. Resources MUST ensure that subscription tickets are:

- Short-lived (expiry appropriate to the expected delay between issuing and using the ticket).
- Single-use (the resource invalidates the ticket on first successful subscription registration).
- Bound to the agent that triggered the prior interaction (the resource MUST verify that `sub` in the subscribe token matches the agent that established the ticket).

## AP as Delivery Intermediary

The AP sees every event token delivered to an agent. The AP validates the event token's `iss`, `aud`, and `eid` claims but does not need to inspect resource-specific payload claims. APs SHOULD document their data retention policies for event tokens.

## Resource Enumeration

A resource that exposes its AsyncAPI document publicly reveals what event types it emits. This may be intentional (public API). Resources that wish to restrict event type discovery MAY gate their AsyncAPI document with AAuth authentication.

# Privacy Considerations

## Agent Identifier Stability

The `sub` claim in the subscribe token carries the agent's stable identifier. Resources that receive subscribe tokens can correlate an agent's subscription activity over time. This is the intended property — the resource needs to know which agent subscribed. Agents and APs should be aware that subscription registrations leave a record at the resource.

## Event Content

The event token carries no event-specific data — it is the security and routing envelope only. Event-specific content travels in the `payload` field of the POST body (see (#event-delivery)), which is also visible to the AP during routing. Resources SHOULD NOT include sensitive personal data in the payload beyond what is necessary for the agent to evaluate relevance. Sensitive details SHOULD be fetched by the agent from the resource's data API using a current auth token.

# IANA Considerations

## JWT Type Values

This specification defines the following JWT `typ` header parameter values, to be registered in the IANA "JSON Web Token Types" registry:

- `aa-subscribe+jwt`: AAuth Subscribe Token.
- `aa-event+jwt`: AAuth Event Token.

## AAuth R3 Vocabulary Identifiers

This specification defines the following R3 vocabulary identifier:

- `urn:aauth:vocabulary:asyncapi`: AAuth AsyncAPI event vocabulary.

# Implementation Status

*Note: This section is to be removed before publishing as an RFC.*

TBD

# Document History

*Note: This section is to be removed before publishing as an RFC.*

- draft-hardt-aauth-events-00
  - Initial draft.

# Acknowledgments

TBD.

{backmatter}

# Design Rationale {#design-rationale}

This appendix explains the key design decisions in AAuth Events and the alternatives considered.

## Why the AP Is the Delivery Intermediary

Agents are workloads, not servers. They spin up, execute, and terminate. They run behind NAT, inside containers, or on mobile devices. They have no stable public endpoint.

Every existing push delivery mechanism (webhooks, WebSub, CIBA ping/push mode, W3C Web Push) assumes the subscriber has a stable HTTP endpoint. W3C Web Push is the closest analog to what AAuth Events does — it uses a browser push service (Google/Apple/Mozilla) as the subscriber's stable address. AAuth Events uses the AP in this role, with two improvements: the AP already has a trust relationship with the agent (it issued the agent's identity token), and the subscriber's identity is cryptographic (not just an opaque push service subscription).

The AP-as-inbox pattern mirrors how email works: you do not need to be online when someone sends you mail. The mail server is the stable address. AAuth Events gives agents the same property for event delivery.

## Why the Subscribe Token Is the Signature-Key JWT

The subscribe token simultaneously serves two functions: it proves the agent's identity (via `cnf.jwk` + HTTP signature) and registers the subscription (via `eid`, `aud`, `exp`). Presenting it as the `Signature-Key` JWT means a single signed HTTP request to the subscription endpoint accomplishes both without a separate credential or header.

This is structurally analogous to the agent token — both are AP-signed JWTs with `cnf.jwk`, distinguished by `typ`. The resource's verification path is the same whether it is processing an identity-based request with an agent token or a subscription registration with a subscribe token.

The alternative — a separate header or body parameter carrying the subscribe token alongside the normal agent token — was rejected because it requires two credentials where the subscribe token alone is sufficient.

## Why `aud` in the Subscribe Token Is the Resource

The `aud` claim restricts event delivery authorization to a specific resource. Only the resource named in `aud` may deliver events for this `eid` to the AP. This prevents:

- A compromised resource from injecting events into another agent's subscription channels.
- The AP from accepting events from unexpected callers.

The AP enforces this by matching the calling resource (identified by its HTTP signature) against the `aud` in the subscribe token stored in the subscription record.

## Why `exp` Is the JWT Validity Period, Not the Subscription Lifetime

Subscription lifetime is a negotiation between the agent and the resource at registration time. The resource has its own policy on maximum subscription duration. These durations can be days or months and are resource-specific.

The subscribe token's `exp` is the standard JWT validity window — how long the resource may accept this token for registration. Conflating JWT validity with subscription lifetime would either force a very long-lived token (security concern: replay window) or a very short subscription (UX concern: subscriptions expire before they're useful).

The resource stores the subscription record with whatever lifetime the agent and resource negotiate at registration. The subscribe token is a registration credential, not a subscription policy document.

## Why `max_uses` Is in the Subscribe Token

`max_uses` is the AP's throttle on how many event tokens it will accept for a given `eid`. It is AP-enforced, not resource-enforced. Placing it in the subscribe token — which the AP issued and controls — makes it AP-policy without requiring a separate AP configuration step.

For single-shot events (confirm this reservation), `max_uses: 1` ensures the AP accepts exactly one event. For ongoing subscriptions, `max_uses` is omitted (unlimited). When `max_uses` is absent, there is no sentinel value — absence means unlimited, avoiding any need for a special value such as -1.

The AP informs the resource of remaining uses in the `202 Accepted` response body after each delivery. The resource SHOULD use `remaining_uses: 0` as the signal to clean up its subscription record and prompt the agent to re-subscribe. This keeps the AP as the enforcement point while giving the resource the state it needs to manage the subscription lifecycle.

## Why the Event Token Is the Transport Layer, Not the Data Layer

The event token carries only what is needed for security, routing, and correlation: `iss`, `aud`, `eid`, `exp`. It is the cryptographic layer — the AP uses it to authenticate the resource, look up the subscription, and verify the delivery is authorized. The agent uses it to verify authenticity and look up its context via `eid`.

Event-specific data travels as a separate `payload` in the same POST body. The AsyncAPI message schema for the event type defines the payload structure. This separation keeps the JWT minimal and avoids embedding event data in a signed-but-not-encrypted envelope. For events where the agent needs full details beyond the payload, it fetches them from the resource's data API using a current auth token.

## Why `exp` in the Event Token Is the Response Window

The `exp` claim in the event token defines how long the agent has to respond to the event. Its meaning is event-specific: for a waitlist slot, it is the deadline by which the agent must claim the slot; for a shipping confirmation, it may be a much longer acknowledgment window.

The AP delivers events in near real-time. If the AP cannot deliver an event before its `exp`, the agent should not act on it (the response window has closed). The agent verifies `exp` before acting.

## Why Protected Subscriptions Use a Pre-Authorized URL

For protected event channels, the resource needs to verify that the subscribing agent has been authorized in a prior interaction before accepting the subscription. The naive approach — requiring both an auth token and a subscribe token on the subscription call — is awkward because the two tokens serve different purposes and the auth token conveyance alongside a `Signature-Key` subscribe token has no established AAuth pattern.

The pre-authorized subscription URL pattern solves this cleanly: authorization is captured in the prior authenticated interaction, and the resource returns a ticket URL that encodes this context. The agent then presents only the subscribe token at the ticket URL. The HTTP signature covers the URL path (including the ticket), binding the subscribe token's identity to this specific authorization context.

This mirrors established patterns (OAuth authorization codes, S3 presigned URLs) while preserving the AAuth Events invariant: all subscription endpoints accept only the subscribe token as the `Signature-Key` JWT.

## Why AsyncAPI Is the Discovery Vocabulary

AsyncAPI is the de facto standard for describing event-driven APIs. It describes channels, message schemas, security requirements, and (via parameterized addresses) dynamic subscription endpoints. The AAuth R3 vocabulary framework already accommodates multiple vocabularies per resource — AsyncAPI sits naturally alongside OpenAPI for synchronous operations.

The target reader of an AAuth resource's AsyncAPI document is an AAuth-capable agent, not generic AsyncAPI tooling. This means the `aauth_subscribe` security scheme (type: `http`, scheme: `aauth-subscribe`) does not need to be understood by Swagger UI or code generators — it is a declaration for the agent's benefit, interpreted per this specification.

## Comparison to Existing Patterns

| | AAuth Events | Webhooks | WebSub | CIBA (ping) | Web Push |
|---|---|---|---|---|---|
| Receiver needs public URL | No | Yes | Yes | Yes | No |
| Caller identity | Cryptographic (resource key) | HMAC shared secret | None | Client creds | Push service |
| Subscriber identity at resource | Agent identifier (`sub`) | None | None | Client ID | Subscription ID |
| Per-operation subscription | Yes | No (account-level) | No | Yes | No |
| General event types | Yes | Yes | Yes | No (auth only) | Yes |
| Standard description format | AsyncAPI (R3) | Proprietary | Atom/RSS | N/A | None |

# Non-Normative AP-to-Agent Delivery Examples {#non-normative-ap-agent}

How the AP delivers an event token to an agent is platform-dependent and not specified by this document. The following examples illustrate common patterns, paralleling the approach taken in [@?I-D.hardt-aauth-bootstrap] for agent token acquisition.

## Workload Agents

A workload agent (running in a cloud function, container, or batch job) may poll the AP for pending event tokens on startup, using an AP-internal endpoint. The AP acts as a durable inbox — storing event tokens until the workload polls. The workload validates and processes pending events before beginning its primary task.

## Mobile Agents

A mobile agent may receive events via the platform's native push notification infrastructure (APNs on iOS, FCM on Android). The AP holds a push token registered by the agent at enrollment time and delivers event tokens to the agent via push notification. The agent wakes on receipt, fetches the full event token from the AP if needed, and processes it.

## Web Agents

A web agent with a persistent session may receive events via a server-sent event (SSE) or WebSocket connection that the agent maintains to the AP. The AP streams event tokens over this connection as they arrive.

## Self-Hosted Agents

A self-hosted agent may receive events in two ways depending on whether it manages its own AP or delegates to an external one.

If the agent acts as its own AP ([@?I-D.hardt-aauth-bootstrap]), it may expose an internal event endpoint. Events are delivered directly to this endpoint by the resource — the AP and agent are collocated.

If the agent uses an external AP service, it maintains an outbound persistent connection (SSE, WebSocket, or a similar mechanism) to the AP's inbox service. The AP delivers event tokens and payloads over this connection as they arrive. The self-hosted agent does not need a public inbound endpoint — the outbound connection to the AP is sufficient.


