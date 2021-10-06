#!/bin/bash

podman build -t nextcry-php .

podman run --rm -d --name nc-php nextcry-php sleep 10

podman cp nc-php:/nextcry-php.deb nextcry-php.deb
