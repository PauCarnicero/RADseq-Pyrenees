##fastSTRUCTURE analyses
########################

### mount the shared folder in virtualbox
sudo mount -t vboxsf RADseq /home/pau/RADseq


#variables  CHANGE ACCORDINGLY!
Species=Rp
batch=batch_1_m5_n5_M5

##PREPARING FILES (Pau)
##input file in: RADseq_data/TIMELESS_PYRENEES/$Species/STACKS_denovo_map/batch_1_m#_n#_M#/export/pop

cd /home/pau/RADseq/TIMELESS_PYRENEES/$Species/$batch/FastStructure
	
	#clean the headings from stacks:
	sed '1,2d' populations.structure > populations.structure.nohead
	#obtain a list of individuals
	awk '{print $1}' populations.structure.nohead | uniq > list_of_inds_str
	#obtain the list of populations
	awk -F'[_]' '{print $2}' list_of_inds_str > list_of_pops_str
	#change 0 per -9 in TextPAD
	awk '{print $1,$2}' populations.structure.nohead > populations.structure.c12
	awk '{$1=$2=""; print $0}' populations.structure.nohead  > populations.structure.nohead1
	sed 's/0/-9/g' populations.structure.nohead1 > populations.structure.nohead2
	paste populations.structure.c12 populations.structure.nohead2 > $Species.faststructure.str
	mv $Species.faststructure.str /home/pau/Programs/fastStructure
	rm populations.structure.nohead
	rm populations.structure.c12
	rm populations.structure.nohead1
	rm populations.structure.nohead2
	
## Executing the code ## 
########################

# The main script you will need to execute is structure.py. To see command-line options that need to be passed to the script, you can do the following:


##SIMPLE PRIOR######################### 
## INITIAL TEST run FastStructure for multipl Ks: 1 replicate per each K
## used to select the optimal K$i
## final analyses should be done with LOGISTIC PRIOR to "look for subtle structure in the data" (Raj et al. 2014)
mkdir /home/pau/Programs/fastStructure/$Species.output
mkdir /home/pau/Programs/fastStructure/$Species.output/simple
mkdir /home/pau/Programs/fastStructure/$Species.output/logistic
cd /home/pau/Programs/fastStructure/
	for k in {1..10};	do python structure.py --input=$Species.faststructure --full --seed 100 --output=$Species.output/simple -K $k --format=str; done
	


####Choosing model complexity
##from FastSTRUCTURE
	$ python chooseK.py --input=$Species.output/simple/$Species\_output_simple

	# these two numbers seems to be a range of possible optimal Ks*:
	#Model complexity that maximizes marginal likelihood = 4     #change accordingly!
	#Model components used to explain structure in data = 7		#change accordingly!
	
	sel_K=(5 6 7 8 9 10)

		# *comments on chooseK.py results on Google groups:
		https://groups.google.com/forum/#!topic/structure-software/s_rc_ueq6CU

##Additionally compute DeltaK
##?? CLUMPAK accepts output from STRUCTURE and a log prob file, but where is it?



# run FastStructure for multipl Ks: creating a script per each selected K to run 20 reps per K (Eliska)
# better do final analyses with LOGISTIC PRIOR


	for k in "${sel_K[@]}"; do echo '#!/bin/bash' > $Species.fastStructure_K$k.20reps.sh; done

	for k in "${sel_K[@]}"
	do
	for i in {1..20} 
	do 
	echo 'python structure.py --input '$Species'.faststructure --output '$Species'.output/logistic/'$Species'_output_log.'$i' -K '$k' --format str --prior logistic --tol=10e-5'>> $Species.fastStructure_K$k.20reps.sh
	done
	done

cd /home/pau/Programs/fastStructure/
	for k in "${sel_K[@]}"; do bash $Species.fastStructure_K$k.20reps.sh; done
	
	bash $Species.fastStructure_K5.20reps.sh
	
###Files organization (TO BE COMPLETED)	
##move .meanQ files to Ki directories

cd /home/pau/RADseq/TIMELESS_PYRENEES/$Species/$batch/FastStructure/

for i in "${sel_K[@]}";	do
	mkdir /K$i

