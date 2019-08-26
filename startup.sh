#!/usr/bin/env bash
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf &
/root/entrypoint.sh
