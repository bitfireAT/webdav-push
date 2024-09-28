#!/bin/sh
mkdir -p build
kramdown-rfc2629 webdav-push.mkd >build/webdav-push.xml && (cd build; xml2rfc --html webdav-push.xml && xml2rfc --text webdav-push.xml && xdg-open webdav-push.html)

