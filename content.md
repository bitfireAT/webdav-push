
# Introduction

**(This document is in work and has not been submitted yet.)**

This document, below referred to as _WebDAV-Push_, provides a way for compliant WebDAV servers to send notifications about updated collections to subscribed clients over suitable push transports.

WebDAV-Push is intended as an additional tool to notify clients about updates in near time so that clients can refresh their views, perform synchronization etc.

A client SHOULD NOT rely solely on WebDAV-Push, so it should also perform regular polling like when WebDAV-Push is not available. However if WebDAV-Push is available, the polling frequency can be
significantly reduced.

Typical use cases:

- A mobile app synchronizes calendars/address books with device-local storage and wants to be notified on collection updates in order to re-synchronize.
- A desktop file manager shows contents of a WebDAV collection and wants to be notified on updates in order to refresh the view.
- A calendar Web app shows a CalDAV collection and wants to be notified on updates in order to refresh the view.


## Requirements language

{::boilerplate bcp14-tagged}


## Architectural overview

[^todo] Figure

[^todo]: TODO


## Terminology

If parts of a term are in brackets, it means that those parts may or may not be written together with the other parts. However it means the same in any case.

(Push) backend
: Part of a WebDAV-Push server that interacts with a specific push transport. In context of this document, there's only one backend for Web Push.

Push notification
: push message or delivery of a push message

Push message
: Actual network message that is sent from the WebDAV-Push server over a push service to the WebDAV-Push client. Notifies the client that a specific collection (identified by its push topic) has changed.
  
  In Web Push context, a server can send a push message (more exact, "request delivery of a push message") by `POST`ing the message to the client's subscription URL.

Push service
: Infrastructure that implements a specific push transport. The push service is the actual network service between WebDAV-Push server and WebDAV-Push client.
  
  For instance, if the push transport is Web Push and the client is a Web app, the push service would be provided by the vendor of the browser that the client runs in.

(Push) subscription (URL)
: The information that the client needs to provide to the server so that the server can send push notifications.
  
  If the transport is Web Push, the term "(push) subscription (URL)" as used in this document is equivalent to the Web Push term _push resource_. So for instance, a client could have connected to its Web Push service and receive `https://push.example.net/push/JzLQ3raZJfFBR0aqvOMsLrt54w4rJUsV` as the subscription URL.

(Push) topic
: Character sequence that identifies a WebDAV collection for push purposes (unique per WebDAV server). A specific collection could be reachable at different URLs, but it can only have one push topic.

