# service_discovery

A cookbook whose purpose is to abstract service discovery.

Currently there are two main recipes, register and discover, and they do what
you would expect (handle all tasks necessary to register the given instance, and
discover information about instances that have been registered).

See the recipes themselves for usage.  You will likely want to replicate what's
in those recipes and use the libraries directly in many cases, but sometimes
they may already do what you need.
