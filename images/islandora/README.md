# Drupal

Docker image for [Drupal].

Built from [libops/isle-buildkit islandora](https://github.com/libops/buildkit/tree/main/images/islandora)

Acts as base Docker image for Drupal based projects, it doesn't install Drupal
as consumers of this image are expected to provide their own composer file.
Instead it provides startup scripts that allow Drupal to be installed when the
image is first run.

## Dependencies

Requires `libops/nginx` Docker image to build. Please refer to the
[Nginx Image README](../nginx/README.md) for additional information including
additional settings, volumes, ports, etc.

## Ports

| Port | Description |
| :--- | :---------- |
| 80   | HTTP        |

## Settings

### Network Settings

| Environment Variable     | Default | Description                                                                        |
| :----------------------- | :------ | :--------------------------------------------------------------------------------- |
| DRUPAL_ENABLE_HTTPS      | true    | Inform PHP that `https` should be used.                                            |
| DRUPAL_REVERSE_PROXY_IPS |         | Use the IP address for the host 'traefik' if found otherwise default to `0.0.0.0`. |

### Database Settings

[Drupal] can make use of different database backends for storage. Please see the
documentation in the [base image] for more information about the default
database connection configuration.

Use the base image `DB_*` settings for the single Islandora site database.

### JWT Settings

[Drupal] is expected to make use of JWT for authentication. Please see the
documentation in the [base image] for more information.

The public/private key pair used here should be the same key as is used in the
derivative service and `fcrepo` based containers.

### Site

| Environment Variable            | Default                 | Description                                        |
| :------------------------------ | :---------------------- | :------------------------------------------------- |
| DRUPAL_DEFAULT_ACCOUNT_EMAIL    | webmaster@localhost.com | The email to use for the admin account             |
| DRUPAL_DEFAULT_ACCOUNT_NAME     | admin                   | The Drupal administrator user                      |
| DRUPAL_DEFAULT_ACCOUNT_PASSWORD | password                | The Drupal administrator user password             |
| DRUPAL_DEFAULT_DB_NAME          | drupal_default          | The name of the sites database                     |
| DRUPAL_DEFAULT_DB_PASSWORD      | password                | The database users password                        |
| DRUPAL_DEFAULT_DB_USER          | drupal_default          | The database user used by the site                 |
| DRUPAL_DEFAULT_EMAIL            | webmaster@localhost.com | The Drupal administrators email                    |
| DRUPAL_DEFAULT_LOCALE           | en                      | The Drupal sites locale                            |
| DRUPAL_DEFAULT_NAME             | default                 | The Drupal sites name                              |
| DRUPAL_DEFAULT_PROFILE          | standard                | The installation profile to use                    |
| DRUPAL_DEFAULT_SUBDIR           | default                 | The installation profile to use                    |
| DRUPAL_DEFAULT_CONFIGDIR        |                         | Install using existing config files from directory |
| DRUPAL_DEFAULT_INSTALL          | true                    | Perform install if not already installed           |

Of the above you should provide at a minium your own passwords when running in
production.

[base image]: ../base/README.md
[Drupal]: https://www.drupal.org/
