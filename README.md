# A shell script to connect WHU WLAN

This is a bash script for logging in and out of the wireless network at Wuhan University (WHU) in China.

## Usage

To use this script, open a terminal and navigate to the directory containing the script. Then run the script with one of the following commands:

- `whu-wlan.sh {login|in|-i|i}`: Logs in to the network. Please write **USERID** and **PASSWORD** in script first. If you want to connect a specific service, rewrite **SERVICE** please.
- `whu-wlan.sh {logout|out|-o|o}`: Logs out of the network.

## Dependencies

This script requires the following dependencies:

- Bash: The script is written in Bash and requires a Bash shell to run.
- OpenSSL: The script uses OpenSSL to generate and encrypt the password.
- curl: The script uses curl to send HTTP requests to the network's login and logout pages.
- sed: The script uses sed to parse the query string returned by the network's login page.
- dd: The script uses dd to pad the password to the length of the RSA modulus.

## Notice

- This script is intended for use on the WHU-WLAN, WHU-STU and WHU-STU-5G. It may not work on other networks.
- The script requires your user ID and password to log in to the network. Your password will be encrypted using RSA public key encryption before it is sent to the network's login page.
- This script is provided as-is and without warranty. Use at your own risk.
