#!/usr/bin/bash

# New storage dir
STORAGE_DIR="/media/vlucet/My Passport/Images"

# Start with empty array
DIRS=()

# Find all folders
echo "Finding all folders"
for FILE in "$STORAGE_DIR"/*; do
    echo "$FILE"
    [[ -d "$FILE" ]] && DIRS+=("$FILE")
done

echo "      Directory list:"
printf "      %s\n" "${DIRS[@]}"
echo ""

for DIR in "${DIRS[@]}"; do

	echo "$DIR"
	# mkdir "$DIR/Wildlife"

	for SUBFILE in "$DIR"/*; do
		# echo "$SUBFILE"
    	[[ -f "$SUBFILE" ]] && mv "$SUBFILE" "$DIR/Wildlife/$(basename "$SUBFILE")"
	done

done

