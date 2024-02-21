
using ExifViewer
using ProgressBars

function rename_images(
    images_from,
    images_to,
    deployment_code ;
    locations_subset = nothing,
    file_ext = r"\.(jpg|jpeg|JPG|JPEG)$")

    # Get all location folders in this deployment, some will have _repeat or _crop
    # in them, due to the way folders were processed before renaming
    locations_all = filter(isdir, readdir(images_from; join=true)) |> 
        filter(s -> !occursin("repeat", s)) |>
        filter(s -> !occursin("crop", s))

    # Subset if necessary
    if !isnothing(locations_subset)
        locations = [joinpath(images_from, loc) for loc in locations_subset]
    else 
        locations = locations_all
    end

    println(basename.(locations))

    # For all locations, proceed to the copy and renaming
    for loc in locations # This is the full path...

        # ...so we also obtain the base path
        loc_base = basename(loc)
        @info("Processing folder $loc_base")

        # List all images
        all_images = []
        for (root, _, files) in walkdir(loc)
            for file in files
                image_path =  joinpath(root, file)
                if occursin(file_ext, image_path) push!(all_images, image_path) end
            end
        end

        @info("Found $(length(all_images)) images, first is $(all_images[1])")

        for i in ProgressBar(1:length(all_images))
            image = all_images[i]

            # Filter the path for useless sections, removing DCIM first
            image_split_filtered = replace.(replace.(replace.(replace.(replace.(
                filter(x -> x != "DCIM", 
                    # Split at appropriate file separator
                    splitpath(replace(image, loc=>""))[2:end]), 
                "RECNX"=>""), "RCNX"=>""), file_ext=>""), "Wildlife"=>"W"), "NonWildlife"=>"NW")
            
            # Get datetime from exif dat
            datetime = replace(replace(first(read_tags(image, read_all = false, 
                tags=["EXIF_TAG_DATE_TIME_ORIGINAL"]))[2], ":"=>"_"), " "=>"_")
            
            # Construct the new file name...
            new_name =  join([deployment_code, loc_base,
                join(vcat(image_split_filtered, [datetime]), "_") * ".JPG"], "_")

            # ...and new file path
            new_path = joinpath(images_to, deployment_code, 
                                join([deployment_code, loc_base], "_"),
                                join(vcat([deployment_code], [loc_base], image_split_filtered[1:2]), "_"),
                                new_name)

            if isfile(new_path)
                # @info("File $(basename(new_path)) already exists")
            else
                if !isdir(dirname(new_path)) 
                    @info("Creating path $(dirname(new_path))")
                    mkpath(dirname(new_path)) 
                end
                # @info("Creating file $(basename(new_path))")
                cp(image, new_path)
            end
            
        end

    end

end

# rename_images("/media/vlucet/TrailCamST1/TrailCamStorage", 
#               "/media/vlucet/TrailCamST1/renamed", 
#               "TC1"; locations_subset = [  # "P045", "P058", "Q647", "P216", "P100",
#                                          "P087", "P293",  "P080", "P224" ])

# rename_images("/media/vlucet/TrailCamST1/TrailCamStorage", 
#               "/media/vlucet/TrailCamST1/renamed", 
#               "TC1")
rename_images("/data/TrailCamStorage", 
              "/data/renamed", 
              "TC1")