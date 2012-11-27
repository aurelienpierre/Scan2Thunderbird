#!/bin/sh
#                             Scan2Thunderbird                             #
#                                   v0.1                                   #
#                                                                          #
#                 To run, this script needs this packages :                #
#	        sane, imagemagick, gzip, thunderbird & shred               #
#                                                                          #
#                          GNU Public License v3                           #
#                                                                          #
#                     Copyright © 2012 Aurélien PIERRE                     #
#         http://aurelienpierre.com - aurelien@aurelienpierre.com          #
#                                                                          #
#                                                                          #
# Scan2Thunderbird is free software: you can redistribute it and/or modify #
# it under the terms of the GNU General Public License as published by     #
# the Free Software Foundation, either version 3 of the License, or        #
# (at your option) any later version.                                      #
#                                                                          #
# This program is distributed in the hope that it will be useful,          #
# but WITHOUT ANY WARRANTY; without even the implied warranty of           #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
# GNU General Public License for more details.                             #
#                                                                          #
# You should have received a copy of the GNU General Public License        #
# along with this program.  If not, see <http://www.gnu.org/licenses/>     #
 

path=$(dirname $0)

echo " "
echo "********************************************************************"
echo "!                Welcome in Scan2Thunderbird v0.1                  !"
echo "!                     GNU Public License v3                        !"
echo "!                Copyright © 2012 Aurélien PIERRE                  !"
echo "!    http://aurelienpierre.com - aurelien@aurelienpierre.com       !"
echo "!        This program is distributed WITHOUT ANY WARRANTY !        !"     
echo "********************************************************************"
echo " "


# Check if required packages are installed

echo "This program needs the following packages to run :"
echo "sane, imagemagick, thunderbird, gzip,coreutils."
echo " "
echo "Please install them if they are missing."
echo " "

## functions

# Function convert : $res $crop $pages $couleur $quality $pass
convertimage() {

	if [ "$6" = 1 ]; then
	convert -page A4 -density $1 -quality $5 -compress jpeg -strip -crop $2 $path/courrier-$cmpt.tiff $path/courrier-$cmpt.jpeg 
	else
	convert -page A4 -density $1 -quality $5 -compress jpeg -strip -resize $2 $path/courrier-$cmpt.tiff $path/courrier-$cmpt.jpeg
	fi 
}

# Function merge : $res $crop $pages $couleur $quality

merge() {

	# Combine all images (if any) i a single PDF file

	cmpt=0
	while [ "$cmpt" != "$3" ]
		do
		# Concatenate images list
		string="$string $path/courrier-$cmpt.jpeg"
		cmpt=$(($cmpt+1))
	done
		convert -compress jpeg -quality $5 -density $1 $string $path/courrier.pdf

	# Compress the PDF to fit mail limitations. Comment the following line if you don't want to compress it.
	gzip --best $path/courrier.pdf

}

# Function scan : $res $crop $pages $couleur $quality
scan() {
cmpt=0

	while [ "$cmpt" != "$3" ]
		do
			echo "Page $(($cmpt+1)) of $3 :"
			case $4 in
			[yYoO]*)						
				# Scan and convert for color case						
				scanimage -p --resolution=$1 --format=tiff > $path/courrier-$cmpt.tiff
				convertimage "$1" "$2" "$3" "$4" "$5" "1"
				echo " "
				echo "++ File courrier-$cmpt.jpeg written in $1 DPI color at $5% quality."
				echo " ";;
			[Nn]*)
				# Scan and convert for B&W case						
				scanimage -p --resolution=$1 --mode=gray --format=tiff > $path/courrier-$cmpt.tiff
				convertimage "$1" "$2" "$3" "$4" "$5" "1"
				echo " "
				echo "++ File courrier-$cmpt.jpeg written in $1 DPI B&W at $5% quality." 
				echo " ";;
			esac 

			if  [ "$cmpt" != "$(($pages-1))" ]; then
				echo "Switch to the next page and press enter when it's ready..."	
				echo " "
				read go
			fi

			cmpt=$(($cmpt+1))
	done
	echo "Finished"

	echo " "
	echo "********************************************************************"
	echo "!                       FILE GENERATION                            !"
	echo "********************************************************************"
	echo " "

	# Combine all images (if any) i a single PDF file

	merge "$1" "$2" "$3" "$4" "$5"

	echo " "
	echo "File courrier.pdf.gz generated with 9 compression factor."
	echo "Finished."
	echo " "
}

