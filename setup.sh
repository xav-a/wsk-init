#!/bin/bash

# Upgrade disk image and install vim, curl, pip3 & nginx
echo -e "set number\nset tabstop=4\nset softtabstop=4\nset shiftwidth=4\nset expandtab\nset hlsearch\n" >> ~/.vimrc
echo -e "SETUP ./~vimrc"

# scala syntax hightlighting
mkdir -p ~/.vim/{ftdetect,indent,syntax} && \
for d in ftdetect indent syntax; do
    wget -O ~/.vim/$d/scala.vim https://raw.githubusercontent.com/derekwyatt/vim-scala/master/$d/scala.vim > /dev/null;
done
echo -e "SETUP scala.vim at ~/.vim\n"

