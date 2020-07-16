# 3-color Single-Molecule FRET Data Analysis

IDL and MATLAB scripts for analyzing 3-color single-molecule FRET data.

Note: Microsoft Windows is required to run IDL.

## Histogram / Colocalization Analysis

### Generate Mapping between 3 channels

A mapping file provides a mapping function between (x, y) coordinates of 3 emission channels. A short movie of fluorescent beads is used to generate the mapping file and is provided in `example\beads.pma`.

To generate a mapping file for FRET histogram or colocalization analysis:

1. In IDL, open `histograms\idl\maketiff.pro`.

2. Replace line 25 with the path to the folder containing the bead movie. For example:

```
dir = "X:\singlemolecules\smfret3color\example\"
```

3. Compile and run the script. A file named `beads.tiff` will be generated under the same folder.

4. In IDL, open `histograms\idl\calc_mapping2.pro`.

5. Replace the quoted region on line 39 with the same path as Step 2.

6. Run the script. 

7. In our miscroscope, the field of view is spectrally separated into 3 colors and projected onto three vertical sections on the camera. We begin by mapping the left and the middle sections. The IDL terminal will prompt you to select three pairs of spots, where each pair should correspond to the same spot in the original field of view. To select the first pair, use keys D/F/R/C to move the left circle so it's centered on the desired spot on the left section; use keys G/H/Y/B to move the right circle so it's centered on the desired spot on the middle section. To save the current pair, press 'S'.

8. Repeat step 7 two times to select the next two pairs. A file named `beads.coef` should be generated. Note: To optimize the number of spots that are successfully mapped, we recommend spread out the three pairs as much as possible, such as ones located at the top right, middle left and bottom right.

10. Run `histograms\idl\nxgn1_cm_35.pro`. `beads_35.map` will be generated.

11. Next we will create a mapping file for the left and the right sections. Repeat steps 6-8, except this time you will select spots from the left and the right channels.

12. To generate the mapping file, run `histograms\idl\nxgn1_cm_37.pro`. `beads_37.map` should appear.

### Process raw data into time trajectories of single-molecule fluorescence intensity

1. In IDL, open `ana_all_3ch_ALEX.pro`, `p_nxgn1_ap_3ch_ALEX.pro` and `p_nxgn1_ffp_3ch_alex_MattThreeColor.pro` under `histograms\idl`

2. Replace line 240 with path to the `beads_35.map` mapping file you generated in the previous section.

3. Replace line 247 with path to `beads_37.map`.

4. Replace line 8 with path to the parent folder that contains data in its subfolders. 

5. Compile all and run. All unprocessed data stored under the subfolders will be processed. For a movie named `x.pma`, this step will generate `x_ave.tif`, `x_selected.tif`, `x.pks`, `x_bsl.traces`, `x_raw.traces`.

### Plotting a FRET histogram

1. In MATLAB, open `histogram\matlab\histogram_maker_3c3a_ver2.m`

2. Make sure the correction paramters are correct. Current parameters are for Cy3, Cy5, Cy7.

3. Run the script. Enter data directory and time unit as prompted.

4. Set intensity cutoffs for each fluorophore by selecting the desired intensity range.

5. Done! FRET histogram for all three FRET pairs will be displayed and automatically saved as images as well as raw values.

## Trace Analysis

### Generate Mapping

1. In IDL, open `traces\mapping_maker_smb_3.pro`.

2. Select `beads.pma` when prompted.

3. Select 3 triplets of spots on the image, visually inspect to make sure the correspond to the same spot in the original field of view. Adjust if needed.

4. Press enter to finish. This should generate a file named `beads.map`.

### Process raw data into time trajectories of single-molecule fluorescence intensity

1. In IDL, open `smb_analyze_all_3alex.pro`, `smb_peak_location_maker_3color_3alex.pro`, and `smb_peak_trace_maker_3color_3alex.pro` under the `traces\` folder.

2. In `smb_analyze_all_3alex.pro`, replace line 6 with path to the data directory. Then replace line 7 with path to the mapping file.

3. Compile all and run. For a movie named `x.pma`, this step should generate `x_ave_first.tif`, `x_ave_second.tif`, `x_ave_third`

### Analyze single-molecule time trajectories

1. Open `traces\matlab\smb_tirM_3alex_2020.m` in MATLAB.

2. Modify path and filename as needed.

3. Run and follow instructions in the command window.





