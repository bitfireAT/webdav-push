	WebDAV Push

Draft Document (In Work)


# Introduction

This document, below referred to as _WebDAV-Push_, provides a way for compliant
WebDAV servers to send notifications about updated collections to subscribed clients
over existing push transports.

WebDAV-Push notifications are intended as an additional tool to notify clients about updates in near time so that clients can refresh their views, perform synchronization etc.

A client must not rely on WebDAV-Push notifications, so it should also perform regular WebDAV access / synchronization like when WebDAV-Push notifications are not available. However if a client uses polling, it can significantly reduce the polling interval when WebDAV-Push notifications are available.

Capitalized words like Application Server, Client etc. have a special meaning in the context
of this document.

Typical use cases:

- mobile app synchronizes calendars/address books with device storage and wants to be notified on collection updates
- file manager lists contents of a WebDAV collection and wants to be notified on updates
- Calendar Web app shows a CalDAV collection and wants to be notified on updates


# Architectural overview

![Architectural overview diagram](images/architecture.png)

## WebDAV Server + WebDAV-Push Module

A WebDAV server that implements WebDAV-Push needs to

- advertise WebDAV-Push features and relevant information (service detection),
- manage subscriptions to collections and
- send push requests when a subscribed collection changes.

In order to manage subscriptions, a WebDAV server must

- provide a way for clients to subscribe to a collection (and provide transport-specific information),
- provide a way for clients to unsubscribe from collections,
- handle expired or otherwise invalid subscriptions.

Updates in collections have to be sent to all subscribed clients over the respective push transports.

The server must be prepared to handle errors. For instance, if a push transport signals that a subscription doesn't exist anymore, it must be removed and not be used again.

## Push Transports

WebDAV-Push isn't restricted to specific push transports and allows clients to specify which push transports they support. This allows upcoming push transports to be used with WebDAV-Push.

WebDAV-Push currently recommends to implement at least Web Push (see Appendix A).

For proprietary push services (like Google FCM), client vendors may need to provide
a _rewrite proxy_ that signs and forwards the requests to the respective
proprietary service.

Push transport definitions can define extra properties and additional processing rules. For instance, a transport definition could define that WebDAV servers should send an additional *topic* header with their push notifications so that previous undelivered push messages are replaced by new ones.



# Protocol definitions

![Flowchart: WebDAV-Push over UnifiedPush](images/unifiedpush-flowchart.png)

Here we define how the communication between the components is done.

## Service detection: WebDAV

How clients can detect

- whether a collection supports WebDAV-Push,
- which push services are supported (may contain service-specific information)

> **TODO:** specify WebDAV properties

Example:
```
PROPFIND https://example.com/webdav/collection/
[…]
<propfind xmlns="DAV:" xmlns:P="DAV:Push">
  <prop>
    <P:push-transports/>
  </prop>
</propfind>

HTTP/1.1 207 Multi-Status
[…]
<multistatus xmlns="DAV:" xmlns:P="DAV:Push">
  <response>
    <href>/webdav/collection/</href>
    <prop>
      <P:push-transports>
        <P:web-push />
        <P:some-other-transport>
          <P:some-relevant-info>...<P:some-relevant-info>
        </P:some-other-transport>
      <P:push-transports>
    </prop>
  </response>
</multistatus>
```
In this case, the requested collection supports two push transports:

1. Web Push (RFC 8030)
2. Some other transport, with some additional relevant information that is required to use it. This is to illustrate that it WebDAV-Push aims to support other or even yet unknown push transports, too.

## Subscription management

### Register subscription

How to subscribe to collections on the WebDAV server.

Required information:

- Collection to be subscribed
- Push transport, including transport-specific details
  - Web Push: push resource URL
  - details for message encryption
- Expiration? how long by default, min/max (24 h), server decides (and can impose limits)
- End-to-end-encryption? Or should it be defined per transport?

By now, only updates in direct members (equals `Depth: 1`) are sent. Maybe it could be specified that servers can send one notification per path segment? Implications?

To subscribe to a collection, the client sends a POST request to the collection it wants to subscribe with `Content-Type: application/xml`. The root XML element of the XML body is `<push-register>` in the WebDAV-Push name space (`DAV:Push`) and can be used to distinguish between a WebDAV-Push and other requests.

> **Element definitions:**
> 
>Name: `push-register`
>Namespace: `DAV:Push`
>Purpose: Indicates that a subscription shall be registered to receive notifications when the collection is updated.
>Description:
>
>This element specifies details about a subscription that shall be notified when the collection is updated. Besides the optional expiration, there must be exactly one child element that defines the subscription details. In this document, only `web-push-subscription` is defined.
>
>Definition: `<!ELEMENT push-register (expires?, (web-push-subscription | %other-subscription))`
>Example: see below
>
>Name: `expires`
>Namespace: `DAV:Push`
>Purpose: Specifies an expiration date of the registered subscription.
>Description: Specifies an expiration date-time in the `IMF-fixdate` format (RFC 9110).
>
>Definition: `<!ELEMENT expires (#PCDATA)`
>Example: `<expires>Sun, 06 Nov 1994 08:49:37 GMT</expires>`

Allowed response codes:

