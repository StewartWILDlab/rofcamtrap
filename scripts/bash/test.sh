#!/usr/bin/bash

STORAGE_DIR=""
BASE_FOLDER=""

export_default_vars(){
    echo "Storage Directory: $STORAGE_DIR"
    echo "Base Folder: $BASE_FOLDER"
}

run_prep(){
    export_default_vars
    # Other prep steps
}

run_all(){
    run_prep
    # Other steps for run_all
}


shift $((OPTIND - 1))

subcommand=$1; shift
case "$subcommand" in
    all )
        echo "Running 'run_all'"
        while getopts ":s:b:" opt; do
		  case ${opt} in
		    s )
		      STORAGE_DIR=$OPTARG
		      ;;
		    b )
		      BASE_FOLDER=$OPTARG
		      ;;
		    \? )
		      echo "Invalid option -$OPTARG"
		      exit 1
		      ;;
		  	esac
		done
        run_all
        ;;
    prep )
        echo "Running 'run_prep'"
        run_prep
        ;;
    md )
        run_prep
        # run_md
        ;;
    convert )
        run_prep
        # run_convert
        ;;
    repeat )
        run_prep
        # Other steps for repeat
        ;;
    \? )
        echo "Invalid subcommand: $subcommand"
        exit 1
        ;;
esac
