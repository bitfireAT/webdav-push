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

![Architectural overview diagram](images/Push%20overview.drawio.png)

## Application server

For instance. Nextcloud. We want to require as little changes in app server as possible so that it's easily adaptable by a lot of servers. All subscription and actual push distribution logic is out-sourced to the Push Director.

Required functions on app server:

- topic generation (TODO what is a topic)
- send notifications for every change in a collection to Push Director (over HTTP POST)
  - requires to store some configuration (store URL of Push Director)
- provide push-specific information (URL of Push Director and whether it requires authentication and which method) to WebDAV clients

## Push Director

Some standalone software that runs next to the application server. May be hosted together with the application server (can be private, pseudo-public like for ISPs or maybe a public fallback hosted by a client app developer like DAVx5).

Interfaces (incoming):

- Subscription API (HTTP POST, JSON) where Push Clients register and (un)subscribe to collections
  - authentication should be recommended when possible (but method may vary: hosted instances may require same authentication as for WebDAV, public instances like a DAVx⁵-hosted public instance may require a token that's derived from the DAVx⁵ FCM ID)
- API for the Application Server where the Push Director can receive a message for every changed collection (HTTP POST, JSON)

There should also be the possibility for additional non-standard subscription/notification APIs. For instance, a Push Client (TODO: is it possible that the
Push Director does that?) could subscribe to Google Calendars over [Google Calendar API Push notifications](https://developers.google.com/calendar/api/guides/push?hl=en)
and register a Webhook there. Then the Google Calendar would notify the Push Director, but not over the same `POST /update` as defined in this document, but by
some proprietary protocol. The Push Client still has to register to the Push Director so that the actual delivery of of the push notification
over a Push Service can work.

Outgoing side:

- sends filtered (see below) push notifications in correct format to the actual Push Services, like
  - one message per topic and FCM ID (+ FCM Proxy URL) to the Firebase FCM backend
  - one message per endpoint to UnifiedPush server
  - one message for every active and subscribed WebSocket connection
- filtering: only topics that have at least one subscriber in a backend module are forwarded to that backend (for instance, if no Push Clients are subscribed over FCM to a topic, this topic must not be sent to the Firebase FCM backend)

Configuration:

- which Push Services are enabled for this instance
- configuration of specific Push Services (like supported FCM IDs)

TODO: schematic of sample architecture of Push Director

- PubSub
- FCM backend
- UnifiedPush backend
- WebSockets backend
- How subscriptions are handled

## Push Services

Push Services are existing services that can be used for the actual push notifications., like (alphabetically)

- Apple Push Notification (APN) service (supports topics)
- [Google FCM](https://firebase.google.com/docs/cloud-messaging) (supports topics)
- [Huawei HMS](https://developer.huawei.com/consumer/en/hms/huawei-pushkit) (supports topics)
- [UnifiedPush](https://unifiedpush.org/) (one-to-one)
- WebSockets (one-to-one; we have to define how to use it for WebDAV Push)

We must support upcoming new Push Services.

### Google FCM

Topics

FCM redirector: DAVx⁵ would have to host their own FCM redirector

- How to reduce abuse? Require "authentication" with app-internal key; if it's really a problem we could also require a server key that must be obtained from the DAVx⁵ redirector. How do Nextcloud Push and Conversations FCM redirectors handle abuse?

![Flowchart: Push over FCM](images/FCM%20Flowchart.drawio.png)

### UnifiedPush

Endpoints

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

## Service detection: WebDAV

How Push Clients can detect

- whether the service / a collection supports WebDAV Push,
- which Push Services are supported. May contain Push Service-specific information like:
  - For FCM: indicate the supported FCM ID(s)
  - For WebSockets: whether/which authentication is required for incoming WebSocket connections (may contain further details; pre-define auth types *none*, *same as WebDAV*, …)
- whether/which authentication is required for the Subscription API (may contain further details; pre-define auth types *none*, *same as WebDAV*, …)

Note: it should be "easily" possible to detect the Push service over other protocols than WebDAV. It is then in no way limited to WebDAV and can be used to subscribe any "collection" that has an identifier that can be used as a topic.

TODO: WebDAV properties

## Subscription API

How to (un)subscribe to collections.

Authentication (see service detection)

~~Depth header: not specified now because of complexity.~~ By now, only updates in direct members (equals `Depth: 1`) are sent. Maybe it could be specified that servers can send one notification per path segment? Implications?

Required information:

- topic
- Push Service type + details
  - FCM: FCM ID, FCM redirector URL
  - UnifiedPush: endpoint
  - WebSocket: connection ID
- Expiration: how long by default, min max, server decides (and can impose limits)

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
