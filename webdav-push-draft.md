WebDAV Push

Draft Document (In Work)


# Introduction

This document, below referred to as _WebDAV-Push_, provides a way for compliant
WebDAV servers to send notifications about updated collections to subscribed clients
over existing push transports.

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

WebDAV-Push isn't restricted to specific push services and allows clients to specify which push services they support. This allows upcoming push services to be used with WebDAV-Push.

However, WebDAV-Push currently suggests to implement at least

- UnifiedPush (see Appendix A) and
- Web Push (see Appendix B).

UnifiedPush is an open set of specifications and allows push notifications to be delivered
over various transports.

For proprietary push services (like Google FCM), client vendors may need to provide
a _rewrite proxy_ that signs and forwards the UnifiedPush requests to the respective
proprietary service.

A Web Push transport could support all major browsers and provide [Message Encryption](https://www.rfc-editor.org/rfc/rfc8291.html) and [VAPID](https://www.rfc-editor.org/rfc/rfc8292).

Push transport definitions can define extra properties and additional processing rules. For instance, a transport definition could define that WebDAV servers should send an additional *topic* header so that previous undelivered push messages are replaced by new ones.



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
        <P:unifiedpush version="1"/>
        <P:web-push />
        <P:some-other-transport>
          <P:some-relevant-info>...<P:some-relevant-info>
        </P:some-other-transport>
      <P:push-transports>
    </prop>
  </response>
</multistatus>
```
In this case, the requested collection supports three push transports:

1. UnifiedPush (version 1)
2. Web Push (RFC 8030)
3. Some other transport, with some additional relevant information that is required to use it. This is to illustrate that it WebDAV-Push aims to support other or even yet unknown push transports, too.

## Subscription management

### Create subscription

How to subscribe to collections on the WebDAV server.

Required information:

- Collection to be subscribed
- Push transport, including transport-specific details
  - UnifiedPush: endpoint URL
  - Web Push: push resource URL
  - details for message encryption
- Expiration? how long by default, min/max (24 h), server decides (and can impose limits)
- End-to-end-encryption? Or should it be defined per transport?

~~Depth header: not specified now because of complexity.~~ By now, only updates in direct members (equals `Depth: 1`) are sent. Maybe it could be specified that servers can send one notification per path segment? Implications?

1. POST to the collection like for [sharing resources](https://datatracker.ietf.org/doc/html/draft-pot-webdav-resource-sharing-04#section-4.3)
2. Alternatively: URL + action query parameter like in [Managed Attachments](https://www.rfc-editor.org/rfc/rfc8607.html#section-3.3)
3. Alternatively: POST to a dedicated URL (that we know from PROPFIND)

Do we need to provide a possibility for the client to list its subscriptions or request their details? Probably yes. Could be relevant if the server generates some info (salt) per subscription and the client needs to get hold of it. In this case, define collection so that every subscription has its own URL and can for instance be deleted with this URL.

Allowed response codes:

* 201 with a `<subscription>` element if the subscription was created and the server has to return it to the client with additional information (like encryption details that are only valid for this subscription)
* 204 if the subscription was created and there's nothing else to say
* other error code, ideally with `DAV:error` XML body

Sample request for UnifiedPush:
```
POST https://example.com/webdav/collection/
Content-Type: application/xml; charset="utf-8"

<?xml version="1.0" encoding="utf-8" ?>
<push-subscribe xmlns="DAV:Push">
  <transport>
    <unified-push>
      <endpoint>https://up.example.net/yohd4yai5Phiz1wi</endpoint>
    </unified-push>
  </transport>
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
  <transport>
    <web-push>
      <push-resource>https://push.example.net/push/JzLQ3raZJfFBR0aqvOMsLrt54w4rJUsV</push-resource>
      <public-key keyid="p256dh" dh="BL0IG_CKsOMezWrQPFQQDC39nRk88ROhz4Ytr9T-NZ7sbuHcjV0cVjoLtE7hR8c5USnRQ3LeKwuRxLvMVozJUt8" />
      <authentication-secret>c9_nEWEAI8JUnB_uh5uEbQ</authentication-secret>
    </web-push>
  </transport>
  <expires>Wed, 20 Dec 2023 10:03:31 GMT</expires>
</push-subscribe>

HTTP/1.1 204 No Content
Location: https://example.com/webdav/subscriptions/io6Efei4ooph
```

### Remove subscription

> **TODO:** ~~Works like creating a subscription, but with `action=remove-subscription`.~~ Probably better with an own URL per subscription so that clients can DELETE.

The server identifies the subscription by its details (for instance, the endpoint) and then removes it. If it can't find a matching subscription, it returns 404.


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


# Appendix A: UnifiedPush Transport

WebDAV-Push can be used with [UnifiedPush](https://unifiedpush.org/).

## Transport description

The XML element to specify the transport is `<unifiedpush>`, with these direct sub-elements:

### Endpoint
Property name: `url`
Description: UnifiedPush endpoint URL
Example: `<url>https://up.example.net/yohd4yai5Phiz1wi</url>`

### Message Encryption

> **TODO:** message encryption, if we even need it

# Appendix B: Web Push Transport

WebDAV-Push can be used with Web Push (RFC 8030) to deliver WebDAV-Push notifications directly to compliant user agents, typically Web browsers which come with operate their own RFC 8030 push services.

Usage of Message Encryption (RFC 8291) and VAPID (RFC 8292) is recommended.

> **RESEARCH:** Are subscription-sets of use for us?

## Transport description

The XML element to specify the transport is `<web-push>`, with these direct sub-elements:

### Push Resource
Name: `push-resource`
Description: push resource URL as defined in RFC 8030
Example: `<push-resource>https://push.example.net/push/JzLQ3raZJfFBR0aqvOMsLrt54w4rJUsV</push-resource>`

### Message Encryption

>**TODO:** message encryption as defined in RFC 8291