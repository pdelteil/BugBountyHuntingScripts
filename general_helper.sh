#general helper functions

# create a screen instance with a given name
# Example
# Create a screen session called "mySession"
# createScreen mySession
function createScreen()
{
    if [[ -z "$1" ]]; then
      echo -e "Create a screen session with given name \n Use ${FUNCNAME[0]} SCREEN_NAME"
      return 1
    fi
	screen -q -S "$1"
}

# Gets the IP address of a given domain
# Example
# Get the IP address of github.com
# getIp github.com
# Output: 140.82.121.4
function getIp()
{
  # Check if the domain name argument is empty
  if [[ -z "$1" ]]; then
    # Print a usage message and return an error code if the argument is empty
    echo "Get the IP address of a domain. Example: getIp example.com"
    return 1
  fi

  domain="$1"
  
  # Use the dig command to get the IP address of the domain and print the result
  dig "$domain" +short
}

# The locateNano function can be used to search for a file on the system and open it in the nano text editor.
# To search for and open a file called "example.txt" in the nano editor, you can call the function like this:
locateNano() 
{
  # Check if the filename argument is empty
  if [[ -z "$1" ]]; then
    # Print a usage message and return an error code if the argument is empty
    echo "Use ${FUNCNAME[0]} filename"
    return 1
  fi

  # Store the filename in a variable search
  search="$1"
  
  # Use the locate command to find the first matching file and store the result in a variable called location
  location=$(locate "$search" | head -n 1)

  # TODO: Choose from the list of results if there are more than 1 match

  # Check if the location variable is not empty
  if [[ ${#location} -gt 0 ]]; then
    # If the location is not empty, open the file in the nano editor
    nano "$location"
  else
    # If the location is empty, print a message indicating that the file was not found
    echo "File not found: $search"
  fi
}
# The locateCat function can be used to search for a file on the system and display its contents. 
# To search for and display the contents of a file called "example.txt", you can call the function like this:
# locateCat example.txt

locateCat() {
  # Check if the filename argument is empty
  if [[ -z "$1" ]]; then
    # Print a usage message and return an error code if the argument is empty
    echo "Use ${FUNCNAME[0]} filename"
    return 1
  fi

  # Store the filename in a variable called search
  search="$1"
  
  # Use the locate command to find the first matching file and store the result in a variable called location
  location=$(locate "$search" | head -n 1)

  # TODO: Choose from the list of results if there are more than 1 match

  # Check if the location variable is not empty
  if [[ ${#location} -gt 0 ]]; then
    # If the location is not empty, print the location and the contents of the file
    echo "$location"
    cat "$location"
    echo ""
  else
    # If the location is empty, print a message indicating that the file was not found
    echo "Not found: $search"
  fi
}


#use getField n (where n is the nth column)
# example:  cat file.txt | getField 4 
getField() 
{
    if [[ -z "$1" ]]; then
      echo -e "Use ${FUNCNAME[0]} number (nth column) [space as default separator]"
      echo "Example:  cat file.txt | getField 4"
      return 1
    fi
    if [[ -z "$2" ]]; then
        awk -v number=$1 '{print $number}'
    fi
    if [[ ! -z "$2" ]]; then
       # Receive the column number and field separator as function parameters and use them to print the specified column using the specified field separator
        awk -v column=$1 --field-separator=$2 '{print $column}'
    fi

}
#get domain From URL
getDomainFromURL()
{
    url="$1"
    awk -F'/' <<<"$1" #'{print $1}' # | sed 's/http:\/\///;s|\/.*||'
}
#sort urls by TLD domain
sortByDomain()
{
    sed -e 's/^\([^.]*\.[^.]*\)$/.\1/'|sort -t . -k2|sed -e 's/^\.//'
} 


# This function allows to find the difference between to input/output files (containing domains or urls)
# Example if you ran bbrf urls multiple times and you want to output only the new urls
#1. bbrf urls > file1.txt
#some programs/urls were added
#2. bbrf urls > file2.txt
#using the function we can output only the new added content to the file

#diffFiles file1.txt file2.txt output.txt
diffFiles()
{
  # Check if any of the filename arguments are empty
  if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]]; then
    # Print a usage message and return an error code if any of the arguments are empty
    echo "Use ${FUNCNAME[0]} file1.txt file2.txt output.txt"
    return 1
  fi

  # Store the filenames in variables
  file1="$1"
  file2="$2"
  output="$3"

  # Sort the lines in each input file and suppress column 3 (lines that appear in both files)
  # Redirect the output to the output file
  comm -3 <(sort "$file1") <(sort "$file2") > "$output"
}
#retreive the ORGs names in SSL Certs 
getOrgsFromCerts()
{
    if [[ -z "$1" ]]; then
      echo "Use ${FUNCNAME[0]} file.with.ssl.output.txt"
      return 1
    fi

    names=( $@ )
    for file in "${names[@]}"; do
        echo "$file"
        cat "$file" |grep -a subject |awk -F"O=" '{print $2}'|awk -F";" '{print $1}'|sort -u
    done
}
#retreive the ORGs names in SSL Certs 
getCNFromCerts()
{
    if [[ -z "$1" ]]; then
      echo "Use ${FUNCNAME[0]} file.with.ssl.output.txt"
      return 1
    fi

    names=( $@ )
    for file in "${names[@]}"; do
        echo "$file"
        cat "$file" |grep -a subject|awk -F"CN=" '{print $2}'|awk -F";" '{print $1}'|sort -u
    done
}

# Get all resolving Tls for a given domain name 
# For example, a program has a scope like companyA.*, we already know some domains companyA.com and companyA.fr, from here we could use all possible TLDs 
# to find new domains. This function first uses flat country TLDs and in a second iterating tests for com.tld (cases like com.ar, com.br, com.pe, etc)
getTLDs()
{
    URL="https://raw.githubusercontent.com/datasets/top-level-domain-names/master/top-level-domain-names.csv"
    FILE="/tmp/top-level-domain-names.csv"

    if [[ -z "$1" ]] ;    then
        echo "Use ${FUNCNAME[0]} targetDomain"
        echo "Example ${FUNCNAME[0]} testing-sites"
        return 1
    fi

    if [[ -f "$FILE" ]]; then
        echo "$FILE exists."
    #if file not found download it 
    else 
        echo "$FILE does not exist."
        echo "Downloading ... "
        curl -ks $URL -o $FILE
    fi

    target="$1"
    #do with com 
    tlds=$(grep country-code "$FILE" |awk -F "," '{print $1}'|grep -Pv '[^\x00-\x7F]'|awk -v target=$target '{print target$1}' |dnsx -silent| awk '{print "*."$1}')
    echo "$tlds" | tr '\n' ' '

    # test them with com 
    target="$target".com
    tlds=$(grep country-code "$FILE" |awk -F "," '{print $1}'|grep -Pv '[^\x00-\x7F]'|awk -v target=$target '{print target$1}' |dnsx -silent| awk '{print "*."$1}')
    echo "$tlds"| tr '\n' ' '
}
#finds the words that repeat the most in subdomains names
sortByDomainCount()
{
  # Check if the input file argument is empty
  if [[ -z "$1" ]]; then
    # Print a usage message and return an error code if the argument is empty
    echo "Use ${FUNCNAME[0]} INPUT_FILE"
    return 1
  fi

  # Store the input file in a variable called input_file
  input_file="$1"

  # Read the input file, replace dots with newlines, sort the lines, count the number of occurrences of each line, and sort the results by count in descending order
  cat "$input_file" | tr '\.' '\n' | sort | uniq -c | sort -nr
}

# find domains with IP address format
# ie: 108-249-27-4.lightspeed.wlfrct.sbcglobal.net
findIpsInDomains()
{
  # Check if the filename argument is empty
  if [[ -z "$1" ]]; then
    # Print a usage message and return an error code if the argument is empty
    echo "Use ${FUNCNAME[0]} filename"
    return 1
  fi
   
  input_file="$1"
  # Read the contents of the file and search for lines that contain an IP address in the format "X.X.X.X", where X is a number between 0 and 255.
  cat "input_file" | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
}
