#!/usr/bin/env bash

### tip via https://sites.google.com/a/yarina.org/dougs-notes/home/mac-os-x/multiple-instances-of-chrome
### yay http://dev.chromium.org/user-experience/user-data-directory
### also https://developer.apple.com/library/mac/#documentation/opensource/conceptual/shellscripting/
### launch a separate instance of Google Chrome without web security
(
	/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --disable-web-security --user-data-dir=/tmp/junk > /dev/null 2>&1 &
	ChromeProcessId=$!
	wait $ChromeProcessId
	rm -r /tmp/junk
) &
