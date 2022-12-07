#! /usr/bin/bash

my_exit(){
    echo -e "$1"
    exit $2
}

param_pattern="(\-\-[a-z]+\-?.*)=(.*)"
for i in $@
do
    param=$(sed -r 's|'$param_pattern'|\1|' <<< $i)
    arg=$(sed -r 's|'$param_pattern'|\2|' <<< $i)
    case $param in
        "--pass")
             pass=$arg
        ;;
        "--key-id")
             key_id=$arg
        ;;
        "--rpm")
            if [[ $arg =~ ^.+[.]rpm$ ]];
              then
                rpm=$arg
              else
                my_exit "Invalid argument for parameter $param:$arg \n" 1
            fi
        ;;
        *)
            my_exit "Parameter is not found: $param \n" 1
        ;;
    esac
done

rpm --addsign $rpm --define "_gpg_name $key_id"  
