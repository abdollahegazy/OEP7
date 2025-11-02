import sys; sys.path.append("/home/abdolla/anaconda3/lib/python3.12/site-packages")
from vmd import atomsel, molecule # type: ignore
from pathlib import Path
import numpy
from tqdm import tqdm

import logging
logger = logging.getLogger(__name__); logger.setLevel(logging.INFO)
stream_handler = logging.StreamHandler(stream=sys.stdout)
formatter = logging.Formatter("[%(levelname)s] %(message)s")
stream_handler.setFormatter(formatter)
logger.addHandler(stream_handler)

BASE_PATH = Path("../.OEP7/Simulations/integral")
OUTPUT_DIR = Path("./test")
OUTPUT_DIR.mkdir(exist_ok=True)
STRIDE = 1000
MEMBRANE_IDX = [1]

def compute_sasa():
    all_sasa = {}

    for i in MEMBRANE_IDX:
        sim_dir = BASE_PATH / f"memb-{i}"

        if not sim_dir.exists(): raise FileNotFoundError(f"Skipping memb-{i}: directory not found");
        logger.info(f"Processing memb-{i}...")

        psf_file = sim_dir / "system.psf"
        pdb_file = sim_dir / "system.pdb"
        
        molid = molecule.load('psf', str(psf_file))
        molecule.read(molid, 'pdb', str(pdb_file))
        
        dcd_files = sorted(sim_dir.glob("system_run*.dcd"))
        print(f"\tFound {len(dcd_files)} DCD files")
        
        for dcd_file in dcd_files:
            molecule.read(molid, 'dcd', str(dcd_file), stride=STRIDE, waitfor=-1)
        
        nframes = molecule.numframes(molid)
        print(f"\tLoaded {nframes} frames")
        

        system = atomsel('not water and not ions', molid=molid)
        sel_motif = "protein and resid 19 to 24"
        motif = atomsel(sel_motif,molid=molid)

        sasa_vals = []
        for frame in tqdm(range(0,nframes),desc=f'Processing frames (memb-{i})'):

            system.frame = frame
            motif.frame  = frame
            # molecule.set_frame(molid, frame).  verified same as above but but be slower than above?

            sasa = system.sasa(srad=1.4,restrict=motif)
            sasa_vals.append(sasa)
        
        all_sasa[f"memb-{i}"] = numpy.array(sasa_vals,dtype=float)


        molecule.delete(molid)
        
    numpy.savez(OUTPUT_DIR / "motif_sasa.npz", **all_sasa)

if __name__ == "__main__":
    compute_sasa()

exit()