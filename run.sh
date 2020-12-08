#!/bin/bash
#SBATCH -p normal
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
#SBATCH -o ./info/run.sh.o
#SBATCH -e ./info/run.sh.e

sbatch ./scripts/impute_chrX.sh X

for i in {1..22};
do
	touch chr$i.sh;
	echo "#!/bin/bash" >> chr$i.sh; 
	echo "#SBATCH -p normal" >> chr$i.sh;
	echo "#SBATCH -N 1" >> chr$i.sh;
	echo "#SBATCH -n 1" >> chr$i.sh;
	echo "#SBATCH -c 32" >> chr$i.sh;
	echo "#SBATCH -o ./info/chr${i}.sh.o" >> chr$i.sh;
	echo "#SBATCH -e ./info/chr${i}.sh.e" >> chr$i.sh;
	cat ./scripts/impute_autosome.sh >> chr$i.sh;
	sbatch chr$i.sh $i;
done

rm chr*
