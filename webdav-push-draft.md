
WebDAV Push
Draft Document


# Introduction

- rationale
- similiar technologies / ideas
  * [JMAP Push](https://jmap.io/spec-core.html#push)
  * [Draft: Discovery of CalDAV Push-Notification Settings](https://github.com/apple/ccs-calendarserver/blob/master/doc/Extensions/caldav-pubsubdiscovery.txt)
  * [Draft: Push Discovery and Notification Dispatch Protocol](https://datatracker.ietf.org/doc/html/draft-gajda-dav-push-00)
- based on WebDAV
- extending WebDAV and especially CalDAV/CardDAV
- terminology


# Push Mechanism

## Service detection

How to detect whether the service supports WebDAV Push.


## Subscriptions

How to (un)subscribe to collections.

`Depth` header?


## Push delivery method

WebDAV Push should be usable with any push delivery method, including future ones.

Current ones to be considered:

- [Apple APN](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server)
- [Google FCM](https://firebase.google.com/docs/cloud-messaging)
- [Unified Push](https://unifiedpush.org/)
- [W3C Push](https://www.w3.org/TR/push-api/) – Nextcloud Server → W3C Push → Nextcloud Calendar app (in the browser)
- [WebSocket](https://www.rfc-editor.org/rfc/rfc6455.html) – allows for instance file managers to subscribe to a shown WebDAV folder;
  can also used by tools like [vdirsyncer](https://github.com/pimutils/vdirsyncer) to watch directories.

Reliability of different methods


## Push messages

Push message format


# WebDAV Properties

…


# Security considerations

…

