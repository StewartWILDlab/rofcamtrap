#!/usr/bin/bash

# ------------------------------------------------------------------

## CLI UTILITY FOR Camera trap workflow
## WARNING: Make sure to activate conda env first

# ------------------------------------------------------------------

# Declare variables first

STORAGE_DIR=""
BASE_FOLDER=""
INPUT_DIR=""
OUTPUT_DIR=""

# ------------------------------------------------------------------

print_main_usage(){
cat <<EOM
    Usage: camtrap.sh [-s storage_dir] [-b base_folder] <subcommand>

    CLI UTILITY FOR Camera trap workflow
    WARNING: Make sure to activate conda env first

    Options:
      -s    Set the storage directory for camera trap images.
      -b    Set the base folder for the workflow.
      -m    Set the path to model file to use.
      -o    Set the output folder.
      -h    Prints usage.

    Subcommands:
      all      Run the entire camera trap workflow.
      prep     Run the preparation steps for the workflow.
      md       Run the megadetector (MD) step.
      convert  Run the converter to LS step.
      repeat   Run the repeat detection and conversion step.

    Examples:
      camtrap.sh -s /path/to/storage -b /path/to/base_folder all
      camtrap.sh -s /path/to/storage -b /path/to/base_folder prep
      camtrap.sh -s /path/to/storage -b /path/to/base_folder md
      camtrap.sh -s /path/to/storage -b /path/to/base_folder convert
      camtrap.sh -s /path/to/storage -b /path/to/base_folder repeat
EOM
}

# ------------------------------------------------------------------

export_default_vars(){

    MD_FOLDER="$BASE_FOLDER/MegaDetector"
    CHECKPOINT_FREQ=1000
    THRESHOLD_FILTER=0.1

    IOU_THRESHOLD=0.85
    NDIR_LEVEL=0

    OVERWRITE_MD=true
    OVERWRITE_LS=true
    OVERWRITE_MD_CSV=true
    OVERWRITE_EXIF_CSV=true

    OVERWRITE_COCO_REPEAT=false
    OVERWRITE_LS_REPEAT=false

    OVERWRITE_COMBINED=true
    OVERWRITE_MD_COMBINED=false
    OVERWRITE_EXIF_COMBINED=false

    export PYTHONPATH="$PYTHONPATH:$MD_FOLDER"
    export PYTHONPATH="$PYTHONPATH:$BASE_FOLDER/ai4eutils"
    export PYTHONPATH="$PYTHONPATH:$BASE_FOLDER/yolov5"

    # STORAGE_DIR="/media/vlucet/TrailCamST/TrailCamStorage"
    # STORAGE_DIR="/home/vlucet/Documents/WILDLab/mdtools/tests/test_images/"
    # STORAGE_DIR="/media/vlucet/My Passport/Images"
    # BASE_FOLDER="/home/vlucet/Documents/WILDLab/repos/MDtest/git"
    # MODEL="md_v5a.0.0.pt"
    # THRESHOLD=0.0001
}

print_vars(){

    echo ""
    echo "Variables for MD: "
    echo "      STORAGE_DIR = $STORAGE_DIR"
    echo "      BASE_FOLDER = $BASE_FOLDER"
    echo "      MD_FOLDER = $MD_FOLDER"
    echo "      MODEL PATH = $MODEL_PATH"
    echo "      CHECKPOINT_FREQ = $CHECKPOINT_FREQ"
    echo "      THRESHOLD_FILTER = $THRESHOLD_FILTER"
    echo "      IOU_THRESHOLD = $IOU_THRESHOLD"
    echo "      NDIR_LEVEL = $NDIR_LEVEL"
    echo ""
    echo "Variables for workflow: "
    echo "      OVERWRITE_MD = $OVERWRITE_MD"
    echo "      OVERWRITE_LS = $OVERWRITE_LS"
    echo "      OVERWRITE_MD_CSV = $OVERWRITE_MD_CSV"
    echo "      OVERWRITE_EXIF_CSV = $OVERWRITE_EXIF_CSV"
    # echo "      OVERWRITE_COMBINED = $OVERWRITE_COMBINED"
    # echo "      OVERWRITE_EXIF_COMBINED = $OVERWRITE_EXIF_COMBINED"
    echo ""
}

