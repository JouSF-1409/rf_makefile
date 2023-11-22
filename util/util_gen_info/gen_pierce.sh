#!/bin/bash

#gen info for piecring
#after pick arrival or rfs

wkdir=$1
pierce_file="pierce_after_pick.lst"

cd $wkdir

for list in `ls */rf.lst` ; do
    dir=`dirname $list`
    if [ -e $dir/$pierce_file ];then
        rm $dir/$pierce_file
    fi
    for traces in `awk '{if($3>0){print $1}}' $list` ; do
        saclst stla stlo baz user0 f ${traces} |
            piercing.pl s ~/opt/util/models/iasp91.pierce 100 >> $dir/$pierce_file
    done
done
if [ -e pierce.dat ];then
    rm pierce.dat
fi
done */$pierce_file >> pierce.dat
