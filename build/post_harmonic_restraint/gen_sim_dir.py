import os
import shutil
from pathlib import Path


base_sim_dir = Path("../../simulations/oep7_atg8e_system/integral/memb-1")
equil_dir = Path("/tank/abdolla/oep7/simulations/oep7_atg8e_system/integral/memb-1/no_restraint/")
harmonic_dir = base_sim_dir / "harmonic_restraint"
post_harmonic_dir = base_sim_dir / "post_harmonic_restraint"
current_dir = Path("./")

# Files to copy
system_rot_pdbs = [current_dir / f"protein_rot{i}.pdb" for i in range(1, 6+1)]
psf_file = harmonic_dir / "system.psf"
xsc_file = harmonic_dir / "final_system.xsc"

# Script/config files to copy
script_files = [
    equil_dir / "eq_local.sh",
    equil_dir / "run.sh",
    equil_dir / "system_eq.namd",
    equil_dir / "system_pull.namd"
]

# Create directories and copy files
for i in range(1, 7):
    # Create directory
    target_dir = post_harmonic_dir / str(i)
    target_dir.mkdir(parents=True, exist_ok=True)
    print(f"Created directory: {target_dir}")
    
    # Copy rotated system PDB
    shutil.copy2(system_rot_pdbs[i-1], target_dir / "system.pdb")
    print(f"  Copied {system_rot_pdbs[i-1].name} as system.pdb")
    
    # Copy PSF file
    shutil.copy2(psf_file, target_dir / "system.psf")
    print(f"  Copied system.psf")
    
    # Copy XSC file
    shutil.copy2(xsc_file, target_dir / "system.xsc")
    print(f"  Copied final_system.xsc")
    
    # Copy script/config files
    for script_file in script_files:
        if script_file.exists():
            shutil.copy2(script_file, target_dir / script_file.name)
            print(f"  Copied {script_file.name}")
        else:
            raise FileNotFoundError(f"  WARNING: {script_file} not found, skipping")
    
    print()

print("Setup complete! Created 6 simulation directories with rotated protein orientations.")