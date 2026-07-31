#!/bin/sh -x
set -e

# default to port 8080 if not specified
#
PORT="${PORT:-8080}"
WEBDYNE_SERVER="${WEBDYNE_SERVER:-psgi}"


# cpanfile exist ? If installdeps
#
if [ -f ./cpanfile ]; then
    cpanm --notest --installdeps .
fi

# hands off to the real command overridden
#
if [ $# -gt 0 ]; then
  exec "$@"
fi

case "$WEBDYNE_SERVER" in
  psgi)
    psgi_args=""
    [ -n "$WEBDYNE_SERVER_PSGI_WORKERS" ] && psgi_args="$psgi_args --workers $WEBDYNE_SERVER_PSGI_WORKERS"
    [ -n "$WEBDYNE_SERVER_PSGI_MAX_REQUESTS" ] && psgi_args="$psgi_args --max-requests $WEBDYNE_SERVER_PSGI_MAX_REQUESTS"
    [ -n "$WEBDYNE_SERVER_PSGI_BACKLOG" ] && psgi_args="$psgi_args --backlog $WEBDYNE_SERVER_PSGI_BACKLOG"
    [ -n "$WEBDYNE_SERVER_PSGI_KEEPALIVE_TIMEOUT" ] && psgi_args="$psgi_args --keepalive-timeout $WEBDYNE_SERVER_PSGI_KEEPALIVE_TIMEOUT"
    [ -n "$WEBDYNE_SERVER_PSGI_READ_TIMEOUT" ] && psgi_args="$psgi_args --read-timeout $WEBDYNE_SERVER_PSGI_READ_TIMEOUT"
    exec starman -MWebDyne --port "$PORT" $psgi_args $PERL_CARTON_PATH/bin/webdyne.psgi
    ;;
  pagi)
    pagi_args=""
    [ -n "$WEBDYNE_SERVER_PAGI_WORKERS" ] && pagi_args="$pagi_args --workers $WEBDYNE_SERVER_PAGI_WORKERS"
    [ -n "$WEBDYNE_SERVER_PAGI_MAX_REQUESTS" ] && pagi_args="$pagi_args --max-requests $WEBDYNE_SERVER_PAGI_MAX_REQUESTS"
    [ -n "$WEBDYNE_SERVER_PAGI_LISTENER_BACKLOG" ] && pagi_args="$pagi_args --listener-backlog $WEBDYNE_SERVER_PAGI_LISTENER_BACKLOG"
    [ -n "$WEBDYNE_SERVER_PAGI_TIMEOUT" ] && pagi_args="$pagi_args --timeout $WEBDYNE_SERVER_PAGI_TIMEOUT"
    [ -n "$WEBDYNE_SERVER_PAGI_REQUEST_TIMEOUT" ] && pagi_args="$pagi_args --request-timeout $WEBDYNE_SERVER_PAGI_REQUEST_TIMEOUT"
    [ -n "$WEBDYNE_SERVER_PAGI_MAX_CONNECTIONS" ] && pagi_args="$pagi_args --max-connections $WEBDYNE_SERVER_PAGI_MAX_CONNECTIONS"
    [ -n "$WEBDYNE_SERVER_PAGI_MAX_BODY_SIZE" ] && pagi_args="$pagi_args --max-body-size $WEBDYNE_SERVER_PAGI_MAX_BODY_SIZE"
    exec pagi-server -MWebDyne -E production --host 0.0.0.0 --port "$PORT" $pagi_args $PERL_CARTON_PATH/bin/webdyne.pagi
    ;;
  *)
    echo "ERROR: unsupported WEBDYNE_SERVER '$WEBDYNE_SERVER' - expected 'psgi' or 'pagi'" >&2
    exit 64
    ;;
esac
