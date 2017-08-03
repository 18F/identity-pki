# service_discovery

A cookbook whose purpose is to abstract service discovery.

Currently there is one main recipe, register, which handles all tasks necessary
to register the given instance.  This can be included in the run list to
register this instance.

There are custom resources that can be used, and a library that can also be
called directly.  See the `resources` and `libraries` directories to find the
latest.
