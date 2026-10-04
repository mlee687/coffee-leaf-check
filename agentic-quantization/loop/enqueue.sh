#!/usr/bin/env bash
# usage: enqueue.sh TAG TEMPLATE NSEQ [EXTRA]  — append one build job for the workers (TAG names the output file)
HERE=$(cd "$(dirname "$0")" && pwd); source "$HERE/env.sh"
[ -f "$2" ] || { echo "template not found: $2" >&2; exit 1; }
( flock 9; echo "$1|$2|$3|${4:-}" >> $WORK/queue.txt ) 9>$WORK/.queue.lock
echo "QUEUED $1 template=$(basename $2) $(date -Is)" >> $WORK/logs/events.log
