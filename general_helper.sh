#general helper functions 

function createScreen()
{
    if [ -z "$1" ]
    then
      echo -e "#Creates a screen session with given name \n Use ${FUNCNAME[0]} SCREEN_NAME"
      return 1;
    fi

	screen -q -S "$1"
}
# finds and then open a file with nano
locatenano()
{
    if [ -z "$1" ]
    then
      echo -e "Use ${FUNCNAME[0]} filename"
      return 1;
    fi
    search="$1"
    location=$(locate $search)
    #TODO choose from list when there are more than 1 result
    echo $location
    nano $location
}

