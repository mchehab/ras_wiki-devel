#!/bin/bash

trap 'catch $LINENO "$BASH_COMMAND"' ERR
catch() {
	echo "Error on line $1: $2"
	exit 1
}

ERROR_DEFAULT='"cache-error"'
ERROR=""
PHY_ADDR=
VIR_ADDR=
MULT_ERR=
ERR_INFO=
VALIDATION=
FLAGS=

HELP="$0 <options>, where all <options> are optional and can be:\n\n"
HELP+="- Zero or more error types (if none set, defaults to cache error):\n"
HELP+="\t<-c|--cache-error> - error type has cache error\n"
HELP+="\t<-t|--tlb-error> - error type has TLB\n"
HELP+="\t<-b|--bus-error> - error type has bus error\n"
HELP+="\t<-v|--vendor-error|--micro-arch-error>\n\n"
HELP+="- Zero or more flags (if none set, defaults all but overflow):\n"
HELP+="\t<--first-error-cap>\n"
HELP+="\t<--last-error-cap>\n"
HELP+="\t<--propagated>\n"
HELP+="\t<--overflow>\n\n"
HELP+="- Zero or more validation bits (if none set, defaults to all the ones below):\n"
HELP+="\t<--multiple-error-valid>\n"
HELP+="\t<--flags-valid>\n"
HELP+="\t<--error-info-valid>\n"
HELP+="\t<--virt-addr-valid>\n"
HELP+="\t<--phy-addr-valid>\n\n"
HELP+="- Integer or hexadecimal values:\n"
HELP+="\t<-m|--multile-error> [value]\n"
HELP+="\t<-e|--error-info> [value]\n"
HELP+="\t<-P|--phy|--physical-address> [value]\n"
HELP+="\t<-V|--virt|--virtual-address> [value]\n\n"

while [ "$1" != "" ]; do
	case "$1" in
		# Error type
		-c|--cache-error)
			if [ ! -z "$ERROR" ]; then ERROR+=", "; fi
			ERROR+='"cache-error"'
			;;
		-t|--tlb-error)
			if [ ! -z "$ERROR" ]; then ERROR+=", "; fi
			ERROR+='"tlb-error"'
			;;
		-b|--bus-error)
			if [ ! -z "$ERROR" ]; then ERROR+=", "; fi
			ERROR+='"bus-error"'
			;;
		-v|--vendor-error|--micro-arch-error)
			if [ ! -z "$ERROR" ]; then ERROR+=", "; fi
			ERROR+='"micro-arch-error"'
			;;

		# Integer values
		-m|--multile-error)
			shift
			MULT_ERR="$(printf '%d', $1|cut -d, -f1)"
			;;
		-e|--error-info)
			shift
			ERR_INFO="$(printf '%d', $1|cut -d, -f1)"
			;;
		-P|--phy|--physical-address)
			shift
			PHY_ADDR="$(printf '%d', $1|cut -d, -f1)"
			;;
		-V|--virt|--virtual-address)
			shift
			VIR_ADDR="$(printf '%d', $1|cut -d, -f1)"
			;;
		# Flags
		--first-error-cap)
			if [ ! -z "$FLAGS" ]; then FLAGS+=", "; fi
			FLAGS+='"first-error-cap"'
			;;
		--last-error-cap)
			if [ ! -z "$FLAGS" ]; then FLAGS+=", "; fi
			FLAGS+='"last-error-cap"'
			;;
		--propagated)
			if [ ! -z "$FLAGS" ]; then FLAGS+=", "; fi
			FLAGS+='"propagated"'
			;;
		--overflow)
			if [ ! -z "$FLAGS" ]; then FLAGS+=", "; fi
			FLAGS+='"overflow"'
			;;
		# Validation bits
		--multiple-error-valid)
			if [ ! -z "$VALIDATION" ]; then VALIDATION+=", "; fi
			VALIDATION+='"multiple-error-valid"'
			;;
		--flags-valid)
			if [ ! -z "$VALIDATION" ]; then VALIDATION+=", "; fi
			VALIDATION+='"flags-valid"'
			;;
		--error-info-valid)
			if [ ! -z "$VALIDATION" ]; then VALIDATION+=", "; fi
			VALIDATION+='"error-info-valid"'
			;;
		--virt-addr-valid)
			if [ ! -z "$VALIDATION" ]; then VALIDATION+=", "; fi
			VALIDATION+='"virt-addr-valid"'
			;;
		--phy-addr-valid)
			if [ ! -z "$VALIDATION" ]; then VALIDATION+=", "; fi
			VALIDATION+='"phy-addr-valid"'
			;;
		*)
			echo -e $HELP
			exit 1
			;;

		help|-h|--help)
			echo -e $HELP
			exit 0
			;;
	esac
	shift
done


if [ -z "$ERROR" ]; then
	ERROR=$ERROR_DEFAULT
fi

CACHE_MSG='{ "execute": "qmp_capabilities" } '
CACHE_MSG+='{ "execute": "arm-inject-error", "arguments": { "errortypes": ['$ERROR']'

if [ ! -z "$VALIDATION" ]; then
	CACHE_MSG+=", \"validation\": [ $VALIDATION ]"
fi

if [ ! -z "$FLAGS" ]; then
	CACHE_MSG+=", \"flags\": [ $FLAGS ]"
fi

if [ ! -z "$MULT_ERR" ]; then
	CACHE_MSG+=", \"multiple-error\": $MULT_ERR"
fi

if [ ! -z "$ERR_INFO" ]; then
	CACHE_MSG+=", \"error-info\": $ERR_INFO"
fi

if [ ! -z "$VIR_ADDR" ]; then
	CACHE_MSG+=", \"virt-addr\": $VIR_ADDR"
fi

if [ ! -z "$PHY_ADDR" ]; then
	CACHE_MSG+=", \"phy-addr\": $PHY_ADDR"
fi

CACHE_MSG+=' } }'

echo $CACHE_MSG
echo $CACHE_MSG | nc localhost 4445
