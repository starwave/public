#!/usr/bin/env python3

_imageDescriptionTag = 0x010e # = 270

def get_with_piexif(path):
    import piexif
    try:
        exif_dict = piexif.load(path)
    except Exception as error:
        return ""
    for ifd in ("0th", "Exif", "GPS", "1st"):
    #    for tag in exif_dict[ifd]:
    #        print(ifd, tag, piexif.TAGS[ifd][tag]["name"], exif_dict[ifd][tag])
        try:
            exif = exif_dict[ifd][_imageDescriptionTag].decode('utf-8')
        except Exception as error:
            exif = ""
        if exif != "":
            break
    return exif

def get_with_ExifTags(path):
    try:
        from PIL import Image, ExifTags
        from PIL.ExifTags import TAGS
        img = Image.open(path)
        img_exif = img._getexif()
        exif = img_exif[_imageDescriptionTag]
    except Exception as error:
        exif = ""
    return exif  # image description (not utf-8 encoded)

def get_with_exifread(path):
    # failed in reading some tags
    import exifread, sys
    backup = sys.stderr
    sys.stderr = object # suppress exif error message
    try:
        file = open(path, 'rb')
        tags = exifread.process_file(file)
        exifDesc = tags["Image ImageDescription"]
    except Exception as error: 
        exifDesc = ""
    sys.stderr = backup
    return str(exifDesc)

def get_with_exiftool(path):
    import subprocess
    result = subprocess.run(['exiftool', '-b', '-imagedescription', path], stdout=subprocess.PIPE)
    exif = result.stdout.decode('utf-8').strip()
    return exif

"""
print("piexif   : ", get_with_piexif(path))   # 1s / 15K
print("ExifTags : ", get_with_ExifTags(path)) # 6s / 15K
print("exifread : ", get_with_exifread(path)) # 33s / 15K
print("exiftool : ", get_with_exiftool(path)) # 4m 36s / 15K
"""
