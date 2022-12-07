#!/usr/bin/bash

param_pattern="(\-\-[a-z]+\-?.*)=(.*)"
for i in $@
do
    param=$(sed -r 's|'$param_pattern'|\1|' <<< $i)
    arg=$(sed -r 's|'$param_pattern'|\2|' <<< $i)
    case $param in
        "--email")
            if [[ $arg =~ ^[A-Z0-9+_.-]+@[A-Z0-9.-]+$ ]];
              then
                email=$arg
              else
                my_exit "Invalid argument for parameter $param:$arg \n" 1
            fi
        ;;
        *)
            my_exit "Parameter is not found: $param \n" 1
        ;;
    esac
done

if [[ -z $email ]];
  then
    email="${USER}@"$(hostname -s)
fi

isGPGpresent=$(gpg --list-key | grep uid | grep $email)
echo $isGPGpresent
if [[ -z $isGPGpresent ]];
  then
    while true;
    do
      read -p "Generate quick GPG key (Yy): "
      if [[ $REPLY =~ ^[Yy]$ ]]
        then
          read -p "Please enter passphrase: "
          gpg --quick-gen-key --batch --passphrase $REPLY $email
          echo -e "Your GPG id is: ${email}\n"
          break
        else
          break 
      fi
    done
fi

while read RPM;
do
  sign_rpm.sh --rpm=$RPM --key-id=$email
done <<< $(find ./builds/RPMs/ -name  "*rpm")