* 201 with a `<subscription>` element if the subscription was created and the server has to return it to the client with additional information (like encryption details that are only valid for this subscription)
* 204 if the subscription was created and there's nothing else to say
* other error code, ideally with `DAV:error` XML body

Sample request for Web Push without Message Encryption:
```
POST https://example.com/webdav/collection/
Content-Type: application/xml; charset="utf-8"

<?xml version="1.0" encoding="utf-8" ?>
<push-subscribe xmlns="DAV:Push">
  <web-push-subscription>
    <endpoint>https://up.example.net/yohd4yai5Phiz1wi</endpoint>
  </web-push-subscription>
  <expires>Wed, 20 Dec 2023 10:03:31 GMT</expires>
</push-subscribe>

HTTP/1.1 204 No Content
Location: https://example.com/webdav/subscriptions/io6Efei4ooph
```

Sample request for Web Push with Message Encryption:
```
POST https://example.com/webdav/collection/
Content-Type: application/xml; charset="utf-8"

<?xml version="1.0" encoding="utf-8" ?>
<push-subscribe xmlns="DAV:Push">
  <subscription>
    <transport>
      <web-push>
        <push-resource>https://push.example.net/push/JzLQ3raZJfFBR0aqvOMsLrt54w4rJUsV</push-resource>
        <public-key keyid="p256dh" dh="BL0IG_CKsOMezWrQPFQQDC39nRk88ROhz4Ytr9T-NZ7sbuHcjV0cVjoLtE7hR8c5USnRQ3LeKwuRxLvMVozJUt8" />
        <authentication-secret>c9_nEWEAI8JUnB_uh5uEbQ</authentication-secret>
      </web-push>
    </transport>
    <expires>Wed, 20 Dec 2023 10:03:31 GMT</expires>
  </subscription>
</push-subscribe>

HTTP/1.1 204 No Content
Location: https://example.com/webdav/subscriptions/io6Efei4ooph
```

### Subscription removal

> **TODO:** ~~Works like creating a subscription, but with `action=remove-subscription`.~~ Probably better with an own URL per subscription so that clients can DELETE.

The server identifies the subscription by its details (for instance, the endpoint) and then removes it. If it can't find a matching subscription, it returns 404.

#### Expiration

Clients can specify an expiration date-time when they register a subscription.

A server should take the expiration specified by a client into consideration, but may impose its own (often stricter) expiration rules, for instance to keep their database clean or because the client has specified an implausible late expiration.

Clients should refresh their registrations regularly because they can't rely on servers to keep their subscriptions until the client-specified expiration date.

Expired subscriptions should be cleaned up and not be used anymore as chances are high that notifying such subscriptions will cause errors.

## Push messages

Actual push message format. As little data as possible, i.e. **only the changed topic**. Can we use a canonical collection URL when the payload is encrypted or do we need a topic ID, for instance if there's no reasonable way to canonicalize the collection URL? Otherwise the server could send another form of the URL in the push message and a user-agent wouldn't know which collection is meant.

Push notification rate limit?

XML (like in WebDAV), JSON (like in Web Push, seems to be more usual nowadays in push environments), other format?

Shall end-to-end encryption (for instance as described by RFC 8291) be possible / recommended / required?

Shall a TTL value, as used by Web Push, be recommended in general, per transport, or not at all?

Shall multiple enqueued (and not yet delivered) push messages for the same collection be merged to a single one (like _Replacing push messages_ with the `Topic` header in RFC 8030)? Maybe use a timestamp? Shall this be specified in general, per transport or not at all?


# Security considerations

Which information is shared with which party, especially public ones like the Google FCM + implications? Involved parties:

* WebDAV server
* client
* push transports

Without E2EE, push transports can collect metadata:

* which WebDAV server notifies which clients,
* which clients are subscribed to the same collection (because they receive the same topic in the push message),
* at which times the collection is changed,
* other metadata (IP addresses etc.)

With E2EE, every push message is different and push transports can only relate clients over heuristics, like the clients that are notified at the same time have probably subscribed the same collection.

How sensitive are the data, how to minimize risks

What happens when information leaks

What happens when some component is hacked


# Appendix A: Web Push Transport

WebDAV-Push can be used with Web Push (RFC 8030) to deliver WebDAV-Push notifications directly to compliant user agents, like Web browsers which come with their own push service infrastructure. Currently (2024), all major browsers support Web Push.

Usage of Message Encryption (RFC 8291) and VAPID (RFC 8292) is currently recommended. If future protocol extensions become used by push services, WebDAV-Push servers should implement them as well, if applicable.

> **RESEARCH:** Are subscription-sets of use for us?

> **NOTE**: [UnifiedPush](https://unifiedpush.org/) (UP) is a set of specification documents which are intentionally designed as a 100% compatible subset of Web Push, together with a software that can be used to implement these documents. From a WebDAV-Push server perspective, UP endpoints may used as Web Push resources.

## Transport description

The XML element to specify the transport is `<web-push>`, with these direct sub-elements:

### Push Resource
Name: `push-resource`
Description: push resource URL as defined in RFC 8030
Example:
```
<push-resource>https://push.example.net/push/JzLQ3raZJfFBR0aqvOMsLrt54w4rJUsV</push-resource>
```

### Message Encryption

>**TODO:** message encryption as defined in RFC 8291