# Function scan : $res $crop $pages $couleur $quality
rescan() {
cmpt=0

	while [ "$cmpt" != "$3" ]
		do
			case $4 in
			[yYoO]*)						
				convertimage "$1" "$2" "$3" "$4" "$5" "1" ;;
			[Nn]*)
				convertimage "$1" "$2" "$3" "$4" "$5" "1" ;;
			esac 

			cmpt=$(($cmpt+1))
	done

	# Combine all images (if any) i a single PDF file

	merge "$1" "$2" "$3" "$4" "$5"

	echo " "
	echo "File courrier.pdf.gz generated with 9 compression factor."
	echo "Finished."
	echo " "
}


# Function clean

clean() {
	echo " "
	echo "Do not interrupt this operation. Please wait 'Finished' message."
	echo " "
	shred -n 35 -z -u $path/courrier-*.tiff
	shred -n 35 -z -u $path/courrier-*.jpeg
	shred -n 35 -z -u $path/courrier.pdf.gz
}

## Global var

# Define resolution, quality and corresponding A4 size in pixels for single page documents
res=300
crop=2480x3506+0+0
quality=90

## Running loop

run=true

while $run

do

	echo -n "Number of pages you want to scan :"
	read pages

	# Override relotion and A4 size for multiple page documents - Too heavy files will not be sent by email
	if [ "$pages" -ge 3 ]; then
		res=150
		crop=1240x1753+0+0
	fi

	echo " "
	echo "********************************************************************"
	echo "Is the source document in color ? "
	echo "-- type Y for yes then press Enter"
	echo "-- type N for no then press Enter"
	read couleur
	echo " "

	echo " "
	echo "********************************************************************"
	echo "!                       SCAN BEGINNING                             !"
	echo "********************************************************************"
	echo " "

		scan "$res"  "$crop"  "$pages"  "$couleur" "$quality"

	# Check file weight
	FILESIZE=$(stat -c%s "$path/courrier.pdf.gz")

	while [ "$FILESIZE" -ge 5000000 ]
		do
		echo " "
		echo "/!\ Warning : Generated file weights more than 5 Mo ($FILESIZE bytes). "
		echo "In some cases, it may not be sent by email"
		echo " "
		echo "Would you like to scan it again with another parameters ?"
		echo "-- type Y for yes then press Enter"
		echo "-- type N for no then press Enter"
		read stop
		echo " "

		case $stop in 
			[yYoO]*) 	
				rescan "150"  "1240x1753+0+0"  "$pages"  "$couleur" "$quality" "2"
				FILESIZE=$(stat -c%s "$path/courrier.pdf.gz")
				quality=$(($quality-5)) ;;
			[nN]*)
				break ;;
		esac

	done

	echo " "
	echo "********************************************************************"
	echo "!                         FILE SENDING                             !"
	echo "********************************************************************"
	echo " "

	thunderbird -compose "to='',subject='',body='Please note that the attachment is compressed using Gzip and must be uncompressed before reading.',attachment='file://$path/courrier.pdf.gz'" 
	echo " "
	echo "Press Enter when the email is sent"
	read done
	echo "Finished."
	echo " "

	echo " "
	echo "********************************************************************"
	echo "!                         FILE CLEANING                            !"
	echo "********************************************************************"
	echo " "

	# Removing all generated files for security purpose. Comment the following line if you want to store a local copy.

		clean


	echo "All files were deleted with high secured algorithm (35 passes of random bytes)."
	echo "Finished."
	echo " "

	echo " "
	echo "********************************************************************"
	echo "!                          END OF SCAN                             !"
	echo "********************************************************************"
	echo " "
	echo "The programm is now finished."
	echo " "

	# Tweak for multiple scans
	echo "Would you like to scan again ?"
	echo "-- type Y for yes then press Enter"
	echo "-- type N for no then press Enter"
	
	read fin
	echo " "

	case $fin in 
	[yYoO]*) 
		unset string 
		res=300
		crop=2480x3506+0+0
		quality=90 ;;
	[nN]*) 
		run=false ;;
	esac
done
exit 0