#!/bin/bash

ds=qu;
set_cpu=0
repetitions=3
duration=7000
keep=median
cores=ppopp
#ub=BINARIES PLACEMENT
#uo=DATA PLACEMENT FOLDER
fixed_file_dat=0

mkdir -p data
make clean
make "SET_CPU := 0"

algos=( Q_MS_LF Q_MS_LB Q_MS_H );

# params_initial=( 128 512 2048 4096 8192 );
# params_update=( 100 50  20   10   1 );
param_initial=65534;
params_put=( 40 50 60 );
params_nc=( 10 );

num_params=${#params_put[*]};

max_cores=$(grep "processor" /proc/cpuinfo | wc -l)
extra_cores=$(( $max_cores * 3 / 2 ))
if [[ $max_cores -eq 1 ]] ; then
	max_cores=4
fi
increment=$(($max_cores/20))
if [[ $increment -eq 0 ]] ; then
	increment=1
fi
extra_increment=$(($increment*2))

cores="$(seq $increment $increment $max_cores) $(seq $(($max_cores+$extra_increment)) $extra_increment $extra_cores)"
if [[ $increment -gt 1 ]] ; then
	cores="1 $cores"
fi

num_tests_cores=$(echo "$cores" | wc -w);
duration_secs=$(echo $duration/1000 | bc -l);
num_algorithms=${#algos[@]};

dur_tot=$(( $num_algorithms*$num_params*$num_tests_cores*$repetitions*$duration_secs ));

printf "#> $num_algorithms algos, $num_params params, $num_tests_cores cores configurations, $repetitions reps of %.2f sec = %.2f sec\n" $duration_secs $dur_tot;
printf "#> = %.2f hours\n" $( echo "$dur_tot/3600" | bc -l );

#printf "   Continue? [Y/n] ";
#read cont;
#if [ "$cont" = "n" ]; then
#	exit;
#fi;

#cores=$cores_backup;

for ((i=0; i < $num_params; i++))
do
    initial=${params_initial[$i]};
    update=${params_update[$i]};
    range=$((2*$initial));

    #algos_w=( "${algos[@]/%/_$workload}" )
    #algos_progs=( "${algos[@]/#/./bin/test -a}" )
    #algos_str="${algos_w[@]}";
    algos_str="${algos[@]}";

    if [ $fixed_file_dat -ne 1 ] ; then
	out="$(hostname).${ds}.thr.p${put}.dat"
    else
	out="data.${ds}.thr.p${put}.dat"
    fi;

    echo "### params -i$initial -p$put / keep $keep of reps $repetitions of dur $duration" | tee data/$out;
    ./scripts/scalability_rep_simple.sh "$cores" $repetitions $keep "$algos_str" -d$duration -i$initial -p$put \
				 | tee -a data/$out;
done;