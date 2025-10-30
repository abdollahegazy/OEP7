#!/bin/bash

# Base directory containing rotations 1-6
base_dir="../../simulations/oep7_atg8e_system/integral/memb-1/post_harmonic_restraint"

# Loop through directories 1 to 6
for i in {1..6}; do

    sim_dir="${base_dir}/${i}"
    
    if [ ! -d "$sim_dir" ]; then
        echo "ERROR: Directory $sim_dir does not exist, skipping..."
        continue
    fi
    
    if [ ! -f "$sim_dir/eq_local.sh" ]; then
        echo "ERROR: eq_local.sh not found in $sim_dir, skipping..."
        continue
    fi
    
    echo "=========================================="
    echo "Starting equilibration in directory: $i"
    echo "=========================================="
    
    # Change to the simulation directory and run eq_local.sh
    cd "$sim_dir" 
    
    # Run the equilibration script and wait for it to complete
    bash eq_local.sh
    
    # Check if the script succeeded
    if [ $? -eq 0 ]; then
        echo "Equilibration $i completed successfully"
    else
        echo "ERROR: Equilibration $i failed!"
        exit 1
    fi
    
    # Return to the original directory
    cd - > /dev/null
    
    echo ""
done

echo "=========================================="
echo "All equilibrations completed!"
echo "=========================================="