crawl_dirs(){

    # Start with empty array
    DIRS=()

    # Find all folders
    echo "Finding all folders"
    for FILE in "$STORAGE_DIR"/*; do
        echo "$FILE"
        if [[ "$FILE" == *"repeat"* ]];then
            continue
        fi
        [[ -d "$FILE" ]] && DIRS+=("$FILE")
    done

    echo "      Directory list:"
    printf "      %s\n" "${DIRS[@]}"
    echo ""

    export DIRS
}

run_prep(){
    export_default_vars
    print_vars
    crawl_dirs
}

run_all(){
    run_prep
    run_md
    run_convert
}

run_md(){

    for DIR in "${DIRS[@]}"; do # "P072"; do # @ 0

        echo "*** RUNNING MD ***"

        RUN_DIR="$STORAGE_DIR/$(basename "$DIR")"
        echo "Running on directory: $RUN_DIR"

        OUTPUT_JSON="$(basename "$DIR")_output.json"
        echo $OUTPUT_JSON

        CHECKPOINT_PATH="$(basename "$DIR")_checkpoint.json"
        echo $CHECKPOINT_PATH

        if [ -f "$OUTPUT_DIR/$OUTPUT_JSON" ] && [ "$OVERWRITE_MD" != true ]; then # if output exist, do nothing

            echo "Output file $OUTPUT_JSON exists, moving to the next folder"

        elif [ -f "$STORAGE_DIR/$CHECKPOINT_PATH" ]; then # else, if checkpoint exists, use it

            python $MD_FOLDER/detection/run_detector_batch.py \
                "$MODEL_PATH" "$RUN_DIR" "$OUTPUT_DIR/$OUTPUT_JSON" \
                --output_relative_filenames --recursive \
                --checkpoint_frequency $CHECKPOINT_FREQ \
                --checkpoint_path "$STORAGE_DIR/$CHECKPOINT_PATH" \
                --quiet \
                --include_max_conf \
                --resume_from_checkpoint "$STORAGE_DIR/$CHECKPOINT_PATH" \
                --allow_checkpoint_overwrite #--threshold $THRESHOLD

        else # else, start new run
            python $MD_FOLDER/detection/run_detector_batch.py \
                "$MODEL_PATH" "$RUN_DIR" "$OUTPUT_DIR/$OUTPUT_JSON" \
                --output_relative_filenames --recursive \
                --include_max_conf \
                --checkpoint_frequency $CHECKPOINT_FREQ \
                --checkpoint_path "$STORAGE_DIR/$CHECKPOINT_PATH" \
                --quiet #--threshold $THRESHOLD
        fi

    done
}

run_detect_repeat(){

    for DIR in "${DIRS[@]}"; do # "P072"; do # @ 0

        echo "*** RUNNING REPEAT DETECT ***"

        RUN_DIR="$STORAGE_DIR/$(basename "$DIR")"
        echo "Running on directory: $RUN_DIR"

        INPUT_JSON="$(basename $DIR)_output.json"
        echo $INPUT_JSON

        OUTPUT_BASE="$(basename $DIR)_repeat"
        echo $OUTPUT_BASE

        python $MD_FOLDER/api/batch_processing/postprocessing/repeat_detection_elimination/find_repeat_detections.py \
            "$INPUT_DIR/$INPUT_JSON" --imageBase "$RUN_DIR" \
            --outputBase "$STORAGE_DIR/$OUTPUT_BASE" \
            --confidenceMin $THRESHOLD_FILTER \
            --iouThreshold $IOU_THRESHOLD \
            --nDirLevelsFromLeaf $NDIR_LEVEL

    done
}

run_remove_repeat(){

    for DIR in "${DIRS[@]}"; do # "P072"; do # @ 0

        echo "*** RUNNING REPEAT REMOVE ***"

        RUN_DIR="$STORAGE_DIR/$(basename "$DIR")"
        echo "Running on directory: $RUN_DIR"

        INPUT_JSON="$(basename $DIR)_output.json"
        echo $OUTPUT_JSON

        OUTPUT_JSON="$(basename $DIR)_output_norepeats.json"
        echo $OUTPUT_JSON

        OUTPUT_BASE="$(basename $DIR)_repeat"
        echo $OUTPUT_BASE
        FILT_DIR=$(ls -td "$STORAGE_DIR/$OUTPUT_BASE"/*/ | head -1)
        echo $FILT_DIR

        python $MD_FOLDER/api/batch_processing/postprocessing/repeat_detection_elimination/remove_repeat_detections.py \
            "$INPUT_DIR/$INPUT_JSON" "$OUTPUT_DIR/$OUTPUT_JSON" $FILT_DIR

    done
}

# ------------------------------------------------------------------

