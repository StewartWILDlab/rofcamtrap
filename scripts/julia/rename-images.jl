
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere Pkg.instantiate()

@everywhere using ExifViewer

using ProgressMeter
using DataFrames
using CSV

@everywhere function get_datetime(image)

    io = open(image, "r")
    tags =  read_tags(io, read_all = false, tags=["EXIF_TAG_DATE_TIME_ORIGINAL"])
    
    if isempty(tags)
        @info("Image $image has no datetime")
        datetime = nothing
    else
        datetime = replace(replace(first(tags)[2], ":"=>"_"), " "=>"_")
    end

    close(io)

    return(datetime)

end

@everywhere function process_image(image, datetime, images_to, deployment_code, loc, loc_base, file_ext)

    if isnothing(datetime) 
        @info("Image $image has no datetime")
    else
        # Filter the path for useless sections, removing DCIM first
        image_split_filtered = replace.(replace.(replace.(replace.(replace.(
            filter(x -> x != "DCIM", 
                # Split at appropriate file separator
                splitpath(replace(image, loc=>""))[2:end]), 
            "RECNX"=>""), "RCNX"=>""), file_ext=>""), "Wildlife"=>"W"), "NonWildlife"=>"NW")         
        
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
        
        exif_path = joinpath(images_from, (loc_base * "_exif.csv"))

        if !isfile(exif_path) 
            @info("Collecting exif datetime")
            datetimes = @showprogress pmap(all_images) do x
               get_datetime(x)
            end
            exif = DataFrame(:image => all_images, :datetime =>datetimes)
            CSV.write(exif_path, exif)
        else
            exif = CSV.read(exif_path, DataFrame)
        end

        
        @showprogress pmap(all_images, exif[!, :datetime]) do x, y
            process_image(x, y, images_to, deployment_code, loc, loc_base, file_ext)
        end

    end

end

# rename_images("/media/vlucet/TrailCamST1/TrailCamStorage", 
#               "/media/vlucet/TrailCamST1/renamed", 
#               "TC1"; locations_subset = [  # "P045", "P058", "Q647", "P216", "P100",
#                                          "P087", "P293",  "P080", "P224" ])

rename_images("/media/vlucet/TrailCamST1/TrailCamStorage", 
              "/media/vlucet/TrailCamST1/renamed", 
              "TC1"; locations_subset = ["P028"])

# rename_images("/home/ubuntu/data/TrailCamStorage", 
#               "/home/ubuntu/data/renamed", 
#               "TC1"; locations_subset = ["P030"])