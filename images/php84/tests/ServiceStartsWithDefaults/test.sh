#!/usr/bin/env bash
set -e

s6-svwait -U /run/service/fpm
test -S /run/php-fpm84/php-fpm84.sock
