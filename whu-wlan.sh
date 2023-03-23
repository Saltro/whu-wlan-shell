case $1 in
    "login" | "-i" | "i" | "in")
        USERID="your account"
        PASSWORD="your password"
        # Service must be Internet/yidong/dianxin/liantong
        SERVICE="Internet"
        EXPONENT="10001"
        MODULUS="94dd2a8675fb779e6b9f7103698634cd400f27a154afa67af6166a43fc26417222a79506d34cacc7641946abda1785b7acf9910ad6a0978c91ec84d40b71d2891379af19ffb333e7517e390bd26ac312fe940c340466b4a5d4af1d65c3b5944078f96a1a51a5a53e4bc302818b7c9f63c4a1b07bd7d874cef1c3d4b2f5eb7871"
        query=`curl -sL http://172.19.1.9:8080 | sed "s/.*\?\([^\/']*\)'.*/\1/g" | sed "s/&/%26/g" | sed "s/=/%3D/g"`
        pub_asn1=$(mktemp pub.asn1.XXXXX) || exit 1
        cat > $pub_asn1 << EOF
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
        pubkey_der=$(mktemp pubkey.der.XXXXX) || exit 1
        openssl asn1parse -genconf $pub_asn1 -out $pubkey_der
        pubkey_pem=$(mktemp pubkey.pem.XXXXX) || exit 1
        openssl rsa -in $pubkey_der -inform der -pubin -out $pubkey_pem
        password_txt=$(mktemp password.txt.XXXXX) || exit 1
        password_byte=`echo "$PASSWORD\c" | wc -c`
        modulus_len=`echo "$MODULUS\c" | wc -c`
        modulus_byte=`expr $modulus_len \/ 2`
        dd if=/dev/zero of=$password_txt bs=1 count=`expr $modulus_byte - $password_byte`
        echo "$PASSWORD\c" | dd of=$password_txt bs=1 seek=`expr $modulus_byte - $password_byte`
        secret=$(mktemp secret.XXXXX) || exit 1
        openssl rsautl -encrypt -raw -inkey $pubkey_pem -pubin -in $password_txt -out $secret
        password_secret=`xxd -c 256 -p $secret`
        echo $password_secret $query
        curl "http://172.19.1.9:8080/eportal/InterFace.do?method=login" \
            -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
            -d "userId=$USERID&password=$password_secret&service=$SERVICE&queryString=$query&passwordEncrypt=true"
        rm $pub_asn1 $pubkey_der $pubkey_pem $password_txt $secret
        ;;
    "logout" | "-o" | "o" | "out")
        curl -X POST "http://172.19.1.9:8080/eportal/InterFace.do?method=logout"
        ;;
    *) echo "Error: need to pass parameter!"
        exit 1
        ;;
esac
