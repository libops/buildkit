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
  - ArchivesSpace, OJS, Omeka S, and Omeka Classic include checksum-verified upstream application releases.
  - Drupal and Wordpress remain infrastructure scaffolding for Composer-managed application code in downstream builds.
- Tags are based on software versions
- Multiple versions of the same software/image can coexist (e.g. java, solr, fcrepo, php, etc.)
- `base`  environment variables (e.g. `DB_NAME`) are overriden instead of `IMAGE_NAME_*` env vars
- Removed Islandora multisite support
- Added optional Vault-backed secret bootstrap

## OJS dataset initialization

Fresh OJS installations defer the install-time ROR registry and IP geolocation
downloads so that container initialization is bounded and does not require
outbound network access. OJS's built-in scheduler remains enabled and updates
the ROR registry monthly on the first day of the month and the IP database
monthly on the tenth.

To populate either dataset immediately after installation, run the corresponding
OJS scheduler task from `/var/www/ojs` as the application user:

```sh
php lib/pkp/tools/scheduler.php test --name='PKP\task\UpdateRorRegistryDataset'
php lib/pkp/tools/scheduler.php test --name='PKP\task\UpdateIPGeoDB'
```
