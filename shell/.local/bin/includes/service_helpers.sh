#!/bin/bash

# Sets service, signal, and pidname based on a 'shortname'
set_service_vars() {
    case "$1" in
        postgres)
            service="postgresql.service"
            signal="20"
            pidname=$name
            ;;
        *)
            return 1
            ;;
    esac
}

service_action() {
    local action="$1"
    local name="$2"

    if [[ -z "$action" || -z "$name" ]]; then
        notify-send "Usage: service_action <start|stop|restart|toggle> <service>"
        return 1
    fi

    if ! set_service_vars "$name"; then
        notify-send "unknown service $name"
        return 1
    fi

    is_running() {
        pgrep -x "$pidname" >/dev/null
    }

    do_start() {
        if is_running; then
            notify "$name is already running"
            return 0
        fi
    
        if ! systemctl start "$service"; then
            notify_err "$name ($service) failed to start"
            return 1
        fi
    
        notify "$name has been started"
        signal_waybar "$signal"
    }
    
    do_stop() {
        if ! is_running; then
            notify "$name is not running"
            return 0
        fi
    
        if ! systemctl stop "$service"; then
            notify_err "$name ($service) failed to stop"
            return 1
        fi
    
        notify "$name has been stopped"
        signal_waybar "$signal"
    }
    
    case "$action" in
        start)  do_start ;;
        stop)   do_stop ;;
        restart)
            if is_running; then
                do_stop
            fi
            do_start
            ;;
        toggle)
            if is_running; then
                do_stop
            else
                do_start
            fi
            ;;
        *)
            notify "Invalid action: $action"
            return 1
            ;;
    esac
}
