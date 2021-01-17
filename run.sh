mkdir ./data/imputed

chmod +x ./scripts/impute_chrX.sh
bash ./scripts/impute_chrX.sh X

for i in {1..22};
do
	touch chr$i.sh
	cat ./scripts/impute_autosome.sh >> chr$i.sh
	chmod +x chr$i.sh
	bash chr$i.sh $i
done

rm chr*
