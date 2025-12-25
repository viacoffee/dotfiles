#!/bin/bash

# Sets service, signal, and pidname based on a 'shortname'
set_service_vars() {
    case "$1" in
        postgres)
            service="postgresql.service"
            signal="-RTMIN+20"
            pidname=$name
            ;;
        *)
            return 1
            ;;
    esac
}
