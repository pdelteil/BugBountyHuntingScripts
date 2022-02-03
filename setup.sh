
#TODO: prompt which helper to install
echo "Starting setup script"

#change this if you don't use bash
shellConfig="$HOME/.bashrc"

location=$(pwd)

#installing dependencies 
echo "Installing dependencies..."

echo "Installing subfinder"
#subfinder
GO111MODULE=on go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder

echo "Installing httpx" 
#httpx
GO111MODULE=on go get -v github.com/projectdiscovery/httpx/cmd/httpx

echo "Installing dnsx" 
#dnsx
GO111MODULE=on go get -v github.com/projectdiscovery/dnsx/cmd/dnsx

echo "Installing assetfinder" 
#assetfinder
GO111MODULE=on go get -u github.com/tomnomnom/assetfinder

echo "Installing httprobe" 
#httprobe
go get -u github.com/tomnomnom/httprobe@master

echo "Adding bbrf_helper.sh to $shellConfig"
echo "source $location/bbrf_helper.sh " >> $shellConfig

echo "Adding nuclei_helper.sh to $shellConfig"
echo "source $location/nuclei_helper.sh " >> $shellConfig

echo "Adding general_helper.sh to $shellConfig"
echo "source $location/general_helper.sh " >> $shellConfig

echo "Adding bbrf_helper.sh to $shellConfig"
echo "source $location/axiom_helper.sh " >> $shellConfig

echo "Adding amass_helper.sh to $shellConfig"
echo "source $location/amass_helper.sh " >> $shellConfig

source $shellConfig

