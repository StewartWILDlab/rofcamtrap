#!/bin/bash

# Specify the directory containing your folders
main_directory="TrailCamStorage_2"

# Loop through each folder in the main directory
for folder in "$main_directory"/*; do
    if [ -d "$folder" ]; then
        echo "Processing files in folder: $folder"

        # Create subdirectories for NonWildlife and Wildlife files
        mkdir -p "$folder/NonWildlife"
        mkdir -p "$folder/Wildlife"

        # Loop through each file in the folder
        for file in "$folder"/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                
                # Check if the filename contains "NonWildlife"
                if [[ "$filename" == *NonWildlife* ]]; then
                    mv "$file" "$folder/NonWildlife"
                    echo "Moved $filename to NonWildlife folder"
                else
                    mv "$file" "$folder/Wildlife"
                    echo "Moved $filename to Wildlife folder"
                fi
            fi
        done

        echo "Processing complete for folder: $folder"
    fi
done
