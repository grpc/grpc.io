#!/bin/bash

set -e

command -v hugo >/dev/null || (echo "Hugo extended must be installed on your system." >/dev/stderr; exit 1)
hugo version | grep -i extended >/dev/null || (echo "Your Hugo installation does not appear to be extended." >/dev/stderr; exit 1)