(Push) transport
: Protocol that defines an actual push mechanism. In this document, Web Push is the only defined push transport. However, WebDAV-Push may also be used with other push transports like proprietary or yet unknown protocols. In that case, it has to be specified how to use that protocol with WebDAV-Push (like it's done for Web Push in {{transport-web-push}}). A push transport implementation may or may not involve a push service.

Rewrite proxy
: Push services sometimes require authentication from their users and consider their user to be an application vendor who has control over both the server and the client. For instance, a push service could be used by the vendor of a weather app who controls both the servers that deliver weather data and the clients, which are mobile apps that show the weather data. Both servers and clients can authenticate against the push service with the same private key.
  
  When however the server and clients are not in control of the same entity, like when the server is a WebDAV-Push server and the client is a mobile app that is not related to the server vendor, client and server can't have the same private key to authenticate against the push service. In that case, the client vendor may need to operate a rewrite proxy that receives each push message delivery request from a server, sign it with the same private key as the client and forwards it to the push service.

(W3C) Push API
: API for Web applications to use push notifications over Web Push

Web Push
: "Protocol for the delivery of real-time events to user agents", defined by {{RFC8030}}. Usually implemented in browsers (which means that major browser vendors provide their own push services), but there are also other implementations like {{UnifiedPush}}. Some parts of RFC 8030 (namely chapter 6 and HTTP/2 delivery between push service and client) specify implementation details that may be done by other means without changing the meaning of the RFC for WebDAV-Push servers and clients. There are also additional standards that can be considered to belong to Web Push (like VAPID, RFC 8292 and Message Encryption, RFC 8291).

WebDAV-Push
: WebDAV-based protocol to notify clients about updates in collections using a push transport (vs. polling). Specified in this document.

(WebDAV-Push) client
: WebDAV client that supports WebDAV-Push, for instance a CalDAV/CardDAV app on a mobile device

(WebDAV-Push) server
: WebDAV server (for instance a CalDAV/CardDAV server) that implements WebDAV-Push


## WebDAV server with support for WebDAV-Push

A WebDAV server that implements WebDAV-Push needs to

- advertise WebDAV-Push features and relevant information (service detection),
- manage subscriptions to collections and
- send push messages when a subscribed collection changes.

In order to manage subscriptions, a WebDAV server needs to

- provide a way for clients to subscribe to a collection (with transport-specific information),
- provide a way for clients to unsubscribe from collections,
- handle expired or otherwise invalid subscriptions.

Notifications about updates in collections have to be sent to all subscribed clients over the respective push transports.

The server must be prepared to handle errors. For instance, if a push transport signals that a subscription doesn't exist anymore, it must be removed and not be used again.


## WebDAV client with support for WebDAV-Push

A WebDAV client that implements WebDAV-Push typically

- detects whether the server supports WebDAV-Push and which push transports,
- connects to a push service (which is usually not operated by the same party as the WebDAV server),
- subscribes to one or more collections on the server (providing push service-specific details),
- receives push notifications that cause some client-side action (like to refresh the view or run synchronization),
- re-subscribes to collections before the subscriptions expire,
- unsubscribes from collections when notifications are not needed anymore.


## Push transports

WebDAV-Push is not restricted to specific push transports and allows clients to specify which push transports they support. This allows even upcoming, yet unknown push transports to be used with WebDAV-Push.

WebDAV-Push implementations SHOULD implement at least the Web Push transport (defined in {{transport-web-push}}).

For proprietary push services, client vendors may need to provide a rewrite proxy that signs and forwards the requests to the respective proprietary service.

Push transport definitions can define extra properties and additional processing rules.



# Service detection

This section describes how a client can detect

- whether a collection supports WebDAV-Push,
- which push services are supported (may contain service-specific information).


## PROPFIND for WebDAV-Push

Example:

~~~
PROPFIND https://example.com/webdav/collection/
<?xml version="1.0" encoding="utf-8" ?>
<propfind xmlns="DAV:" xmlns:P="DAV:Push">
  <prop>
    <P:push-transports/>
    <P:topic/>
  </prop>
</propfind>

HTTP/1.1 207 Multi-Status
<?xml version="1.0" encoding="utf-8" ?>
<multistatus xmlns="DAV:" xmlns:P="DAV:Push">
  <response>
    <href>/webdav/collection/</href>
    <prop>
      <P:push-transports>
        <P:transport><P:web-push /></P:transport>
        <P:transport>
          <P:some-other-transport>
            <P:some-parameter>...</P:some-parameter>
          </P:some-other-transport>
        </P:transport>
      </P:push-transports>
      <P:topic>O7M1nQ7cKkKTKsoS_j6Z3w</P:topic>
    </prop>
  </response>
</multistatus>
~~~

In this case, the requested collection supports WebDAV-Push in general (because it has a push topic). Two push transports can be used:

1. Web Push (see {{transport-web-push}}), without additional specific information
2. Some other transport, with some additional specific information that is required to use it. This is to illustrate that it WebDAV-Push supports other or future push transports, too.


## Element definitions

Name: `push-transports`  
Namespace: `DAV:Push`  
Purpose: Indicates which push transports are supported by the server.  
Definition: `<!ELEMENT push-transports (transport*)`  
Example: see below

Name: `transport`  
Namespace: `DAV:Push`  
Purpose: Specifies a push transport (like Web Push).  
Definition: `<!ELEMENT transport (web-push | %other-transport)`  
Example: see below

Name: `topic`  
Namespace: `DAV:Push`  
Purpose: Globally unique identifier for the collection.  
Definition: `<!ELEMENT topic (#PCDATA)`  
Description:

Character sequence that identifies a WebDAV collection for push purposes (globally unique). A specific collection could be reachable at different URLs, but it can only have one push topic.

A client MAY register the same subscription for collections from multiple servers. When the client receives a notification over such a shared subscription, the topic can be used to distinguish which collection was updated. Because the client must be able to distinguish between collections from different servers, the topics need to be globally unique.

Because push services will typically be able to see push messages in clear text, the topic SHOULD NOT allow to draw conclusions about the synchronized collection.

For instance, a server could use as a topic:

* a random UUID for each collection; or
* a salted hash (server-specific salt) of the canonical collection URL, encoded with base64.

Example: `<P:topic>O7M1nQ7cKkKTKsoS_j6Z3w</P:topic>`



# Subscription management

[^todo] ACL for registering subscriptions?


## Subscription registration

How to subscribe to collections on the WebDAV server. Required information:

- Collection to be subscribed
- Push transport, including transport-specific details
    - Web Push: push resource URL
    - (TODO details for message encryption)
- Expiration? how long by default, min/max (24 h), server decides (and can impose limits)
- (End-to-end-encryption? Or should it be defined per transport?)

[^todo] By now, only updates in direct members (equals `Depth: 1`) are sent. Maybe it could be specified that servers can send one notification per path segment? Implications?

To subscribe to a collection, the client sends a POST request with
`Content-Type: application/xml` to the collection it wants to subscribe. The root XML element of the XML body is `push-register` in the WebDAV-Push name space (`DAV:Push`) and can be used to distinguish between a WebDAV-Push and other requests.

The `push-register` element contains (exactly/at least?) one `subscription` element, which contains all information the server needs to send a push message.

Allowed response codes:

* 201 if the subscription was registered and the server wants to return additional information, like encryption details that are only valid for this subscription. Details have to be specified by the particular transport definition.
* 204 if the subscription was registered
* other response code with usual HTTP/WebDAV semantics (if possible, with `DAV:error` XML body)

[^todo] Always return expiration

In any case, when a subscription is registered the first time, the server creates a URL that identifies that registration (_registration URL_). That URL is sent in the `Location` header and can be used to remove the subscription.

Sample request for Web Push:

~~~
POST https://example.com/webdav/collection/
Content-Type: application/xml; charset="utf-8"

<?xml version="1.0" encoding="utf-8" ?>
<push-register xmlns="DAV:Push">
  <subscription>
    <web-push-subscription>
      <push-resource>https://up.example.net/yohd4yai5Phiz1wi</push-resource>
    </web-push-subscription>
  </subscription>
  <expires>Wed, 20 Dec 2023 10:03:31 GMT</expires>
</push-register>

HTTP/1.1 201 Created
Location: https://example.com/webdav/subscriptions/io6Efei4ooph
~~~



## Subscription updates

Every subscription has an identifier that uniquely identifies the (push transport, push service, client) triple. For Web Push, the identifier is the push resource URL.

A server MUST NOT register a subscription with the same identifier multiple times. Instead, when a client wants to register a subscription with an identifier that is already registered for the requested collection, the server MUST update the subscription with the given details and the expiration date. 

Allowed response codes:

* 201 if the registered subscription was updated and the server wants to share registration-specific details
* 204 if the registered subscription was updated
* 404 if the registration URL is unknown (or expired)
* other response code with usual HTTP/WebDAV semantics (if possible, with `DAV:error` XML body)

In any case, the server MUST return the registration URL in the `Location` header.


## Subscription removal

A client can explicitly unsubscribe from a collection by sending a `DELETE` request to the previously acquired registration URL.

Allowed response codes:

* 204 if the registered subscription was removed.
* 404 if the registration URL is unknown (or expired).
* other response code with usual HTTP/WebDAV semantics (if possible, with `DAV:error` XML body)

When a subscription registration is removed, no further push messages must be sent to the subscription.

Sample request:

~~~
DELETE https://example.com/webdav/subscriptions/io6Efei4ooph

HTTP/1.1 204 Unregistered
~~~


## Expiration

Clients can specify an expiration date-time when they register a subscription.

A server SHOULD take the expiration specified by a client into consideration, but MAY impose its own (often stricter) expiration rules, for instance to keep their database clean or because the
client has specified an implausible late expiration. Servers SHOULD keep registered subscriptions for at least a week.

Clients should refresh their registrations regularly because they can't rely on servers to keep their subscriptions until the client-specified expiration date. Clients SHOULD update subscription registrations at least every few days (significantly more often than weekly).

Expired subscriptions should be cleaned up on both server and client side and not be used anymore as chances are high that using such subscriptions will cause errors.


## Element definitions

Name: `push-register`  
Namespace: `DAV:Push`  
Purpose: Indicates that a subscription shall be registered to receive notifications when the collection is updated.  
Description:

This element specifies details about a subscription that shall be notified when the collection is updated. Besides the optional expiration, there must be exactly one `subscription` element that
defines the subscription details.

Definition: `<!ELEMENT push-register (expires?, subscription)`  
Example: see below

Name: `subscription`  
Namespace: `DAV:Push`  
Purpose: Specifies a subscription that shall be notified on updates. Contains exactly one element with details about a specific subscription type. In this document, only the `web-push-subscription` child element is defined.  
Definition: `<!ELEMENT subscription (web-push-subscription | %other-subscription)`  
Example: `<expires>Sun, 06 Nov 1994 08:49:37 GMT</expires>`

Name: `expires`  
Namespace: `DAV:Push`  
Purpose: Specifies an expiration date of the registered subscription.  
Description: Specifies an expiration date-time in the `IMF-fixdate` format {{RFC9110}}.  
Definition: `<!ELEMENT expires (#PCDATA)`  
Example: `<expires>Sun, 06 Nov 1994 08:49:37 GMT</expires>`



# Push notification

When content of direct members change. What is this exactly?

Data vs. metadata, only about members or also the subscribed collection itself? CalDAV/CardDAV: subscribe home-set?

Typically when CTag / sync-token changes.


## Push message

The push message body contains the topic of the changed collection.

Sample push message body:

~~~
<?xml version="1.0" encoding="utf-8" ?>
<push-message xmlns="DAV:Push">
  <topic>O7M1nQ7cKkKTKsoS_j6Z3w</topic>
</push-message>
~~~

Push notification rate limit?

Shall end-to-end encryption (for instance as described by RFC 8291) be possible / recommended /
required?

Shall a TTL value, as used by Web Push, be recommended in general, per transport, or not at all?

Shall multiple enqueued (and not yet delivered) push messages for the same collection be merged to a
single one (like _Replacing push messages_ with the `Topic` header in RFC 8030)? Maybe use a
timestamp? Shall this be specified in general, per transport or not at all?

CTag / sync-token?

How often / batch / delay?

Expiration ...

### Removal of invalid subscriptions

A WebDAV-Push server MUST ensure that invalid subscriptions (encountered when trying to sending a push notification) are removed at some time.

An invalid subscription is a subscription that push notifications can't be delivered to. Usually the push service returns an HTTP error code like 404 when it receives a notification for an invalid subscription. There may also be other conditions that render a subscription invalid, like a non-resolvable hostname or an encryption handshake error.

A server MAY use some logic like remembering the last successful delivery plus some tolerance interval to defer removal of an invalid subscription for some time. Doing so will make WebDAV-Push more reliable in case of temporary problems and avoid temporal "holes" between subscription removal and re-registration.


## Element definitions

[^todo] `push-message`



# Security considerations

Which information is shared with which party, especially public ones like the Google FCM +
implications? Involved parties:

* WebDAV server
* client
* push transports

Without E2EE, push transports can collect metadata:

* which WebDAV server notifies which clients,
* which clients are subscribed to the same collection (because they receive the same topic in the
  push message),
* at which times the collection is changed,
* other metadata (IP addresses etc.)

With E2EE, every push message is different and push transports can only relate clients over
heuristics, like the clients that are notified at the same time have probably subscribed the same
collection.

How sensitive are the data, how to minimize risks

What happens when information leaks

What happens when some component is hacked



# Web Push transport {#transport-web-push}

WebDAV-Push can be used with Web Push {{RFC8030}} as a transport to deliver WebDAV-Push notifications directly to compliant user agents, like Web browsers which come with their own push service infrastructure. Currently (2024), all major browsers support Web Push.

When the Web Push transport is used for WebDAV-Push,

* {{RFC8030}} defines how to generate subscriptions and send push messages,
* the WebDAV-Push server acts as Web Push application server,
* the WebDAV client (or a redirect proxy) acts as Web Push user agent.

Corresponding terminology:

* (WebDAV-Push) push subscription ↔ (Web Push) push resource
* (WebDAV-Push) push server ↔ (Web Push) application server
* (WebDAV-Push) push client (or redirect proxy) ↔ (Web Push) user agent

Usage of message encryption {{RFC8291}} and VAPID {{RFC8292}} is RECOMMENDED. If future protocol extensions become used by push services, WebDAV-Push servers should implement them as well, if applicable.

A WebDAV-Push server SHOULD use the collection topic as `Topic` header in push messages to replace previous notifications for the same collection.



## Subscription

Element definitions:

Name: `web-push`  
Purpose: Specifies the Web Push transport.  
Description: Used to specify the Web Push Transport in the context of a `<transport>` element, for instance in a list of supported transports.  
Definition: `<!ELEMENT web-push (EMPTY)`  
Example: `<web-push/>`

Name: `web-push-subscription`  
Purpose: Public information of a Web Push subscription that is shared with the WebDAV-Push server (Web Push application server).  
Description: Used to specify a Web Push subscription in the context of a `<subscription>` element,
for instance to register a subscription.  
Definition: `<!ELEMENT web-push-subscription (push-resource)`  
Example: see below

Name: `push-resource`  
Purpose: Identifies the endpoint where Web Push notifications are sent to. The push resource is used as the unique identifier for the subscription.  
Definition: `<!ELEMENT push-resource (#PCDATA)`  
Example:

~~~
<web-push-subscription xmlns="DAV:Push">
  <push-resource>https://push.example.net/push/JzLQ3raZJfFBR0aqvOMsLrt54w4rJUsV</push-resource>
</web-push-subscription>
~~~


## Push message

The push message is delivered via `POST` to the push resource, with `Content-Type: application/xml; charset="UTF-8"`.

The push topic SHOULD be used to generate the `Topic` header. Since RFC 8030 limits the `Topic` header to 32 characters from the URL and filename-safe Base64 alphabet, it's RECOMMENDED to use a hash of the push topic that meets these requirements as the header value.

The exact algorithm to derive the `Topic` header from the push topic can be chosen by the server.

The server MAY use the `Urgency` header to set the priority of the push message. For instance, a CalDAV server may send push notifications for new/changed events with alarms that are scheduled within the next 15 minutes with `Urgency: high` so that users receive the alarm as soon as possible. Updates that are not that time-critical for the user, for instance in slowly changing collections like a holiday calendar may be sent with `Urgency: low`.

Example:

Push topic: `O7M1nQ7cKkKTKsoS_j6Z3w`  
SHA1(push topic): `47788cfcf010ece3030175b8fa63276bbaea4862`  
As base64url: `R3iM_PAQ7OMDAXW4-mMna7rqSGI`

(Note that SHA1 doesn't serve a cryptographical purpose here and is just used to generate a fixed-length hash out of the variable-length topic.)

So push message delivery is requested with this header:

~~~
POST <push subscription URL>
Content-Type: application/xml; charset="UTF-8"
Topic: R3iM_PAQ7OMDAXW4-mMna7rqSGI

<push message body>
~~~


## VAPID

VAPID {{RFC8292}} SHOULD be used to restrict push subscriptions to the specific WebDAV server.

A WebDAV server which supports VAPID stores a key pair. The server exposes an additional transport property:

* `server-public-key` – VAPID public key in uncompressed form and base64url encoded; attribute `type="p256dh"` MUST be added to allow different key types in the future

Example service detection of a WebDAV server that supports VAPID:

~~~
<?xml version="1.0" encoding="utf-8" ?>
<multistatus xmlns="DAV:" xmlns:P="DAV:Push">
  <response>
    <href>/webdav/collection/</href>
    <prop>
      <P:push-transports>
        <P:transport>
          <P:web-push>
            <server-public-key type="p256dh">BA1Hxzyi1RUM1b5wjxsn7nGxAszw2u61m164i3MrAIxHF6YK5h4SDYic-dRuU_RCPCfA5aq9ojSwk5Y2EmClBPs</server-public-key>
          </P:web-push>
        </P:transport>
      </P:push-transports>
      <P:topic>O7M1nQ7cKkKTKsoS_j6Z3w</P:topic>
    </prop>
  </response>
</multistatus>
~~~

If available, the client SHOULD use this key to create a restricted subscription at the push service.

When the server sends a push message, it includes a corresponding `Authorization` header to prove its identity.


## Message encryption

Message encryption SHOULD be used to hide details of push messages from the push services.

Before creating the subscription, the client generates a key pair as defined in {{RFC8291}}.

When the client then registers this subscription at the server, it includes additional subscription properties:

* `client-public-key` – public key of the user agent's key pair in uncompressed form and base64url encoded; attribute `type="p256dh"` MUST be added to allow different key types in the future
* `auth-secret` – authentication secret

Example for a subscription registration requesting message encryption:

~~~
<web-push-subscription xmlns="DAV:Push">
  <push-resource>https://push.example.net/push/JzLQ3raZJfFBR0aqvOMsLrt54w4rJUsV</push-resource>
  <client-public-key type="p256dh">BCVxsr7N_eNgVRqvHtD0zTZsEc6-VV-JvLexhqUzORcxaOzi6-AYWXvTBHm4bjyPjs7Vd8pZGH6SRpkNtoIAiw4</client-public-key>
  <auth-secret>BTBZMqHH6r4Tts7J_aSIgg</auth-secret>
</web-push-subscription>
~~~

The server uses these data to encrypt the payload and send it to the push service. The client then decrypts the payload again.

