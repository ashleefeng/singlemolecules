# 3-color Single-Molecule FRET Data Analysis

scripts for analyzing 3-color single-molecule FRET data collected on a TIRF microscope

## Histogram / Colocalization Analysis

### Generate Mapping between 3 channels

A mapping file provides a reference so the program knows which fluorescent spots come from the same molecule. We generate the mapping from a short movie (ex. 100 ms per frame, 30 frames total) of fluorescent beads.

To generate a mapping file for FRET histogram or colocalization analysis:

1. In IDL, open `histograms\idl\maketiff.pro`.

2. Replace the quoted region on line 25 with the path of the folder that contains your bead movie. For example:

```
dir = "X:\singlemolecules\smfret3color\example\"
```

3. Run the script. A file named `beads.tiff` will be generated in the same folder that contains your bead movie.

4. In IDL, open `histograms\idl\calc_mapping2.pro`.

5. Replace the quoted region on line 39 with the same path as Step 2.

6. Run the script. 

7. Let's first map the left and the middle channels. The IDL terminal will prompt you to select three pairs of spots, where each pair should correspond to the same molecule. To select the first pair, use keys D/F/R/C to move the left circle so it's centered on the desired spot on the left channel; use keys G/H/Y/B to move the right circle so it's centered on the desired spot on the middle channel. To save the current pair, press 'S'.

8. Repeat step 7 two times to select the next two pairs. `beads.coef` will be generated. Note: To optimize the fraction of spots that are successfully mapped, I recommend choosing spots that are far away from each other, such as ones located at the top right, middle left and bottom right.

10. Run `histograms\idl\nxgn1_cm_35.pro`. `beads_35.map` will be generated.

11. Now let's map the left and the right channels. Repeat steps 6-8, except this time you will select spots from the left and the right channels.

12. To generate the mapping file, run `histograms\idl\nxgn1_cm_37.pro`. `beads_37.map` should appear.


## Trace Analysis