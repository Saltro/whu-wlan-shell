#! /bin/bash

set -ue

getMachine() {
    case `uname -s` in
        Darwin*) echo "mac";;
        Linux*Microsoft*) echo "wsl";;
        Linux*) echo "linux";;
        CYGWIN* | MINGW* | MINGW32* | MSYS*) echo "win";;
        *) echo "unknown";;
    esac
}

logError() {
    echo -e $1
    exit 1
}

login() {
    userId=$1
    rawPassword=$2
    service=$3
    EXPONENT="10001"
    MODULUS="94dd2a8675fb779e6b9f7103698634cd400f27a154afa67af6166a43fc26417222a79506d34cacc7641946abda1785b7acf9910ad6a0978c91ec84d40b71d2891379af19ffb333e7517e390bd26ac312fe940c340466b4a5d4af1d65c3b5944078f96a1a51a5a53e4bc302818b7c9f63c4a1b07bd7d874cef1c3d4b2f5eb7871"

    ping -c 3 -i 0.2 -W 3 qq.com > /dev/null && echo "Warn: Successfully pinged to qq.com, which means you may have logged in"
    response=`curl -m 5 -sL http://172.19.1.9:8080` \
        || logError " \
            Error: Can't reach certification website (172.19.1.9:8080). This could be that you are already logged in, or you are not yet connected to WHU-WLAN/WHU-STU/WHU-STU-5G"
    if [ $machine == "mac" ]
    then
        echo "this is mac"
        queryString=`echo $response \
            | sed "s/.*\?\([^\/']*\)'.*/\1/g" \
            | sed "s/&/%26/g" \
            | sed "s/=/%3D/g"`
    else
        echo "this is not mac"
        queryString=`echo $response \
            | sed "s/.*?\([^\/']*\)'.*/\1/g" \
            | sed "s/&/%26/g" \
            | sed "s/=/%3D/g"`
    fi
    asn1File=`mktemp pub.asn1.XXXXX`
    derFile=`mktemp pubkey.der.XXXXX`
    pemFile=`mktemp pubkey.pem.XXXXX`
    passwordFile=`mktemp password.txt.XXXXX`
    secretFile=`mktemp secret.XXXXX`
    trap "rm $asn1File $derFile $pemFile $passwordFile $secretFile" EXIT
    cat > $asn1File << EOF
asn1=SEQUENCE:pubkeyinfo

[pubkeyinfo]
algorithm=SEQUENCE:rsa_alg
pubkey=BITWRAP,SEQUENCE:rsapubkey

[rsa_alg]
algorithm=OID:rsaEncryption
parameter=NULL

[rsapubkey]
n=INTEGER:0x$MODULUS
e=INTEGER:0x$EXPONENT
EOF
    openssl asn1parse -genconf $asn1File -out $derFile
    openssl rsa -in $derFile -inform der -pubin -out $pemFile
    if [ $machine == "mac" ]
    then
        passwordByte=`echo "$rawPassword\c" | wc -c`
        modulusLength=`echo "$MODULUS\c" | wc -c`
        modulusByte=`expr $modulusLength \/ 2`
        dd if=/dev/zero of=$passwordFile bs=1 count=`expr $modulusByte - $passwordByte`
        echo "$rawPassword\c" | dd of=$passwordFile bs=1 seek=`expr $modulusByte - $passwordByte`
    else
        passwordByte=`echo -e "$rawPassword\c" | wc -c`
        modulusLength=`echo -e "$MODULUS\c" | wc -c`
        modulusByte=`expr $modulusLength \/ 2`
        dd if=/dev/zero of=$passwordFile bs=1 count=`expr $modulusByte - $passwordByte`
        echo -e "$rawPassword\c" | dd of=$passwordFile bs=1 seek=`expr $modulusByte - $passwordByte`
    fi
    openssl rsautl -encrypt -raw -inkey $pemFile -pubin -in $passwordFile -out $secretFile
    encryptedPassword=`xxd -c 256 -p $secretFile`
    curl -m 5 "http://172.19.1.9:8080/eportal/InterFace.do?method=login" \
        -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
        -d "userId=$userId" \
        -d "password=$encryptedPassword" \
        -d "service=$service" \
        -d "queryString=$queryString" \
        -d "passwordEncrypt=true" \
        || logError "Error: Send login request to 172.19.1.9:8080 error"
}

machine=`getMachine`

case $1 in
    "login" | "-i" | "i" | "in")
        USERID="your account"
        PASSWORD="your password"
        # Service must be Internet/yidong/dianxin/liantong
        SERVICE="Internet"
        login $USERID $PASSWORD $SERVICE || logError "Login error"
        ;;
    "logout" | "-o" | "o" | "out")
        curl -X POST "http://172.19.1.9:8080/eportal/InterFace.do?method=logout" \
            || logError "Error: Send logout request to 172.19.1.9:8080 error. This could be that you are not yet connected to WHU-WLAN/WHU-STU/WHU-STU-5G"
        ;;
    *) echo "Error: need to pass parameter!"
        exit 1
        ;;
esac
