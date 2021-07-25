
#TODO: prompt which helper to install
#change this if you don't use bash
shellConfig="$HOME/.bashrc"
location=$(pwd)

echo "Adding bbrf_helper.sh to $shellConfig"
echo "source $location/bbrf_helper.sh " >> $shellConfig

echo "Adding nuclei_helper.sh to $shellConfig"
echo "source $location/nuclei_helper.sh " >> $shellConfig

echo "Adding general_helper.sh to $shellConfig"
echo "source $location/general_helper.sh " >> $shellConfig

echo "Adding bbrf_helper.sh to $shellConfig"
echo "source $location/axiom_helper.sh " >> $shellConfig

source $shellConfig


