import re
import numpy as np
from pathlib import Path
from typing import Tuple

def extract_sasa_from_dat(
    dat_file: Path,
    frame_pattern: str = r'^\s*(\d+)\s+([\d.]+)'
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Extract frame numbers and SASA values from a .dat file.
    
    Args:
        dat_file : Path
            Path to the .dat file containing SASA output
        frame_pattern : str, optional
            Regex pattern to match frame and SASA values
        
    Returns:
        frames : np.ndarray
            Array of frame numbers
        sasa_values : np.ndarray
            Array of SASA values in A^2 
    """
    frames = []
    sasa_values = []
    
    with open(dat_file, 'r') as f:
        for line in f:
            match = re.search(frame_pattern, line)
            if match:
                frame = int(match.group(1))
                sasa = float(match.group(2))
                frames.append(frame)
                sasa_values.append(sasa)
    
    return np.array(frames), np.array(sasa_values)

def get_sim_time_ns(memb_dir:str):
    """
    Find the last .out file and extract total simulation time
    """

    out_files = sorted(memb_dir.glob("system_run*.out"))
    if not out_files:
        raise FileNotFoundError(f"No out files found for", str(memb_dir))
    
    last_out = out_files[-1]
    
    # Read last few lines to find "AT STEP"
    with open(last_out, 'r') as f:
        lines = f.readlines()
        for line in reversed(lines[-20:]):  # check last 20 lines
            if "AT STEP" in line:
                match = re.search(r'AT STEP (\d+)', line)
                if match:
                    last_step = int(match.group(1))
                    time_ns = 2 * last_step * 1e-6  # 2 fs timestep
                    return time_ns
