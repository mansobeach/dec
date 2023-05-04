#!/bin/bash
set -e

[ "$DEBUG" == 'true' ] && set -x

echo "container entrypoint init DEC NAOS gsc4eo@nl2-s-aut-srv-01"
decListener -m SIM_DDC_ADA_TDA -i 60
sleep 10
decListener -m SIM_DDC_ADA_DOP -i 60
sleep 10
decListener -m SIM_DDC_TLM -i 60
sleep 10
decListener -m SIM_KSAT_ADA_TDA -i 60
sleep 10
decListener -m SIM_KSAT_ADA_DOP -i 60
sleep 10
decListener -m SIM_KSAT_TLM -i 60
sleep 10
decListener -m SIM_KSAT_SCH_RPL -i 60
sleep 10
decListener -m MCS_EXT_RPT_EOT -i 300
sleep 10
echo "container entrypoint started DEC NAOS gsc4eo@nl2-s-aut-srv-01"

touch /tmp/foo.txt
tail -f /tmp/foo.txt
