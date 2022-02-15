
#Global variables
RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

#TODO: prompt which helper to install
echo -ne "${RED}\nStarting setup script${ENDCOLOR}\n\n"

#change this if you don't use bash
shellConfig="$HOME/.bashrc"

location=$(pwd)

#installing dependencies 
echo -ne "${YELLOW}Installing dependencies...${ENDCOLOR}\n\n"

echo -ne "${YELLOW}Installing subfinder ${ENDCOLOR}\n"
#subfinder
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

echo -ne "${YELLOW}Installing httpx ${ENDCOLOR}\n" 
#httpx
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

echo -ne "${YELLOW}Installing dnsx ${ENDCOLOR}\n" 
#dnsx
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest

echo -ne "${YELLOW}Installing assetfinder ${ENDCOLOR}\n" 
#assetfinder
go get -u github.com/tomnomnom/assetfinder

echo -ne "${YELLOW}Installing httprobe ${ENDCOLOR}\n" 
#httprobe
go install github.com/tomnomnom/httprobe@master

echo -ne "${YELLOW}Adding bbrf_helper.sh to $shellConfig${ENDCOLOR}\n"
echo "source $location/bbrf_helper.sh " >> $shellConfig

echo -ne "${YELLOW}Adding nuclei_helper.sh to $shellConfig${ENDCOLOR}\n"
echo "source $location/nuclei_helper.sh " >> $shellConfig

echo -ne "${YELLOW}Adding general_helper.sh to $shellConfig{ENDCOLOR}\n"
echo "source $location/general_helper.sh " >> $shellConfig

echo -ne "${YELLOW}Adding bbrf_helper.sh to $shellConfig{ENDCOLOR}\n"
echo "source $location/axiom_helper.sh " >> $shellConfig

echo -ne "${YELLOW}Adding amass_helper.sh to $shellConfig{ENDCOLOR}\n"
echo "source $location/amass_helper.sh " >> $shellConfig

source $shellConfig
