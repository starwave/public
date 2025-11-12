I want to create two projects umunhum & prado.
Please make the proper md doc for installation guide for all required components.

1. shared/nodejs/umunhum
   @ http://11.11.11.12:3002/
   Web app with ui to take image and show top 5 most close image from qdrant

2. shared/python/prado
   @ http://11.11.11.11:3003/
   11.11.11.11 has GPU / CUDA available
   Scan images from %PRADOROOT% and its all childen folders ( default = ~/CloudStation/BP\ Photo => about 55K images)
   Using segmentanything and more, analyze each image and extract information and store in quadrant and postgres db for search by umunhum
   sam_vit_h_4b8939.pth is already downloded at ~
   don't make copy of images and don't store any temp files under %PRADOROOT%

it should provide following restful commands
/scan -> start scan only with updated one (check pisize & pimdate, mark removed if file is deleted)
/fullscan -> start scan fully (ignore and do all files, mark removed if file is deleted)
/stop -> stop scan
/status -> show progress status
as in postgres db schema, it should update proper pistatus

3. qdrant
   @ 11.11.11.12
   Store path and analysis information for query by umunhum.

4. postgres db
   @ 11.11.11.12
   db - prado
   table - pimage
   pid - int id
   pipath - image relative path from root
   picdate - image created date
   pimdate - image modified date
   pisize - image size in byte
   piinfo - json format result from segment anything or more
   pistatus - done: done analysis, updated: should analyze again, removed: keep the record in case it's removed
