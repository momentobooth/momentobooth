#!/bin/sh
# Sets up the queue for the CUPS integration tests (rust/src/tests/cups.rs) in a ydkn/cups container.
#
# The queue uses the driver of a DNP DS620 dye-sublimation photo printer (Gutenprint), so it has the paper sizes of a real photo printer. It is
# paused, so jobs stay in the queue and never reach the device, which does not exist.
set -e

# Wait until cupsd accepts requests.
for _ in $(seq 1 30); do
  lpstat -r 2>/dev/null | grep -q 'is running' && break
  sleep 1
done

lpadmin -p MomentoBoothTest -E -v socket://127.0.0.1:9 -m gutenprint.5.3://dnp-ds620/expert -D "MomentoBooth test printer"
cupsdisable MomentoBoothTest
lpstat -p MomentoBoothTest
