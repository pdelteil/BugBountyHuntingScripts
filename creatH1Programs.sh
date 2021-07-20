#!/bin/bash
source ~/BBRF-maintenance/bbrf_helper.sh
#Global variables
RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

# Initiate new BBRF programs from your public and private HackerOne programs
h1name="fdeleite"
apitoken="SckVcvL+QnykGDaLrOCk8qOiGI+jpO4LFymeRnadFdQ="
apiUrl='https://api.hackerone.com/v1/hackers/programs'
next="$apiUrl?page%5Bsize%5D=100"
found=0
notFound=0
while [ "$next" ]; do

  data=$(curl -s "$next" -u "$h1name:$apitoken")
  
  next=$(echo $data | jq .links.next -r)
  #echo "$data" 
  for l in $(echo $data | jq '.data[] | select( .attributes.state != null and .attributes.submission_state != "disabled") | ( .id + "," + .attributes.handle)' -r); do

    p=$(echo $l | cut -d',' -f 2)

    #exists=$(bbrf programs where h1id is $p --show-empty-scope --show-disabled)
    exists=$(checkProgramH1 $p| grep -v 'Programs found\|No program found')
    if [ -z "$exists" ]; then
      notFound=$((notFound + 1))  
      echo -ne "${YELLOW} Adding new program $p to BBRF...${ENDCOLOR}\n"
      #bbrf new $p -t platform:hackerone -t h1id:$p
      
      #(
      #curl -g -s $apiUrl'/'$p -u $h1name:$apitoken #| tee \
      # >(jq '.relationships.structured_scopes.data[].attributes|select(.asset_type == "URL" and .eligible_for_bounty and .eligible_for_submission and .archived_at == null)|.asset_identifier' -r |bbrf inscope add - -p $p) \
      # >(jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_submission == false and .archived_at == null) | .asset_identifier' -r | bbrf outscope add - -p $p ) \
      # > /dev/null
      #) &
    else 
        found=$((found+1))
        echo -ne "${RED}Program $p already on BBRF!${ENDCOLOR}\n"
    fi
  done

done
echo "new $notFound"
echo "exiting $found"
