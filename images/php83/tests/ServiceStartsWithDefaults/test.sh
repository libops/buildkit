#!/usr/bin/env bash
set -e

s6-svwait -U /run/service/fpm
test -S /run/php-fpm83/php-fpm83.sock
