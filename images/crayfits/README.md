# Crayfits

Docker image for [CrayFits]. [FITS][1] as a microservice.


Built from [libops/isle-buildkit crayfits](https://github.com/libops/buildkit/tree/main/images/crayfits)

## Dependencies

Requires `libops/scyllaridae` Docker image to build. Please refer to the
[Scyllaridae Image README](../scyllaridae/README.md) for additional information including
additional settings, volumes, ports, etc.

## Settings

| Environment Variable    | Default                       | Description                                                                                       |
| :---------------------- | :---------------------------- | :------------------------------------------------------------------------------------------------ |
| CRAYFITS_WEBSERVICE_URI | http://fits:8080/fits/examine | The URL of the FITS servlet.                                                                      |

[1]: https://harvard-lts.github.io/fits/
