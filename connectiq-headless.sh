#!/bin/bash
xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" ${CIQ_HOME}/bin/connectiq "$@"
