
function createScreen()
{
    if [ -z "$1" ]
    then
      echo -e "#Creates a screen session with given name \n Use ${FUNCNAME[0]} SCREEN_NAME"
      return 1;
    fi

	screen -q -S "$1"
}
