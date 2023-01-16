## Overview

## Running a simulation

Do the following to carry out the simulation described in the paper:

1. In the folder `ffa-p1/simulation/designs`, create a "design" file called `sim01.yml` with this information:

```
scratch_root: path/to/folder  
grid_size: 30
N_rep: TODO
loadings: [bump01, net01]
Ks: [2, 4]
deltas: [0.05, 0.1, 0.15]
signal_strengths: [sig01, sig02, sig03]
N_samp: [TODO]
```

[EXPLAIN EACH FIELD]

2. Run `simulation/setup-simulation.R sim01`. This script (i) creates directories for design `sim01`, and (ii) generates a YAML file for each configuration of the design. 

3. Run `simulation/simulate-data.R sim01`.