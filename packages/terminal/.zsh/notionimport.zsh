#!/bin/bash


function notionimport () {
    tree -fFi -I '' | grep -v '/$' | sed 's|^\./||' > notionimport.txt
    # tree -fFi -I '' | grep -v '/$' | sed 's|^\./||' > notionimport.txt

}