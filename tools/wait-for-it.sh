#!/bin/sh
#   Use this script to test if a given TCP host/port are available

cmdname=$(basename $0)

echoerr() { if [ $QUIET -ne 1 ]; then echo "$@" 1>&2; fi }

usage()
{
    cat << USAGE >&2
Usage:
    $cmdname host:port [-s] [-t timeout] [-- command args]
    -h HOST                     Host or IP under test
    -p PORT                     TCP port under test
    -s                          Only execute subcommand if the test succeeds
    -q                          Do not output any status messages
    -t TIMEOUT                  Timeout in seconds, zero for no timeout
    -- COMMAND ARGS             Execute command with args after the test finishes
USAGE
    exit 1
}

wait_for()
{
    if [ $TIMEOUT -gt 0 ]; then
        echoerr "$cmdname: waiting $TIMEOUT seconds for $HOST:$PORT"
    else
        echoerr "$cmdname: waiting for $HOST:$PORT without a timeout"
    fi
    start_ts=$(date +%s)
    while :
    do
        if [ $ISBUSY -eq 1 ]; then
            nc -z $HOST $PORT
            result=$?
        else
            (echo > /dev/tcp/$HOST/$PORT) >/dev/null 2>&1
            result=$?
        fi
        if [ $result -eq 0 ]; then
            end_ts=$(date +%s)
            echoerr "$cmdname: $HOST:$PORT is available after $((end_ts - start_ts)) seconds"
            break
        fi
        sleep 1
    done
    return $result
}

wait_for_wrapper()
{
    # In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
    if [ $QUIET -eq 1 ]; then
        timeout $BUSYTIMEFLAG $TIMEOUT $0 -q -c -h $HOST -p $PORT -t $TIMEOUT &
    else
        timeout $BUSYTIMEFLAG $TIMEOUT $0 -c -h $HOST -p $PORT -t $TIMEOUT &
    fi
    PID=$!
    trap "kill -INT -$PID" INT
    wait $PID
    RESULT=$?
    if [[ $RESULT -ne 0 ]]; then
        echoerr "$cmdname: timeout occurred after waiting $TIMEOUT seconds for $HOST:$PORT"
    fi
    return $RESULT
}

while getopts csqt:h:p: OPT; do
    case "$OPT" in
        c)
            CHILD=1
            ;;
        s)
            STRICT=1
            ;;
        q)
            QUIET=1
            ;;
        t)
            TIMEOUT=$OPTARG
            ;;
        h)
            HOST=$OPTARG
            ;;
        p)
            PORT=$OPTARG
            ;;
    esac
done

shift `expr $OPTIND - 1`

CLI="$@"
TIMEOUT=${TIMEOUT:-15}
STRICT=${STRICT:-0}
CHILD=${CHILD:-0}
QUIET=${QUIET:-0}

if [ "$HOST" = "" ] || [ "$PORT" = "" ]; then
    echoerr "Error: you need to provide a host and port to test."
    usage
fi

# check to see if timeout is from busybox
TIMEOUT_PATH=$(realpath $(which timeout))
BUSYBOX="busybox"
if test "${TIMEOUT_PATH#*$BUSYBOX}" != "$BUSYBOX"; then
    ISBUSY=1
    BUSYTIMEFLAG="-t"
else
    ISBUSY=0
    BUSYTIMEFLAG=""
fi

if [ $CHILD -gt 0 ]; then
    wait_for
    RESULT=$?
    exit $RESULT
else
    if [ $TIMEOUT -gt 0 ]; then
        wait_for_wrapper
        RESULT=$?
    else
        wait_for
        RESULT=$?
    fi
fi

if [ ! -z "$CLI" ]; then
    if [ $RESULT -ne 0 ] && [ $STRICT -eq 1 ]; then
        echoerr "$cmdname: strict mode, refusing to execute subprocess"
        exit $RESULT
    fi
    exec $CLI
else
    exit $RESULT
fi
