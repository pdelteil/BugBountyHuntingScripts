#general helper functions

# Get the directory of the script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

function show_program_tags() {
  program="$1"
  local name="._id"
  local site=".tags.site"
  local author=".tags.author"
  local reward=".tags.reward"
  local url=".tags.url"
  local AddedDate=".tags.addedDate"
  local disabled="(.disabled|tostring)"
  local recon="(.tags.recon|tostring)"
  local source="(.tags.sourceCode|tostring)"
  local notes=".tags.notes"
  local api=".tags.api"
  local public=".tags.public"
  local gov=".tags.gov"
  local vpn=".tags.vpn"
  local cidr=".tags.cidr"
  local tags='"Program Name;"+'"$name"'+",Site;"+'"$site"'+",Author;"+'"$author"'+",Reward;"+'"$reward"'+",Url;"+'"$url"'+",disabled;"+'"$disabled"'+",Added Date;"+'"$AddedDate"'+",recon;"+'"$recon"' +",source code;"+'"$source"' + ",Notes;"+'"$notes"'+ ",api;"+'"$api"'+",public;"+'"$public"'+",gov;"+'"$gov"'+",vpn;"+'"$vpn"'+",cidr;"+'"$cidr"

  local output
  output=$(bbrf show "$program" | jq "$tags" | tr -d '"' | sed 's/,/\n/g')
  echo "$output"
}