for i in "${sel_K[@]}";	do
   mv /*$i.meanQ /K$i/

## summarysing results over replicates in CLUMPAK: http://clumpak.tau.ac.il
# prepare a zip folder with subfolders per every K (K2,K2...)
# in every folder move all files .meanq for a certain K
#put output in a folder named "CLUMPAK_$Species"


## Modify Clumpp files to plot admixture

	cd /home/pau/RADseq/TIMELESS_PYRENEES/$Species/$batch/FastStructure/
	mkdir DISTRUCT/
	for i in "${sel_K[@]}";	do awk -F"[ ]" '{for(i=6;i<=100;i++)printf "%s ",$i;printf "\n"}' CLUMPAK_$Species/K=$i/MajorCluster/CLUMPP.files/ClumppIndFile > DISTRUCT/ClumppIndFile.$i.meanQ; done
	## TO SOLVE:
	## !!Use MajorCluster or average clustering over all replicates??	
		#Eliska:YES
		
# Visualizing admixture proportions in user-defined order using distruct2.2.py
	popfile=/home/pau/RADseq/TIMELESS_PYRENEES/$Species/$batch/FastStructure/list_of_pops_str
	cd /home/pau/RADseq/TIMELESS_PYRENEES/$Species/$batch/FastStructure/
	for i in "${sel_K[@]}"; do python distruct.py -K $i --input=DISTRUCT/ClumppIndFile --output=DISTRUCT/K$i --title='admixture K'$i --popfile=$popfile; done #--poporder=order_geography 
		

##LOGISTIC PRIOR #########################

## INITIAL TEST run FastStructure for multipl Ks
	python structure.py --input=Sb_populations --full --seed 100 --output=Sb_output_logistic -K 1 --format=str --prior=logistic
	python structure.py --input=Sb_populations --full --seed 100 --output=Sb_output_logistic -K 2 --format=str --prior=logistic
	python structure.py --input=Sb_populations --full --seed 100 --output=Sb_output_logistic -K 3 --format=str --prior=logistic
	python structure.py --input=Sb_populations --full --seed 100 --output=Sb_output_logistic -K 4 --format=str --prior=logistic
	python structure.py --input=Sb_populations --full --seed 100 --output=Sb_output_logistic -K 5 --format=str --prior=logistic
	python structure.py --input=Sb_populations --full --seed 100 --output=Sb_output_logistic -K 6 --format=str --prior=logistic
	python structure.py --input=Sb_populations --full --seed 100 --output=Sb_output_logistic -K 7 --format=str --prior=logistic
	python structure.py --input=Sb_populations --full --seed 100 --output=Sb_output_logistic -K 8 --format=str --prior=logistic
	python structure.py --input=Sb_populations --full --seed 100 --output=Sb_output_logistic -K 9 --format=str --prior=logistic
	python structure.py --input=Sb_populations --full --seed 100 --output=Sb_output_logistic -K 10 --format=str --prior=logistic


# run FastStructure with logistic prior (for multipl Ks) and using script for multiple replicate runs

	export FAST_STRUCTURE_DIR=/media/ez/5TB_Ext4/january_2017/AE_FastStructure_INGROUP_FINAL_sampling/__LOCPRIOR/

	for i in {1..10}; do echo '#!/bin/bash' > fastStructure_K$i.10reps_locprior.sh; done

	for i in {1..10}; do perl runRepsStructure.pl --input batch_1.FASTstructure --output Sb_output_logistic -K $i --format str --prior logistic --tol=10e-5 >> fastStructure_K$i.10reps_locprior.sh; done

	for i in {1..10}; do bash fastStructure_K$i.10reps_locprior.sh; done


	python chooseK.py --input=Sb_output_logistic



# Choosing model complexity for logistic prior
$ python chooseK.py --input=ES_output_logistic

Model complexity that maximizes marginal likelihood = 1		# these two numbers seems to be a range of possible optimal Ks, see Google groups
Model components used to explain structure in data = 2		

# comments on chooseK.py results on Google groups:
https://groups.google.com/forum/#!topic/structure-software/s_rc_ueq6CU


# Visualizing admixture proportions in user-defined order using distruct2.2.py / Alternatively do it in CLUMPAK:distruct online

python distruct2.2.py -K 3 --input=ES_K3_output_simple --output=ES_K3_poporder --title='K=3 Poporder' --popfile=pop_ES  --poporder=order_geography 
