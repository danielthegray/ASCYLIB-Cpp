#!/bin/bash

ds=sl;
set_cpu=0
repetitions=4
duration=5000
keep=median
fixed_file_dat=0

mkdir -p data
make clean
make "SET_CPU := 0"

algos=( SL_FRASER SL_HERLIHY_LB SL_HERLIHY_LF SL_OPTIK );

params_initial=(  1024 16384 65536 1024 16384 65536 );
params_update=(   40   40    40    40   40    40 );
params_workload=( 0    0     0     2    2     2 );

num_params=${#params_initial[*]};

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
duration_secs=$(($duration/1000));
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

    workload=${params_workload[$i]};
    if [ "${workload}0" = "0" ] ; then
	workload=0;
    fi;

    #algos_w=( "${algos[@]/%/_$workload}" )
    #algos_progs=( "${algos[@]/#/./bin/test -a}" )
    #algos_str="${algos_w[@]}";
    algos_str="${algos[@]}";

    if [ $fixed_file_dat -ne 1 ] ; then
	out="$(hostname).${ds}.i${initial}.u${update}.w${workload}.dat"
    else
	out="data.${ds}.i${initial}.u${update}.w${workload}.dat"
    fi;

    echo "### params -i$initial -r$range -u$update / keep $keep of reps $repetitions of dur $duration" | tee data/$out;
    ./scripts/scalability_rep_simple.sh "$cores" $repetitions $keep "$algos_str" -d$duration -i$initial -r$range -u$update -w$workload \
				 | tee -a data/$out;
done;