import subprocess
from pathlib import Path


base_path = Path("./OEP7/Simulations/integral")
tcl_source = Path("sasa.tcl").resolve()#making tcl file bc putting in big string 2 messy blehh

output_dir = Path("./sasa_for_system_water_res")
output_dir.mkdir(exist_ok=True)


# memb-1 to memb-4
for i in range(1, 5):
    sim_dir = base_path / f"memb-{i}"
    
    if not sim_dir.exists():#error catching in case
        print(f"Skipping memb-{i}: directory not found")
        continue
    
    print(f"Processing memb-{i}...")
    
    output_file = output_dir / f"memb-{i}.dat"
    try:
        with open(output_file,'w') as f:
            subprocess.run(
                ["vmd", "-dispdev", "text", "-e", str(tcl_source)],
                cwd=str(sim_dir),
                check=True,
                stdout=f,
                stderr=subprocess.PIPE,
            )
        print(f"Done. Output saved to {output_file}")
    except subprocess.CalledProcessError as e:
        print(f"Error running VMD for memb-{i}: {e}")


print("\nDone (python)")
exit()