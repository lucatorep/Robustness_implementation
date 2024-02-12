# Robustness implementation in your data analysis
<br />

_NOTE._ This collection of scripts and macros has been developed for the following publication:
Torello Pianale, L., Caputo, F. & Olsson, L. Four ways of implementing robustness quantification in strain characterisation. 
Biotechnol Biofuels 16, 195 (2023). https://doi.org/10.1186/s13068-023-02445-6

<br />
Collection of scripts to analyse: 

- BioLector I data coming from multiple screenings. For analysing of individual screenings, please check ScEnSor Kit Scripts (https://github.com/lucatorep/ScEnSor-Kit-Scripts).
- Flask data coming from Scientific Bioprocessing biomass monitoring, but easily adapted to other setups + HPLC data.
- Microscopy images (preprocessing and biosensor output).
  
<br />

Getting started:

1. Install R (https://cran.r-project.org/), RStudio (https://posit.co/download/rstudio-desktop/) and then the RMarkdown package in R (https://rmarkdown.rstudio.com/). No need to pre-install other packages needed for the scripts as they will be installed automatically (if they are not already).
2. Install Fiji (Fiji: https://imagej.net/software/fiji/downloads), if microscopy images need to be analysed.
3. Always check the data organisation in the example files provided.
4. Follow the directions in the scripts and macros (details before each chunk and important sections of scripts).
5. Make changes upon need (replace grouping variables, way of importing data, etc.).
<br />

----

Luca Torello Pianale, lucat@chalmers.se

Chalmers University of Technology, Department of Life Sciences, Industrial Biotechnology Division. 

Created: October, 2023.

The scripts were tested with: 
1. R Version 4.3.1 (2021-11-01) 
2. RStudio (2021.09.2 Build 382) 
3. ImageJ 1.53t 

Acknowledgment of support: This material is based upon work supported by the Novo Nordisk Foundation grant DISTINGUISHED INVESTIGATOR 2019 - Research within biotechnology-based synthesis & production (#0055044). 
