# Fcrepo 7

Docker image for [fcrepo] version 7.0.0.

Built from [libops/isle-buildkit fcrepo7](https://github.com/libops/buildkit/tree/main/images/fcrepo7)

Please refer to the [Fcrepo Documentation] for more in-depth information.

As a quick example this will bring up an instance of [fcrepo], and allow you
to view on <http://localhost:80/fcrepo/>.

```bash
docker run --rm -ti -p 80:80 libops/fcrepo
```

## Dependencies

Requires `libops/tomcat` Docker image to build. Please refer to the
[Tomcat Image README](../tomcat/README.md) for additional information including
additional settings, volumes, ports, etc.

## Volumes

| Path  | Description     |
| :---- | :-------------- |
| /data | OCFL Filesystem |

> N.B. Volumes are not created automatically. It is up to the user to either bind
> mount or attach a volume at the paths specified above.

## Settings

### Confd Settings

| Environment Variable         | Default              | Description                                                                                                 |
| :--------------------------- | :------------------- | :---------------------------------------------------------------------------------------------------------- |
| FCREPO_ACTIVEMQ_BROKER       | tcp://activemq:61616 | The location of the ActiveMQ Broker in which to publish JMS messages to                                     |
| FCREPO_ACTIVEMQ_QUEUE        | fedora               | The ActiveMQ Queue in which to publish JMS messages                                                         |
| FCREPO_ACTIVEMQ_QUEUE_ENABLE | false                | If `true` publish JMS messages on the queue `FCREPO_ACTIVEMQ_QUEUE`                                         |
| FCREPO_ACTIVEMQ_TOPIC        | fedora               | The ActiveMQ Topic in which to publish JMS messages                                                         |
| FCREPO_ACTIVEMQ_TOPIC_ENABLE | true                 | If `true` publish JMS messages on the topic `FCREPO_ACTIVEMQ_TOPIC`                                         |
| FCREPO_DISABLE_SYN           | false                | Enable or disable authentication via [Syn](https://github.com/Islandora/Syn)                                |
| FCREPO_SESSION_TIMEOUT       | 180000               | This sets the duration (in milliseconds) for which a transaction will stay active before auto-rolling back  |

To allow [external content] provide sites as key pairs. Wherein multiple values
is the url and the 'name' is a key that replaces the '*' symbol below.

| Environment Variable    |
| :---------------------- |
| FCREPO_ALLOW_EXTERNAL_* |

### JWT Settings

[fcrepo] makes use of JWT for authentication. Please see the documentation in
the [base image] for more information.

### Database Settings

[fcrepo] uses MariaDB for object storage. Please see the documentation in the
[base image] for the `DB_*` database connection settings.

### Tomcat Settings

Fcrepo is deployed in as a servlet in Tomcat. Please see the documentation in
the [tomcat image] for more information.


## Updating

You can change the version used for [fcrepo] by modifying the build argument
`SOFTWARE_VERSION` and `FCREPO_SHA256` in the `Dockerfile`.

Change `SOFTWARE_VERSION` and then generate the `FCREPO_SHA256` with the following
commands:

```bash
./ci/update-sha.sh fcrepo7 OLD_VERSION NEW_VERSION ''
```

You can change the version used for [syn] by modifying the build arguments
`SYN_VERSION` and `SYN_REF` in the `Dockerfile`.

By default, the image downloads the checksum-pinned `v${SYN_VERSION}` release
artifact. Change `SYN_VERSION` and then generate `SYN_SHA256` with:

```bash
./ci/update-sha.sh islandora-syn-fcrepo7 OLD_VERSION NEW_VERSION ''
```

To test an unreleased Syn branch, set `SYN_VERSION` and
`SYN_REF=refs/heads/${SYN_VERSION}`. The image then builds Syn with `./gradlew`
instead of downloading a release artifact.

You can change the version used for [fcrepo-import-export] by modifying the
build argument `IMPORT_EXPORT_VERSION` and `IMPORT_EXPORT_SHA256` in the
`Dockerfile`.

Change `IMPORT_EXPORT_VERSION` and then generate the `IMPORT_EXPORT_SHA256` with
the following commands:

```bash
./ci/update-sha.sh fcrepo-import-export OLD_VERSION NEW_VERSION ''
```

You can change the version used for [fcrepo-upgrade-utils] by modifying the
build argument `UPGRADE_UTILS_VERSION` and `UPGRADE_UTILS_SHA256` in the
`Dockerfile`.

Change `UPGRADE_UTILS_VERSION` and then generate the `UPGRADE_UTILS_SHA256` with
the following commands:

```bash
./ci/update-sha.sh fcrepo-upgrade-utils OLD_VERSION NEW_VERSION ''
```

[base image]: ../base/README.md
[external content]: https://wiki.lyrasis.org/display/FEDORA6x/External+Content
[Fcrepo Documentation]: https://wiki.lyrasis.org/display/FF
[fcrepo-import-export]: https://github.com/fcrepo-exts/fcrepo-import-export
[fcrepo-upgrade-utils]: https://github.com/fcrepo-exts/fcrepo-upgrade-utils
[fcrepo]: https://github.com/fcrepo/fcrepo
[syn]: https://github.com/Islandora-CLAW/Syn
[tomcat image]: ../tomcat/README.md
