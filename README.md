# BBRF & nuclei bash helpers 

## How to install

```
git clone https://github.com/pdelteil/BBRF-maintenance.git

location=$(pwd); echo "source $location/BBRF-maintenance/bbrf_helper.sh " >> ~/.bashrc

location=$(pwd); echo "source $location/BBRF-maintenance/nuclei_helper.sh " >> ~/.bashrc

source ~/.bashrc 
```


Loaded from the .bashrc file. 
You can check them running `declare -F` 
You can also use tab to autocomplete them. 


## BBRF helpers 


1. AddPrograms() 

This function is intented to be use while manually adding several programs to BBRF 

Example of use:

` addPrograms h1 `

Then you will be prompted to add information about the program:

![Screenshot from 2021-06-21 01-49-29](https://user-images.githubusercontent.com/20244863/122713055-173d7200-d233-11eb-8298-a7f3c86882f3.png)


#PENDING MORE EXAMPLES 
