#!/bin/bash

cd /home/bill/git/home.net

# Run your playbook (replace local.yml with your actual playbook)
ansible-playbook local.yml "$@"
PLAYBOOK_EXIT=$?

mkdir -p ansible_logs

DATE=$(date +%Y.%m.%d)
RUN_NUM=$(ls ansible_logs/${DATE}_run_* 2>/dev/null | wc -l)
RUN_NUM=$((RUN_NUM + 1))

grep -E 'FAILED!|ERROR!|UNREACHABLE!' ansible_run.log > ansible_logs/${DATE}_run_${RUN_NUM}_errors.txt

# Prune error logs older than 7 days
find ansible_logs/ -type f -name '*_errors.txt' -mtime +7 -delete

> ansible_run.log

exit $PLAYBOOK_EXIT