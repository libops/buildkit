# buildkit

libops docker base images

## Testing

Build an image into the local Docker engine, then run its retained compose tests:

```sh
make bake TARGET=base
make test TARGET=base
```

You can also run a single test:

```sh
make test TARGET=base TEST=ServiceStartsWithDefaults
```

The test runner prints compose status, exit codes, and service logs directly in
the run output when a test fails. The same Go implementation backs
`ci/image-metadata.sh`, so CI and local commands use one source for image tags,
contexts, and affected-image planning.

## Attribution

Forked from https://github.com/Islandora-Devops/isle-buildkit.

Changes in this fork:

- Dropped Blazegraph, ImageMagick, Crayfish, Transkribus, Handle, Riprap, and Postgres images
- Dropped fcrepo file persistence
- Added ArchivesSpace, OJS, Omeka, and Wordpress images.
  - Moved Islandora buildkit's `drupal` image to `islandora` and made a drupal-only image
  - All of these images are intended to be infra scaffolding and app-specific codebase dropped into the container in local builds
- Tags are based on software versions
- Multiple versions of the same software/image can coexist (e.g. java, solr, fcrepo, php, etc.)
- `base`  environment variables (e.g. `DB_NAME`) are overriden instead of `IMAGE_NAME_*` env vars
- Removed Islandora multisite support
- Added optional Vault-backed secret bootstrap