print_table() {
    var="$1"
    # Split the variable into lines
    IFS=$'\n' read -rd '' -a lines <<< "$var"
    # Define an array of colors for each column
    colors=("32" "31")  #  Green, Red

    # Function to print horizontal line
    print_horizontal_line() {
      for ((i = 0; i < ${#max_widths[@]}; i++)); do
        printf "+-%*s-" "${max_widths[i]}" "" | tr ' ' '-'
      done
      printf "+\n"
    }

    # Function to print table cells with colors
    print_cell() {
      local value="$1"
      local width="$2"
      local color="$3"
      printf "| \e[1;${color}m%-*s\e[0m " "$width" "$value"
    }

    # Initialize the maximum widths array with zeros
    max_widths=()
    for ((i = 0; i < ${#colors[@]}; i++)); do
      max_widths[$i]=0
    done

    # Calculate the maximum width of each column
    for line in "${lines[@]}"; do
      IFS=';' read -ra fields <<< "$line"
      for ((i = 0; i < ${#fields[@]}; i++)); do
        field="${fields[i]}"
        width=${#field}
        if (( width > max_widths[i] )); then
          max_widths[i]=$width
        fi
      done
    done

    # Print the top border
    print_horizontal_line

    # Print the table header with colors
    IFS=';' read -ra header_fields <<< "${lines[0]}"
    for i in "${!colors[@]}"; do
      print_cell "${header_fields[i]}" "${max_widths[i]}" "${colors[i]}"
    done
    printf "|\n"
    
    # Print the separator line
    print_horizontal_line
    
    # Print each line as a row in the table with colors
    for line in "${lines[@]:1}"; do
      IFS=';' read -ra fields <<< "$line"
      for i in "${!colors[@]}"; do
        value="${fields[i]}"
        print_cell "$value" "${max_widths[i]}" "${colors[i]}"
      done
      printf "|\n"
    done

    # Print the bottom border
    print_horizontal_line
}
    

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

function getMyIp()
{
    curl ifconfig.me
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
      echo -e "Use ${FUNCNAME[0]} number (nth column) separator [optional, use double quotes, space is the default separator]"
      echo "Examples:  cat file.txt | getField 4"
      echo "          echo \"word1 word2 word3\" | getField 2 "
      echo "          word2"
      echo "          echo \"word1 word2; word3\" | getField 2 \";\""
      echo "          word3"

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
# Usage:
#   extract_domain [URL]
#
# If URL is not provided, the function reads from stdin.
#
# Examples:
#   extract_domain "http://www.example.com/path/to/resource"
#   echo "http://www.example.com/path/to/resource" | extract_domain

getDomainFromURL()
{
# Read each line of the input
while read -r URL; do
    # Extract the protocol (e.g. "http")
    local PROTOCOL=$(echo "$URL" | grep :// | sed -e's,^\(.*://\).*,\1,g')
    # Remove the protocol
    URL=$(echo "$URL" | sed -e "s,$PROTOCOL,,g")

    # Extract the user (if any)
    local USER=$(echo "$URL" | grep @ | cut -d@ -f1)

    # Remove the user (if any)
    URL=$(echo "$URL" | sed -e "s,$USER@,,g")

    # Extract the hostname
    local HOST=$(echo "$URL" | cut -d'/' -f1)

    # Remove the hostname
    URL=$(echo "$URL" | sed -e "s,$HOST,,g")

    # Extract the port (if any)
    local PORT=$(echo "$HOST" | grep : | cut -d: -f2)

    # Remove the port (if any)
    HOST=$(echo "$HOST" | sed -e "s,:$PORT,,g")

    # Extract the path (if any)
    local PATH_URL=$(echo "$URL" | grep "/" | cut -d'/' -f2-)

    # Remove the path (if any)
    URL=$(echo "$URL" | sed -e "s,/$PATH_URL,,g")

    # Print the domain name
    echo "$HOST"

done

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
    URL="https://raw.githubusercontent.com/pdelteil/top-level-domain-names/master/top-level-domain-names.csv"
    FILE="/tmp/top-level-domain-names.csv"

    if [[ -z "$1" ]]; then
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

# Remove color codes from text
# Example
#  echo "This text has \033[31mred\033[0m color" | removeColor
#  The output will be "This text has red color" with no color codes.
removeColor() 
{
  sed 's/\x1b\[[0-9;]*m//g'
}

#This function opens a file in the nano text editor and then sources it.
nano2()
{
    inputFile="$1"
    nano "$inputFile"
    source "$inputFile"
}

remove_protocol_and_path() {
  if [ -t 0 ]; then
    # No input from pipe, read from standard input
    while IFS= read -r line; do
      process_line "$line"
    done
  else
    # Read from pipe
    while IFS= read -r line; do
      process_line "$line"
    done < /dev/stdin
  fi
}

process_line() {
  local line=$1

  # Remove the protocol (e.g., "http://", "https://", "ftp://")
  line=${line#*//}

  # Remove the path by extracting the domain or hostname
  line=${line%%/*}

  echo "$line"
}

check_latest_version() {

    local tool_file="$script_dir/latest_version.txt"
    local github_repo="pdelteil/BugBountyHuntingScripts"
    local github_tag

    # Get the latest GitHub tag
    github_tag=$(curl -s "https://api.github.com/repos/${github_repo}/tags" | jq -r '.[0].name')

    if [[ -z "${github_tag}" ]]; then
        echo "Error: Unable to retrieve the latest GitHub tag."
        return 1
    fi

    # Extract the version from the tool file
    local tool_version
    tool_version=$(grep -oP 'v\d+\.\d+\.\d+' "${tool_file}")

    if [[ -z "${tool_version}" ]]; then
        echo "Error: Unable to extract the version from the tool file."
        return 1
    fi

    echo "Latest GitHub tag: ${github_tag}"
    echo "Local tool version: ${tool_version}"

    # Compare versions
    if [[ "${tool_version}" == "${github_tag}" ]]; then
        echo "The tool is up to date."
    else
        echo "A new version is available."
        # Prompt user to update the tool
        read -rp "Do you want to update the tool? (y/n): " choice

        if [[ "${choice}" =~ ^[Yy]$ ]]; then
            # Update tool using git pull
            git -C "$(dirname "${tool_file}")" pull

            # Source .bashrc to reflect changes
            source ~/.bashrc

            echo "Tool updated successfully."
        else
            echo "Tool update skipped."
        fi
    fi
}

# create tmux instance with a given name
# Example
# Create tmux session called "mySession"
# createTmux mySession
function createTmux()
{
    if [[ -z "$1" ]]; then
      echo -e "Create tmux session with given name \n Use ${FUNCNAME[0]} TMUX_NAME"
      return 1
    fi
    tmux new -s "$1"
}

function attachTmux()
{

IFS=$'\n'
sessions=($(tmux ls ))

# Show enumerated tmux sessions
if [ ${#sessions[@]} -eq 0 ]; then
    echo "No tmux sessions found."
else
    echo "Available tmux sessions:"
    for i in "${!sessions[@]}"; do
        echo "[$i] ${sessions[$i]}"
    done

    # Prompt user to choose a session ID
    read -p "Enter the ID of the session to attach: " session_id

    # Validate user input
    if ! [[ "$session_id" =~ ^[0-9]+$ ]]; then
        echo "Invalid session ID. Please enter a valid numeric ID."
        exit 1
    fi

    if [ "$session_id" -ge 0 ] && [ "$session_id" -lt "${#sessions[@]}" ]; then
        chosen_session="${sessions[$session_id]}"
        chosen_session=$(echo $chosen_session|awk -F: '{print $1}')
        tmux attach -t "$chosen_session"
    else
        echo "Invalid session ID. Please enter a valid ID within the range."
        exit 1
    fi
fi

}

# replaces newlines for spaces
flatten() {
    tr '\n' ' '
}

getWayMoreUrls()
{
    domain="$1"
    installedPath="~/software/waymore/waymore.py"
    python3 "$installedPath" -i "$domain" -mode U
}
getWayBackUrls()
{
    input="$1"
    echo "$input" |waybackurls
}
