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
locateNano()
{
    if [ -z "$1" ]
    then
      echo -e "Use ${FUNCNAME[0]} filename"
      return 1;
    fi
    search="$1"
    location=$(locate $search|head -n 1)
    #TODO choose from list when there are more than 1 result
    if [ ${#location} -gt 0 ]
    then
        nano $location
    else    
        echo "Not found: $search"
    fi
}
# finds and then open a file with nano
locateCat()
{
    if [ -z "$1" ]
    then
      echo -e "Use ${FUNCNAME[0]} filename"
      return 1;
    fi
    search="$1"
    location=$(locate $search|head -n 1 )
    #TODO choose from list when there are more than 1 result 

    if [ ${#location} -gt 0 ]
    then
        echo $location
        cat $location
        echo ""
    else
        echo "Not found: $search"
    fi
}
#use getField n (where n is the nth column)
getField() 
{
  awk  -v number=$1 '{print $number}'
}
#sort urls by TLD domain
sortByDomain()
{
    sed -e 's/^\([^.]*\.[^.]*\)$/.\1/'|sort -t . -k2|sed -e 's/^\.//'
} 

