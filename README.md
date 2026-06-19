# buildkit

libops docker base images

## Testing

Build an image into the local Docker engine, then run its retained compose tests:

```sh
make bake TARGET=base
make test IMAGE=base
```

You can also run a single test:

```sh
make test IMAGE=base TEST=ServiceStartsWithDefaults
```

The test runner prints compose status, exit codes, and service logs directly in
the run output when a test fails. The same Go implementation backs
`ci/image-metadata.sh`, so CI and local commands use one source for image tags,
contexts, and affected-image planning.

## Attribution

Forked from https://github.com/Islandora-Devops/isle-buildkit
