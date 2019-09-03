#!/bin/bash
# converts all MP4 to a small version
# move the small version to another folder
# create a mini jpg preview
# move the original MP4 to a sub-folder

MACRODIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BASEDIR="$( cd "$( dirname "${MACRODIR}" )" >/dev/null 2>&1 && pwd )"
# HD="/mnt/MIRRORHDD/rpicam"
# cd ${MACRODIR}

cd /mnt/MIRRORHDD/rpicam/videos/

mypidfile=${MACRODIR}/end_box.sh.pid
mylogfile=${BASEDIR}/scheduleLog.txt

#Check if script already running
NOW=`date +"-%Y/%m/%d %H:%M:%S-"`
# TODAY=`date +"%Y-%m-%d"`

if [ -f $mypidfile ]; then
    # test if script died without cleaning up file
    if test "`find ${mypidfile} -mmin +30`"; then
        rm -f -- '$mypidfile'
    else
        echo "${NOW} Script already running..." >> ${mylogfile}
        exit
    fi
fi

#Remove PID file when exiting
trap "rm -f -- '$mypidfile'" EXIT
echo $$ > "$mypidfile"

shopt -s nullglob # allows you to change additional shell optional behavior

for i in *.mp4;
    do name=`echo $i | cut -d'.' -f1`;
    filedate=`echo $name | cut -d'_' -f1`;
    echo "Filename: ${name} | from ${i}";
    #ffmpeg -i $i -s 1280x720 -c:a copy $name.mp4.mp4;

    # prepare new directory
    mkdir -p  ../nextcloud/videos-mini/${filedate}

# get original video size
    echo "# Details
name: /mnt/MIRRORHDD/rpicam/videos/converted/${filedate}/${name}.mp4
size: $(du -h ${name}.mp4 | cut -f1)
duration: $(ffmpeg -i ${name}.mp4  2>&1 | grep "Duration"| cut -d ' ' -f 4 | sed s/,//)" >> "../nextcloud/videos-mini/${filedate}/${name}.md"

    # resize the video to a 320px width
    mini="../nextcloud/videos-mini/${filedate}/${name}.mp4"
    ffmpeg -i $i -vf scale="320:-1" $mini

    # create a thumbnail gallery from the video
    ${MACRODIR}/thumbnails-generator.sh 20 5x4 800 $mini ${mini}.jpg >> ${mylogfile}

    # move the file to "converted"
    mkdir -p converted/${filedate}
    mv $i converted/${filedate}/$i
done
