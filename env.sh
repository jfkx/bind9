#  env.sh
#  local configurations
#  13.07.2019 - Filip Krajcovic


# settings
export EDITOR=vi

export PATH=$PATH:$HOME/sh

if [[ ${EUID} == 0 ]] ; then
        #PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\h:\w\$ \[\033[00m\]'
else
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

#aliases

alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'

alias l='ls -lF'
alias ll='ls -lFh'
alias lr='ls -ltrFh'
alias ls='ls -a --color=auto'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias ds='disk_space'


#functions

function disk_space()  {
        if [ "$#" -eq 0 ] ; then
                /bin/ls | while read a ; do du -hs $a; done
        else
                l=`echo $1 | tail -c 2`
                if [ "$l" = "/" ] ; then
                        dn=`echo "${1%?}"`
                else
                        dn=$1
                fi
                /bin/ls -d1 ${dn}/**| while read a ; do du -hs $a; done
        fi
}

