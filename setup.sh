
#TODO: prompt which helper to install
location=$(pwd); echo "source $location/bbrf_helper.sh " >> ~/.bashrc
location=$(pwd); echo "source $location/nuclei_helper.sh " >> ~/.bashrc
location=$(pwd); echo "source $location/general_helper.sh " >> ~/.bashrc
location=$(pwd); echo "source $location/axiom_helper.sh " >> ~/.bashrc

source ~/.bashrc 
