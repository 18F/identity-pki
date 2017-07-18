# config_loader

A cookbook whose only purpose is to provide an abstraction for loading
configuration.  This was necessary because I haven't figured out encrypted data
bags in integration tests, but it will also be useful for changing the way we
access configuration.

See
http://atomic-penguin.github.io/blog/2013/06/07/HOWTO-test-kitchen-and-encrypted-data-bags/.
