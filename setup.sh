
#TODO: prompt which helper to install
#change this if you don't use bash
shellConfig="$HOME/.bashrc"
location=$(pwd)

#installing dependencies 

#subfinder
GO111MODULE=on go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder

#httpx
GO111MODULE=on go get -v github.com/projectdiscovery/httpx/cmd/httpx

#dnsx
GO111MODULE=on go get -v github.com/projectdiscovery/dnsx/cmd/dnsx

#assetfinder
GO111MODULE=on go get -u github.com/tomnomnom/assetfinder

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

source $shellConfig


