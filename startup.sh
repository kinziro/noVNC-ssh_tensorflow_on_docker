#!/usr/bin/env bash
supervisord -c /etc/supervisor/supervisord.conf &
/root/entrypoint.sh
