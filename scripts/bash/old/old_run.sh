#!/usr/bin/bash

## CLI UTILITY FOR MD RUN
## Make sure to activate conda env first

# VARS
# STORAGE_DIR="/media/vlucet/TrailCamST/TrailCamStorage"
STORAGE_DIR="/home/vlucet/Documents/WILDLab/mdtools/tests/test_images/"
BASE_FOLDER="/home/vlucet/Documents/WILDLab/repos/MDtest/git"
MD_FOLDER="$BASE_FOLDER/cameratraps"
MODEL="md_v5a.0.0.pt"
CHECKPOINT_FREQ=1000
THRESHOLD_FILTER=0.1
# THRESHOLD=0.0001

OVERWRITE_MD=true

OVERWRITE_LS=true

OVERWRITE_MD_CSV=true
OVERWRITE_EXIF_CSV=true
OVERWRITE_COMBINED=true

OVERWRITE_MD_COMBINED=false
OVERWRITE_EXIF_COMBINED=false

# Export python path
export PYTHONPATH="$PYTHONPATH:$MD_FOLDER"
export PYTHONPATH="$PYTHONPATH:$BASE_FOLDER/ai4eutils"
export PYTHONPATH="$PYTHONPATH:$BASE_FOLDER/yolov5"

# Start with empty array
DIRS=()

# Find all folders
echo "Finding all folders"
for FILE in $STORAGE_DIR/*; do
    [[ -d $FILE ]] && DIRS+=("$FILE")
done

# Print the list
# echo "Directory list:"
# printf "%s\n" "${DIRS[@]}"

OLD_DIR=$PWD

for DIR in "${DIRS[@]}"; do # "P072"; do 

    echo "*** RUNNING MD ***"
    
    RUN_DIR=$STORAGE_DIR/$(basename $DIR)
    echo "Running on directory: $RUN_DIR"

    OUTPUT_JSON="$(basename $DIR)_output.json"
    echo $OUTPUT_JSON
    
    CHECKPOINT_PATH="$(basename $DIR)_checkpoint.json"
    echo $CHECKPOINT_PATH

    if [ -f "$STORAGE_DIR/$OUTPUT_JSON" ] && [ "$OVERWRITE_MD" != true ]; then # if output exist, do nothing
        
        echo "Output file $OUTPUT_JSON exists, moving to the next folder"

    elif [ -f "$STORAGE_DIR/$CHECKPOINT_PATH" ]; then # else, if checkpoint exists, use it

        python $MD_FOLDER/detection/run_detector_batch.py \
            $MD_FOLDER/$MODEL $RUN_DIR $STORAGE_DIR/$OUTPUT_JSON \
            --output_relative_filenames --recursive \
            --checkpoint_frequency $CHECKPOINT_FREQ \
            --checkpoint_path $STORAGE_DIR/$CHECKPOINT_PATH \
            --quiet \
            --include_max_conf \
            --resume_from_checkpoint $STORAGE_DIR/$CHECKPOINT_PATH \
            --allow_checkpoint_overwrite #--threshold $THRESHOLD

    else # else, start new run
        python $MD_FOLDER/detection/run_detector_batch.py \
            $MD_FOLDER/$MODEL $RUN_DIR $STORAGE_DIR/$OUTPUT_JSON \
            --output_relative_filenames --recursive \
            --include_max_conf \
            --checkpoint_frequency $CHECKPOINT_FREQ \
            --checkpoint_path $STORAGE_DIR/$CHECKPOINT_PATH \
            --quiet #--threshold $THRESHOLD
    fi

    # echo "*** RUNNING MD CSV ***"

    # OUTPUT_CSV="$(basename $DIR)_output.csv"
    # echo $OUTPUT_CSV

    # if [ -f "$STORAGE_DIR/$OUTPUT_CSV" ] && [ "$OVERWRITE_MD_CSV" != true ]; then # if output exist, do nothing
        
    #    echo "Output file $OUTPUT_CSV exists, moving to the next folder"

    # else
    #     mdtools convert csv $STORAGE_DIR/$OUTPUT_JSON -re False -wc True
    # fi

    # echo "*** RUNNING EXIF CSV ***"

    # OUTPUT_EXIF_CSV="$(basename $DIR)_exif.csv"
    # echo $OUTPUT_EXIF_CSV

    # if [ -f "$STORAGE_DIR/$OUTPUT_EXIF_CSV" ] && [ "$OVERWRITE_EXIF_CSV" != true ]; then # if output exist, do nothing
        
    #    echo "Output file $OUTPUT_EXIF_CSV exists, moving to the next folder"

    # else
    #     mdtools readexif $STORAGE_DIR/$OUTPUT_JSON
    # fi

    # echo "*** RUNNING JOIN EXIF CSV TO MD CSV"
    
    # OUTPUT_COMBINED_CSV="$(basename $DIR)_combined.csv"
    # echo $OUTPUT_COMBINED_CSV

    # if [ -f "$STORAGE_DIR/$OUTPUT_COMBINED_CSV" ] && [ "$OVERWRITE_COMBINED" != true ]; then # if output exist, do nothing
        
    #     echo "Output file $OUTPUT_COMBINED_CSV exists, moving to the next folder"

    # else

    #     mdtools joinexif $STORAGE_DIR/$OUTPUT_CSV $STORAGE_DIR/$OUTPUT_EXIF_CSV $STORAGE_DIR/$OUTPUT_COMBINED_CSV

    # fi

    echo "*** RUNNING CONVERTER TO LS ***"

    OUTPUT_JSON_LS="$(basename $DIR)_output_ls.json"
    echo $OUTPUT_JSON_LS

    if [ -f "$STORAGE_DIR/$OUTPUT_JSON_LS" ] && [ "$OVERWRITE_LS" != true ]; then # if output exist, do nothing
        
        echo "Output file $OUTPUT_JSON_LS exists, moving to the next folder"

    else

        mdtools convert ls $STORAGE_DIR/$OUTPUT_JSON $RUN_DIR -ct $THRESHOLD_FILTER \
            -ru "data/local-files/?d=$(basename $STORAGE_DIR)/$(basename $DIR)" \
            --write-ls --write-csv --write-coco
    fi

done

# echo "*** COMBINING CSVs ***"

# if [ -f "$STORAGE_DIR/exif_combined.csv" ] && [ "$OVERWRITE_EXIF_COMBINED" != true ]; then
#     echo "EXIF combined file present"
# else
#     csvstack $STORAGE_DIR/*_exif.csv > $STORAGE_DIR/exif_combined.csv
# fi

# if [ -f "$STORAGE_DIR/md_combined.csv" ] && [ "$OVERWRITE_MD_COMBINED" != true ]; then
#     echo "MD combined file present"
# else
#     csvstack $STORAGE_DIR/*_output.csv > $STORAGE_DIR/md_combined.csv
# fi

cd $OLD_DIR
