# Firefox with a source patch that stops advertising automation to web content
# (navigator.webdriver), while leaving the Marionette and Remote Agent servers
# fully operational. Gated behind the `dom.webdriver.hide_from_content` pref
# (default false), so set it to true in about:config / a user.js to activate.
{ pkgs, ... }:

let
  firefox-unwrapped = pkgs.firefox-unwrapped.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [ ./navigator-hide-webdriver.patch ];
  });
in
pkgs.wrapFirefox firefox-unwrapped { }