run_convert_repeat(){

    OLD_DIR=$PWD

    for DIR in "${DIRS[@]}"; do

        echo "*** RUNNING REPEAT CONVERTER TO LS ***"

        RUN_DIR=$STORAGE_DIR/$(basename $DIR)
        echo "Running on directory: $RUN_DIR"

        OUTPUT_JSON_REPEAT="$(basename $DIR)_output_norepeats.json"
        echo $OUTPUT_JSON_REPEAT

        OUTPUT_JSON_LS_REPEAT="$(basename $DIR)_output_ls_norepeats.json"
        echo $OUTPUT_JSON_LS

        if [ -f "$STORAGE_DIR/$OUTPUT_JSON_LS_REPEAT" ] && [ "$OVERWRITE_LS_REPEAT" != true ]; then # if output exist, do nothing

            echo "Output file $OUTPUT_JSON_LS_REPEAT exists, moving to the next folder"

        else

            mdtools convert ls $STORAGE_DIR/$OUTPUT_JSON_REPEAT $RUN_DIR -ct $THRESHOLD_FILTER \
                -ru "data/local-files/?d=$(basename $STORAGE_DIR)/$(basename $DIR)" \
                --write-ls --repeat --write-csv
        fi

    done

    # for DIR in "${DIRS[@]}"; do
    #     echo "*** RUNNING REPEAT CONVERTER TO COCO ***"
    #     RUN_DIR=$STORAGE_DIR/$(basename $DIR)
    #     echo "Running on directory: $RUN_DIR"
    #     OUTPUT_JSON_REPEAT="$(basename $DIR)_output_norepeats.json"
    #     echo $OUTPUT_JSON_REPEAT
    #     OUTPUT_COCO_REPEAT="$(basename $DIR)_output_coco_norepeats.json"
    #     echo $OUTPUT_COCO_REPEAT
    #     if [ -f "$STORAGE_DIR/$OUTPUT_COCO_REPEAT" ] && [ "$OVERWRITE_COCO_REPEAT" != true ]; then # if output exist, do nothing
    #         echo "Output file $OUTPUT_COCO_REPEAT exists, moving to the next folder"
    #     else
    #         mdtools convert cct $STORAGE_DIR/$OUTPUT_JSON_REPEAT $RUN_DIR --write-coco --repeat
    #     fi
    # done

    cd $OLD_DIR
}

run_convert(){

    OLD_DIR=$PWD

    for DIR in "${DIRS[@]}"; do

        echo "*** RUNNING CONVERTER TO LS ***"

        RUN_DIR=$STORAGE_DIR/$(basename $DIR)
        echo "Running on directory: $RUN_DIR"

        OUTPUT_JSON="$(basename $DIR)_output.json"
        echo $OUTPUT_JSON

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

    cd $OLD_DIR
}

# ------------------------------------------------------------------

run_viz(){

    for DIR in "${DIRS[@]}"; do # "P072"; do # @ 0

        echo "*** RUNNING Viz ***"

        RUN_DIR="$STORAGE_DIR/$(basename "$DIR")"
        echo "Running on directory: $RUN_DIR"

        OUTPUT_JSON="$(basename "$DIR")_output.json"
        echo $OUTPUT_JSON

        OUTPUT_BASE="$(basename $DIR)_repeat"
        echo $OUTPUT_BASE

        python $MD_FOLDER/md_visualization/visualize_detector_output.py ""


    done
}

# ------------------------------------------------------------------

while getopts ":s:b:m:i:o:h:" opt; do
  case ${opt} in
    s )
      STORAGE_DIR=$OPTARG
      ;;
    b )
      BASE_FOLDER=$OPTARG
      ;;
    m )
      MODEL_PATH=$OPTARG
      ;;
    i )
      INPUT_DIR=$OPTARG
      ;;
    o )
      OUTPUT_DIR=$OPTARG
      ;;
    h )
      print_main_usage
      ;;
    \? )
      echo "Invalid option -$OPTARG"
      print_main_usage
      exit 1
      ;;
    esac
done

shift $((OPTIND-1))

subcommand=$1; shift # remove subcommand from the argument list
case "$subcommand" in

    all )
        echo "Running 'run_all'"
        run_all

        shift $((OPTIND -1))
        ;;

    prep )
        echo "Running 'run_prep'"
        run_prep

        shift $((OPTIND -1))
        ;;

    md)
        echo "Running MD step"
        run_prep
        run_md

        shift $((OPTIND -1))
        ;;

    run_viz)
        echo "Visualizing MD results"
        run_prep
        vis

        shift $((OPTIND -1))
        ;;

    convert)
        echo "Running convert step"
        run_prep
        run_convert

        shift $((OPTIND -1))
        ;;

    repeat-detect)
        echo "Running repeat step"
        run_prep
        run_detect_repeat

        shift $((OPTIND -1))
        ;;

    repeat-remove)
        echo "Running repeat step"
        run_prep
        run_remove_repeat

        shift $((OPTIND -1))
        ;;

    repeat-convert)
        echo "Running repeat step"
        run_prep
        run_convert_repeat

        shift $((OPTIND -1))
        ;;

esac

# ------------------------------------------------------------------
