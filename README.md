[![Matrix](https://img.shields.io/matrix/webdav-push:matrix.org)](https://matrix.to/#/#webdav-push:matrix.org)
[![GitHub Discussions](https://img.shields.io/github/discussions/bitfireAT/webdav-push)](https://img.shields.io/github/discussions/bitfireAT/webdav-push)


# The WebDAV Push project

**[View the current draft document](webdav-push-draft.md)**


## Motivation

WebDAV is an open HTTP- and XML- based protocol that is widely adopted and can be used for remote file access (read/write). It has a wide range of usages from browsing folders and uploading files over the Internet with a desktop or mobile file manager (like FTP, but better) to specific protocols that define their own properties and use (virtual) files for data exchange.

Two of these specific WebDAV-based protocols are CalDAV and CardDAV. They allow to access calendars (events, tasks, journal entries, free/busy information, …) and contacts in a standardized way. Because they're open standards, a lot of different servers and clients can be used to work together (no vendor lock-in).

However, these protocols don't come with support for "Push", so there's no way for servers to notify clients about new/updated data. So,

- a file manager won't update its view of a folder automatically when a file in this folder is added/changed/removed, and
- a CalDAV/CardDAV client has to ask the server for changes in regular intervals (polling), which causes unnecessary server load, bad user experience and useless energy usage (especially bad for mobile devices).

WebDAV is however extensible and it's possible to add new properties and mechanisms to it. So we want to create WebDAV-Push, so that users can receive updated data whenever they're available.

**This is especially important for CalDAV/CardDAV, where we want to bring (near-)real-time synchronization** (which is nowadays industry standard for proprietary protocols) also to CalDAV/CardDAV clients.


## How

Our goal is to draft a document defining WebDAV Push.

It will be mainly based on Web Push (RFC 8030), but open for other push transports.

Currently, the main organizations / people behind WebDAV Push are:

- [@bitfireAT](https://github.com/bitfireAT) (developers of [DAVx⁵](https://github.com/bitfireAT/davx5-ose)) – very interested in developing Push for WebDAV, especially CalDAV/CardDAV
- [@verdigado](https://github.com/verdigado) – interested in using CalDAV/CardDAV push

The plan is to

- [draft a standard document](webdav-push-draft.md),
- make a [first server-side implementation](https://github.com/bitfireAT/nc_ext_dav_push) for [@Nextcloud](https://github.com/nextcloud) (who are interested in supporting that) – it's in development and can already be used for demonstration purposes,
- make a first client-side implementation for DAVx⁵ – basic support for demonstration purposes is also already available in the lastest releases,
- ensure that it's usable with [@UnifiedPush](https://github.com/UnifiedPush) (because there's already much awesome open technology available).

A lot of people have shown their interest in WebDAV-Push. Thank you for all ideas and encouragement!


## Contact

If you're interested:

- have a look at the [document draft](webdav-push-draft.md) and tell us your ideas
- take part in our [Discussions](https://github.com/bitfireAT/webdav-push/discussions) – feel free to create new topics with your ideas, questions, what you would love to see, …
- join our Matrix channel: [#webdav-push:matrix.org](https://matrix.to/#/#webdav-push:matrix.org) – not always very active, but well observed
- watch [@davx5@fosstodon.org](https://fosstodon.org/@davx5app), where we sometimes post Push-related news too

We would love to see some activity!


## Repo organization

The repository contains:

- **a [draft document describing our current idea of WebDAV-Push](webdav-push-draft.md)**
- discussion and exchange about the WebDAV Push topic (in [Discussions](https://github.com/bitfireAT/webdav-push/discussions))
- specific tasks (in [Issues](https://github.com/bitfireAT/webdav-push/issues)) and related patches (in [Pull requests](https://github.com/bitfireAT/webdav-push/pulls))
