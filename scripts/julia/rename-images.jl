
# For reproducibility
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere Pkg.instantiate()

# All workers need ExifViewer to read the exif data
@everywhere using ExifViewer

# Other modules needed
using ProgressMeter
using DataFrames
using CSV

# Get the Datetime info
@everywhere function get_datetime(image)

    # Open the file to read a single tag
    io = open(image, "r")
    tags =  read_tags(io, read_all = false, tags=["EXIF_TAG_DATE_TIME_ORIGINAL"])
    
    # If the tag is empty, throw an error, else format it
    if isempty(tags)
        throw("Image $image has no datetime")
    else
        datetime = replace(replace(first(tags)[2], ":"=>"_"), " "=>"_")
    end

    # Make sure to close the connection to the filte
    close(io)

    return(datetime)

end

# Construct a new path
@everywhere function make_new_path(image, datetime ; images_to, deployment_code, loc, loc_base, file_ext)
    
    # If the datetime is empty, throw an error, else format it
    if isnothing(datetime) 
        throw("Image $image has no datetime")
    else
        # Filter the path for useless sections, removing DCIM first
        image_split_filtered = replace.(replace.(replace.(replace.(replace.(
            filter(x -> x != "DCIM", 
                # Split at appropriate file separator
                splitpath(replace(image, loc=>""))[2:end]), 
            "RECNX"=>""), "RCNX"=>""), file_ext=>""), "NonWildlife"=>"NW"), "Wildlife"=>"W")
        
        # Construct the new file name...
        new_name =  join([deployment_code, loc_base,
            join(vcat(image_split_filtered, [datetime]), "_") * ".JPG"], "_")

        # ...and new file path
        if (occursin("_W_", new_name))
            sub = join(vcat([deployment_code], [loc_base], image_split_filtered[1:2], ["W"]), "_")
        elseif (occursin("_NW_", new_name))
            sub = join(vcat([deployment_code], [loc_base], image_split_filtered[1:2], ["NW"]), "_")
        else
            sub = join(vcat([deployment_code], [loc_base], image_split_filtered[1:2]), "_")
        end

        new_path = joinpath(images_to, deployment_code, 
                            join([deployment_code, loc_base], "_"),
                            sub,
                            new_name)

    end

    return(new_path)

end

# Side effect only function to copy files
@everywhere function process_image(image, new_path; force = true)

    if !isfile(new_path)
        if !isdir(dirname(new_path)) 
            @info("Creating path $(dirname(new_path))")
            mkpath(dirname(new_path)) 
        end
        # @info("Creating file $(basename(new_path))")
        cp(image, new_path, force = force)
    end

end

# Main function
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

    @info("Processing locations $(basename.(locations))")

    # For all locations, proceed to the copy and renaming
    for loc in locations # This is the full path...

        # ...so we also obtain the base path
        loc_base = basename(loc)
        @info("Processing folder $loc_base")

        # Make path to exif data
        exif_path = joinpath(images_from, (loc_base * "_exif.csv"))

        # # TEMP skip if csv present
        if isfile(exif_path) 
            @info("Skipping $loc_base")
            continue
        end

        if !isfile(exif_path)

            # List all images
            @info("Walking folder... this could take a while")
            all_images = []
            for (root, _, files) in walkdir(loc)
                for file in files
                    image_path =  joinpath(root, file)
                    if occursin(file_ext, image_path) push!(all_images, image_path) end
                end
            end
            @info("Found $(length(all_images)) images, first is $(all_images[1])")

            @info("Collecting exif datetime")
            datetimes = @showprogress pmap(all_images) do x
               get_datetime(x)
            end

            exif = DataFrame(:image => all_images, :datetime =>datetimes)
            CSV.write(exif_path, exif)
            @info("Datetime data saved")

        else

            @info("Reading datetime data")
            exif = CSV.read(exif_path, DataFrame)

            all_images = exif[!, :image]
            datetimes = exif[!, :datetime]
            @info("Found $(length(all_images)) images, first is $(all_images[1])")

        end
        
        # Construct the new paths
        all_new_paths = @showprogress map(all_images, datetimes) do x, y
            make_new_path(x, y ; images_to = images_to, deployment_code = deployment_code, 
                                 loc = loc , loc_base = loc_base, file_ext = file_ext)
        end

        @info("Processing files")
        @showprogress pmap(all_images, all_new_paths) do from, to
            sleep(0.1)
            process_image(from, to)
            sleep(0.1)
        end

    end

end

# ------------------------------------------------------------------------------------------


rename_images("/media/vlucet/TrailCamST1/TrailCamStorage/", 
              "/home/vlucet/Documents/WILDLab/renamed", 
            #   "/media/vlucet/TrailCamST1/renamed", 
              "TC1";  locations_subset = ["P092"])

rename_images("/media/vlucet/TrailCamST1/TrailCamStorage/", 
              # "/home/vlucet/Documents/WILDLab/renamed", 
              "/media/vlucet/TrailCamST1/renamed", 
              "TC1";  locations_subset = ["P080", "P092"]) # "P080",

rename_images("/media/vlucet/TrailCamST1/TrailCamStorage_2/", 
              "/media/vlucet/TrailCamST1/renamed", 
              "TC2")

rename_images("/media/vlucet/Elements SE/", 
              "/media/vlucet/TrailCamST1/renamed", 
              "TC3")

# rename_images("/home/ubuntu/data/TrailCamStorage", 
#               "/home/ubuntu/data/renamed", 
#               "TC1"; locations_subset = ["P030"])

# "P045" "P058" "P080" "P087" "P100"
# "P216" "P224" "P293" "Q647"

# # TEMP skip if csv present
# if isfile(exif_path) 
#     @info("Skipping $loc_base")
#     continue
# end

# ------------------------------------------------------------------------------------------

function count_images(images_from,
                      file_ext = r"\.(jpg|jpeg|JPG|JPEG)$")

    # Get all location folders in this deployment, some will have _repeat or _crop
    # in them, due to the way folders were processed before renaming
    locations = filter(isdir, readdir(images_from; join=true)) |> 
        filter(s -> !occursin("repeat", s)) |>
        filter(s -> !occursin("crop", s))

    for loc in locations
        x = 0 ; 
        for (root, _, files) in walkdir(loc)
            for file in files
                image_path =  joinpath(root, file)
                if occursin(file_ext, image_path) x += 1 end
            end
        end
        println("Loc $(basename(loc)) has $x images")
    end

end

function check_exif()
end

count_images("/media/vlucet/TrailCamST1/TrailCamStorage/")

count_images("/media/vlucet/TrailCamST1/renamed/TC1")