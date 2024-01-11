
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ROF Camera Trap Data Analysis Research Compedium

<!-- [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/StewartWILDlab/rofcamtrap/main?urlpath=rstudio) -->

Prerequisites:

- docker
- nvidia-container-toolkit

## Main Workflow

1.  At the terminal, clone this repository.

``` bash
git clone https://github.com/StewartWILDlab/rofcamtrap
```

2.  Build the docker image of the computing environment, by running the
    build script. This will also build the apptainer image needed on
    HPC.

``` bash
rofcamtrap/dockerfiles/build.sh
```

3.  Run docker image, with the proper volumes. We currently have two
    separate storage volumes, for each of the two camera retrievals that
    took place. We also make sure to hook the `rofcamtrap` folder as a
    volume.

``` bash
# -e DISABLE_AUTH=true --shm-size 50G
docker run \
  -v "$(pwd):/workspace/rofcamtrap" \
  -v "/media/vlucet/TrailCamST/TrailCamStorage:/workspace/storage/TrailCamStorage" \
  -v "/media/vlucet/TrailCamST/TrailCamStorage_2:/workspace/storage/TrailCamStorage_2" \
  --gpus all \
  -it rofcamtrap
```

4.  Activate ENV, then run mega detector on images using the bash
    script.

``` bash
mamba activate cameratraps-detector
rofcamtrap/scripts/bash/camtrap.sh \
  -b "/workspace/git" \
  -s "/workspace/storage/TrailCamStorage_2" \
  -m "/workspace/models/md_v5a.0.0.pt" \
  -o "/workspace/rofcamtrap/1_MegaDetector/0_outputs/TrailCamStorage_2" \
  md
```

5.  Run the repeat detector using the bash script, and remove all
    instances of trues positives.

``` bash
rofcamtrap/scripts/bash/camtrap.sh \
  -b "/workspace/git" \
  -s "/workspace/storage/TrailCamStorage_2" \
  -i "/workspace/rofcamtrap/1_MegaDetector/0_outputs/TrailCamStorage_2" \
  repeat-detect
```

6.  Patch MD’s output with the repeat detect results.

``` bash
rofcamtrap/scripts/bash/camtrap.sh \
  -b "/workspace/git" \
  -s "/workspace/storage/TrailCamStorage_2" \
  -i "/workspace/rofcamtrap/1_MegaDetector/0_outputs/TrailCamStorage_2" \
  -o "/workspace/rofcamtrap/1_MegaDetector/1_outputs_no_repeats/TrailCamStorage_2" \
  repeat-remove
```

7.  Optionally, write out the visualizations of the detections.

``` bash
rofcamtrap/scripts/bash/camtrap.sh \
  -b "/workspace/git" \
  -s "/workspace/storage/TrailCamStorage_2" \
  -i "/workspace/rofcamtrap/1_MegaDetector/1_outputs_no_repeats/TrailCamStorage_2" \
  -o "/workspace/rofcamtrap/1_MegaDetector/2_visualize/TrailCamStorage_2" \
  viz
```

8.  Switch environments

``` bash
mamba deactivate 
cd mdtools
poetry shell
cd ../
```

9.  Convert to coco and ls \[and 3rd format?\].

``` bash
mamba deactivate 
cd mdtools
poetry shell
cd ../
rofcamtrap/scripts/bash/camtrap.sh \
  -b "/workspace/git" \
  -s "/workspace/storage/TrailCamStorage_2" \
  -i "/workspace/rofcamtrap/1_MegaDetector/1_outputs_no_repeats/TrailCamStorage_2" \
  -o "/workspace/rofcamtrap/2_LabelStudio/0_inputs/TrailCamStorage_2" \
  repeat-convert
```

10. Crop annotations.

``` bash
rofcamtrap/scripts/bash/camtrap.sh \
  -b "/workspace/git" \
  -s "/workspace/storage/TrailCamStorage_2" \
  -i "/workspace/rofcamtrap/2_LabelStudio/0_inputs/TrailCamStorage_2" \
  crop
```

## Label studio outputs

1.  Enter the container running the label studio app and output ths
    number of projects

``` bash
docker exec -it label-studio-app-1 bash
curl -X GET http://localhost:8080/api/projects/?page_size=1000 -H 'Authorization: Token 3135fdd1f4a5b9b3630b69011ec4d70e7800c41d' -o files/outputs/project_counts.json
```

2.  On the instance outside the container, run the Python script to
    extract projects id

``` python
import json

with open('data/outputs/project_counts.json', 'r') as file:
  data = json.load(file)
  
ids = [data['results'][i]['id'] for i in range(len(data['results']))]

with open('data/outputs/project_ids.txt', 'w') as file:
  for the_id in ids:
        file.write(str(the_id) + '\n')
```

3.  Back in the container

``` bash
arr=(192 191 190 189 188 187 186 185 184 183 182 181 180 179 178 177 176 175 174 173 172 171 170 87 86 85 84 83 82 81 80 79 78 77 76 75 74 73 72 65 64 63 62 61 60 59 58 57 55 54 53 52 51 50 49 48 47 46 44 43 42 41 40 39 37 35 33 32 31 30 28 25 23 21 20 19 18 17 16 15 13 10);
for id in ${arr[@]}; do         
  # url="http://localhost:8080/api/projects/${id}/export?exportType=JSON&download_all_tasks=true";
  url="http://localhost:8080/api/projects/${id}/export?exportType=JSON";
  curl -X GET "$url" -H 'Authorization: Token 3135fdd1f4a5b9b3630b69011ec4d70e7800c41d'\
    -o "files/outputs/ls/output_file_$id.json";
done
```

