#nuclei heler

# function to manually test results from nuclei

# example of use 
# testNucleiTemplate open-redirect http://www.sample.com
# TODO add flag to debug optional
testNucleiTemplate()
{
 if [ -z "$1" ]
    then
      echo "Use ${FUNCNAME[0]} nuclei-template-id URL"
      return 1;
    fi

 templateID=$1
 URL=$2
 pathToTemplate=$(locate $templateID|grep nuclei-templates) 
 echo "nuclei -debug -t $pathToTemplate -u $URL"
 nuclei -debug -t $pathToTemplate -u $URL
}
