i loaded pdbs of atge and ope7 from duncan
atg8e from duncan dir in slack oep7 from integral memb-1 (lowest PG)
into vmd and made protein in position i wanted
then saved memrabne (no water or ions) and atg8e positioned, then combiend using packmol (refer to temp.inp),
then loaded into vmd to put protein above cell (but apparently it wouldnt have mattered if above/below bc pbc)
then i ran solvate_and_ioninize and patch_memrabe to get ./blah/system_patched.psf and pdb and system.xsc

ABOVE IS OLD


in ./new_solvation i just used a script duncan gave using topotools. much easier and everything seems perfects
EVERYTHIBG NEEDED IS IN  SOLVATE AND IOINIZE