4.  Back outside the container, check for file numbers

``` bash
ls data/outputs/ls # 81 Jan 11 2024
```

5.  Copy to local machine

``` bash
scp -i ssh_key/arbutus_def_fstewart_prod 'ubuntu@206.12.94.17:~/data/outputs/ls/*' rofcamtrap/2_LabelStudio/1_outputs_downloaded/
```

6.  Process those outputs

``` bash
rofcamtrap/scripts/bash/camtrap.sh \
  -i "/workspace/rofcamtrap/2_LabelStudio/1_outputs_downloaded/" \
  -o "/workspace/rofcamtrap/2_LabelStudio/2_outputs_processed" \
  post
```

## Classifier training workflow

On beluga, we use the apptainer image instead.

``` bash
. /workspace/conda/etc/profile.d/conda.sh 
. /workspace/conda/etc/profile.d/mamba.sh
PATH="$PATH:$HOME/.local/bin"
mamba activate cameratraps-detector
rofcamtrap/scripts/bash/camtrap.sh -b "/workspace/git" -s "/workspace/storage/my_passport_images" -m "/workspace/models/md_v5a.0.0.pt" md

$ mkdir -p /scratch/$USER/apptainer/{cache,tmp}
$ export APPTAINER_CACHEDIR="/scratch/$USER/apptainer/cache"
$ export APPTAINER_TMPDIR="/scratch/$USER/apptainer/tmp"

salloc --time=00:05:00 --mem=4G --ntasks=1 --gpus-per-task=1 --cpus-per-task=1 --account=rrg-fstewart

apptainer shell --nv -C -B "$(pwd):/workspace/rofcamtrap"  -B "/media/vlucet/TrailCamST/TrailCamStorage:/workspace/storage/TrailCamStorage"  -B "/media/vlucet/My Passport/Images:/workspace/storage/my_passport_images" rofcamtrap.sif

apptainer shell --nv -C -B "$(pwd):/workspace/rofcamtrap" -B "/home/vlucet/projects/rrg-fstewart/vlucet:/workspace/project/" rofcamtrap.sif
```

### Species classifier

We need to download the models… TBA

### False detections classifier

## LabelStudio instance setup

## Labelme? WildTrax?

## Reports

The **reports** directory currently contains the `GnC_report` folder
wich is structured as such:

- [:file_folder: paper](/analysis/paper): Quarto source document for
  manuscript. Includes code to reproduce the figures and tables
  generated by the analysis. It also has a rendered version,
  `paper.docx`, suitable for reading (the code is replaced by figures
  and tables in this file)
- [:file_folder: data](/analysis/data): Data used in the analysis.
- [:file_folder: figures](/analysis/figures): Plots and other
  illustrations
- [:file_folder:
  supplementary-materials](/analysis/supplementary-materials):
  Supplementary materials including notes and other documents prepared
  and collected during the analysis.

## How to run in your browser or download and run locally

This research compendium has been developed using the statistical
programming language R. To work with the compendium, you will need
installed on your computer the [R
software](https://cloud.r-project.org/) itself and optionally [RStudio
Desktop](https://rstudio.com/products/rstudio/download/).

You can download the compendium as a zip from from this URL:
[master.zip](/archive/main.zip). After unzipping: - open the `.Rproj`
file in RStudio - run `devtools::install()` to ensure you have the
packages this analysis depends on (also listed in the
[DESCRIPTION](/DESCRIPTION) file). - finally, open
`analysis/paper/paper.Rmd` and knit to produce the `paper.docx`, or run
`rmarkdown::render("analysis/paper/paper.qmd")` in the R console

### Licenses

TBD

<!-- **Text and figures :**  [CC-BY-4.0](http://creativecommons.org/licenses/by/4.0/) 
&#10;**Code :** See the [DESCRIPTION](DESCRIPTION) file
&#10;**Data :** [CC-0](http://creativecommons.org/publicdomain/zero/1.0/) attribution requested in reuse -->

### Contributions

We welcome contributions from everyone. Before you get started, please
see our [contributor guidelines](CONTRIBUTING.md). Please note that this
project is released with a [Contributor Code of Conduct](CONDUCT.md). By
participating in this project you agree to abide by its terms.

### How to cite

Please cite this compendium as:

> Lucet, Valentin; Stewart, Frances et al., (2024). *Compendium of R
> code and data for ROF Camera Trap Data Analysis - Preliminary Report*.
> Accessed 11 Jan 2024. Online at <https://doi.org/xxx/xxx>

### Notes

``` bash
for FILE in project*
    mdtools postprocess --write-csv $FILE
end
```

<!-- This repository contains the data and code for our paper:
&#10;> Authors, (YYYY). _ROF Camera Trap Data Analysis - Preliminary Report_. Name of journal/book <https://doi.org/xxx/xxx>
&#10;Our pre-print is online here:
&#10;> Authors, (YYYY). _ROF Camera Trap Data Analysis - Preliminary Report_. Name of journal/book, Accessed 11 Jan 2024. Online at <https://doi.org/xxx/xxx> -->
