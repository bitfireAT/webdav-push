WebDAV Push
Draft Document

# Introduction

- rationale
- similiar technologies / ideas 
  * [JMAP Push](https://jmap.io/spec-core.html#push)
  * [Draft: Discovery of CalDAV Push-Notification Settings](https://github.com/apple/ccs-calendarserver/blob/master/doc/Extensions/caldav-pubsubdiscovery.txt)
  * [Draft: Push Discovery and Notification Dispatch Protocol](https://datatracker.ietf.org/doc/html/draft-gajda-dav-push-00)
  * [Symfony Mercury over SEE](https://mercure.rocks/spec)
- extending WebDAV and especially CalDAV/CardDAV
- multipurpose: provide specification for WebDAV, but should be adoptable for other protocols

This document, below referred to as _WebDAV Push_ or just _Push_, provides a way for Application
Servers to send notifications to subscribed clients over existing push distributors (like they're
provided by mobile operating system vendors) or custom implementations.

In a nutshell, there's a new component (Push Director) that can be run separately from the Application
Server and that handles everything regarding Push. The application server just needs to send all
update notifications to the Push Director, which forwards the notifications to the Clients.

Capitalized words like Application Server, Client etc. have a special meaning in the context of this document.


## Use cases

Client-side use cases:

- DAVx⁵ syncs to calendar
- file manager wants live updates for WebDAV collection
- Web Calendar wants live updates for CalDAV collections
- (vdirsyncer: tree updates – not strict requirement for now)

Server-side use cases:

- Private Self-hosted Nextcloud
  - Nextcloud-hosted Push Proxy
  - DAVx5-hosted FCM proxy
  - Nextcloud installed on some private Webhost
- Private Google-free Nextcloud
  - Nextcloud installed on private server
  - Push Proxy installed on private server
  - UnifiedPush installed on private server + set up on Android device
- Company Nextcloud (standard risk)
  - Nextcloud installed somewhere by IT dept
  - Push Proxy can be run in the company
  - Managed DAVx5: support for custom FCM proxy and/or UnifiedPush e.g. together with NextPush
  - alternative: protected second Push Gateway for Managed?
- Company Nextcloud (risk-exposed)
  - no information should be public at all (= no public FCM)


# Architectural overview

![Architectural overview diagram](images/architecture.png)

## Application Server

The Application Server is the component that generates update notifications that should be received by clients. For instance, this could be
a WebDAV/CalDAV/CardDAV server that wants to notify clients about updates in files.

One objective of Push is that as little changes as possible should be needed in the Application Server so that Push easily
adaptable by a lot of servers. All subscription and push distribution logic is outsourced to the Push Director.

A compliant Application Server needs to:

- generate topics (map each collection that can be subscribed to a topic name),
- send notifications for every change in a collection to the Push Director,
- provide push-specific information (URL of Push Director and whether it requires authentication and which method) to Clients.
This document describes how to provide this information over WebDAV, but there may be additional specifications for other protocols,
making Push available for non-WebDAV environments, too.

## Push Director

Some standalone software. May be hosted together with the application server. Usually private, but may also be provided pseudo-public
like for ISPs or even public (like a fallback server that's hosted by a Client app developer).

Push Director provides these inbound interfaces:

- [Notify API](#notify-api) for the Application Server to deposit update notifications (like collection changes)
- [Subscription API](#subscription-api) for Clients to register and (un)subscribe to collections

This document provides an HTTP-based specification for these APIs. Additional non-standard subscription/notification APIs
are possible. For instance, a Client could subscribe to a proprietary calendar system over a proprietary API, which
in turn informs the Push Director (that supports this special case) about updates with its own proprietary Webhook protocol.

Push Director receives the incoming update notifications and sends [Push Messages](#push-messages) to the
registered [Push Services](#push-services), which again forward them to subscribed Clients.

**NOTE**: Push Services may support topics, in which case the Push Director only needs to send one message per topic
and Push Service that supports topics. For Push Services that don't support topics (like UnifiedPush or WebSockets), Push
Director has to notify each client separately.

Implementations _MUST_ only forward notifications to Push Services which have at least one subscriber. So the Push Director
has to keep a list of active clients per topic.

A typical configuration file of a Push Director contains which Push Services are enabled for this instance and
Push Service-specific configuration (like authorization keys).

## Push Services

Push Services are existing services that can be used for the actual push notifications, like (alphabetically)

- Apple Push Notification (APN) service (supports topics)
- [Google FCM](https://firebase.google.com/docs/cloud-messaging) (supports topics)
- [Huawei HMS](https://developer.huawei.com/consumer/en/hms/huawei-pushkit) (supports topics)
- [UnifiedPush](https://unifiedpush.org/) (one-to-one)
- WebSockets (one-to-one; we have to define how to use it for WebDAV Push)

Implementations should be extendible for upcoming new Push Services.

### Google FCM

Topics

FCM redirector: DAVx⁵ would have to host their own FCM redirector

- How to reduce abuse? Require "authentication" with app-internal key; if it's really a problem we could also require a server key that must be obtained from the DAVx⁵ redirector. How do Nextcloud Push and Conversations FCM redirectors handle abuse?

![WebDAV Push over FCM Flowchart](images/fcm-flowchart.png)

### UnifiedPush

Endpoints

![WebDAV Push over UnifiedPush Flowchart](images/unifiedpush-flowchart.png)

### WebSockets

Define protocol how to deliver the topics to the WS client.

![Flowchart: Push over WebSockets](images/Websocket%20Flowchart.drawio.png)

## Push Clients

Software interested in being notified when certain collections are changed.

Sample scenarios:

- DAVx⁵ wants FCM notifications (with the DAVx⁵ Firebase ID) when certain synchronized CalDAV/CardDAV are changed.
- Another mobile app wants FCM notifications (with their own Firebase ID) when certain WebDAV collections are changed.
- Managed DAVx⁵ wants UnifiedPush notifications when certain synchronized collections are changed.
- Nextcloud Calendar app (in the browser) wants live updates over WebSockets when visible collections are changed. Similar: Nextcloud Contacts, Nextcloud Tasks
- Not for now, but later: Nextcloud Notifications, Nextcloud Deck etc… – same architecture, but not over WebDAV – generalization possible?
- Nextcloud Android app (for files) wants live updates for the shown collection as long as the view is active (over WebSockets)
- Desktop file manager (Gnome: Nautilus, KDE: Dolphin, …) wants live updates for a collection as long as the window is open (over WebSockets)
- (WebDAV folder DAVx⁵ live updates??)
- Desktop groupware (like KDE PIM, Thunderbird, Gnome Evolution) want live updates for visible collections (over WebSockets) but also notifications to sync in background (over Unified Push)
- vdirsyncer – does it make sense for that? WebSockets?

# Protocol definitions

Here we define how the commication between the components is done.

For HTTP all requests, the correct `Content-Type` header _MUST_ be sent.

## Service detection: WebDAV

How Push Clients can detect

- whether the service / a collection supports WebDAV Push,
- which Push Services are supported. May contain Push Service-specific information like:
  - For FCM: indicate the supported FCM ID(s)
  - For WebSockets: whether/which authentication is required for incoming WebSocket connections (may contain further details; pre-define auth types *none*, *same as WebDAV*, …)
- whether/which authentication is required for the Subscription API (may contain further details; pre-define auth types *none*, *same as WebDAV*, …)

Note: it should be "easily" possible to detect the Push service over other protocols than WebDAV. It is then in no way limited to WebDAV and can be used to subscribe any "collection" that has an identifier that can be used as a topic.

TODO: WebDAV properties

- subscription API access token

## Notify API

Defines how to notify the Push Director about changes over HTTP POST.

For authentication, a shared secret (token) between Application Server and Push Director is used. This token is sent to the Push Directory as Bearer token described in RFC 6750 (although it doesn't need to be an access token in OAuth terms). A Push Director _MUST NOT_ accept unauthenticated Notify API requests, even for private deployments.

---
Sample request from an Application Server, indicating that the resource corresponding to Topic `f0ec984b-4b19-4652-91f2-92c6d81c3c09` has been updated.

```
POST https://push-director.example.com/notify
Authorization: Bearer ohb_hLi2ain!oo5d
Content-Type: application/json

{ "topic": "f0ec984b-4b19-4652-91f2-92c6d81c3c09" }
```
---

## Subscription API

How to (un)subscribe to collections over HTTP POST.

Authentication is required, but method may vary: hosted instances may require a token transmitted over WebDAV or same authentication as for WebDAV; public instances like one hosted by a Client vendor may require a pseudo-public token that's integrated in the Client.

**TODO** How to get the token? Separate request, WebDAV property?

~~Depth header: not specified now because of complexity.~~ By now, only updates in direct members (equals `Depth: 1`) are sent. Maybe it could be specified that servers can send one notification per path segment? Implications?

Required information:

- topic
- Push Service type + details
  - FCM: FCM ID, FCM redirector URL
  - UnifiedPush: endpoint
  - WebSocket: connection ID
- Expiration: how long by default, min max, server decides (and can impose limits)

---
Sample request of a mobile Client:

```
POST https://push-director.example.com/subscribe
Authorization: Bearer ee2Ewoob#a!ingei
Content-Type: application/json

{
  "client_id": "0f069e09-4486-4a1a-85ff-fdad58400b11",
  "topic": "f0ec984b-4b19-4652-91f2-92c6d81c3c09",
  "push_services": {
    "fcm": {
      "registration_token": "FCM_REGISTRATION_TOKEN"
    },
    "unified_push": {
      "endpoint": "https://up.example.com/endpoint"
    }
  },
  "expires": 1698165940
}
```
---

## Push messages

Actual push message format; may depend on Push Service?

As little data as possible, i.e. usually **only the changed topic**.

## WebDAV Push over WebSockets

First guess, should be amended so that it can exchange other information (maybe put everything into JSON messages?). Also think about versioning (we could want future clients to be able to request a more advanced WebSockets protocol in the future).

1. Client establishes connection (authentication recommended).
2. Server generates a random *connection ID* and sends it to the client as one frame. (Other direction? Other method to get connection ID?)
3.  Client can subscribe to one or multiple topics using the Subscription API and request notifications over the WebSocket connection with the given connection ID.
4. When the server wants to send a push notification, it sends a frame containing the affected topic.

# Terminology

FCM ID: identifier for the Firebase key

Topic: identifies something that clients want to be notified about. In WebDAV context: identifies a collection (WebDAV folder, CalDAV calendar, CardDAV address book) whose updates clients are interested in. Must not contain sensitive information because it may be distributed over untrusted Push Services (like FCM). In WebDAV context: could be keyed hash of a canonical collection URL (with static per-server key)

# Security considerations

How sensitive are the data, how to minimize risks

What happens when information leaks

What happens when some component is hacked

Which information is shared with which component, especially public ones like the Google FCM + implications

Security recommendations:

- require authentication for the Push Director and used Push Services (e.g. WebSockets)
- disable FCM for highly sensitive environments because it involves publicly hosted components
