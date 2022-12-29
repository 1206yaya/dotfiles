#!/bin/bash

function genmake() {
    if [[ $@ == "poetry" ]]; then
cat <<EOF >>Makefile
install: 
    poetry install

EOF
fi
}