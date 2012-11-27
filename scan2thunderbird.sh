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
 

path=`dirname $0`
cd $path

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

# Running loop

run=true

while $run

do

	echo "Number of pages you want to scan :"
	read pages

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


	cmpt=0

	while [ "$cmpt" != "$pages" ]
		do
			echo "Page $(($cmpt+1)) on $pages in progress :"
			case $couleur in
			[yYoO]*)						
				# Scan and convert for color case : high resolution						
				scanimage -p --resolution=300 --format=tiff > courrier-$cmpt.tiff
				convert -depth 300 -quality 90 -resize 75% -strip courrier-$cmpt.tiff courrier-$cmpt.jpeg 
				echo " "
				echo "File courrier-$cmpt.jpeg written in 300 DPI color at 90% quality.";;
			[Nn]*)
				# Scan and convert for B&W case : medium resolution						
				scanimage -p --resolution=150 --mode=gray --format=tiff > courrier-$cmpt.tiff
				convert -depth 150 -quality 90 -resize 75% -strip courrier-$cmpt.tiff courrier-$cmpt.jpeg
				echo " "
				echo "File courrier-$cmpt.jpeg written in 150 DPI B&W at 90% quality." ;;
			esac 

			if  [ "$cmpt" != "$(($pages-1))" ]; then
				echo "Switch to the next page and press enter when it's ready..."	
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
	convert -compress jpeg courrier-*.jpeg courrier.pdf

	# Compress the PDF to fit mail limitations. Comment the following line if you don't want to compress it.
	gzip --best courrier.pdf

	echo "File courrier.pdf.gz generated with 9 compression factor."
	echo "Finished."

	echo " "
	echo "********************************************************************"
	echo "!                         FILE SENDING                             !"
	echo "********************************************************************"
	echo " "

	thunderbird -compose "to='',subject='',body='',attachment='file://$path/courrier.pdf.gz'" 
	echo " "
	echo "Press Enter when the email is sent"
	read done
	echo "Finished."

	echo " "
	echo "********************************************************************"
	echo "!                         FILE CLEANING                            !"
	echo "********************************************************************"
	echo " "
	echo "Do not interrupt this operation. Please wait 'Finished' message."

	# Removing all generated files for security purpose. Comment the following lines if you want to store a local copy.
	shred -n 35 -z -u courrier-*.tiff
	shred -n 35 -z -u courrier-*.jpeg
	shred -n 35 -z -u courrier.pdf.gz


	echo "All files were deleted with high secured algorithm (35 passes of random bytes)."
	echo "Finished."

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

	case $fin in 
	[nN]*) run=false ;;
	esac
done
exit 0
