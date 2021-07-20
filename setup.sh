
#TODO: prompt which helper to install
location=$(pwd); echo "source $location/BBRF-maintenance/bbrf_helper.sh " >> ~/.bashrc
location=$(pwd); echo "source $location/BBRF-maintenance/nuclei_helper.sh " >> ~/.bashrc
location=$(pwd); echo "source $location/BBRF-maintenance/general_helper.sh " >> ~/.bashrc
location=$(pwd); echo "source $location/BBRF-maintenance/axiom_helper.sh " >> ~/.bashrc

source ~/.bashrc 
