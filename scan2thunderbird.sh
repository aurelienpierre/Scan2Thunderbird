#!/bin/bash
#                                     Scan2Thunderbird GUI                           #
#                                          v0.2                                                   #
#                                                                                                    #
#                 To run, this script needs this packages :                #
#	    sane, imagemagick, gzip, thunderbird, zenity & shred           #
#                                                                          #
#                          GNU Public License v3                           #
#                                                                          #
#                     Copyright © 2012 Aurélien PIERRE                     #
#         https://aurelienpierre.com - aurelien@aurelienpierre.com          #
#                                                                          #
#                                                                          #
# Scan2Thunderbird is free software: you can redistribute it and/or modify #
#    it under the terms of the GNU General Public License as published by     #
#        the Free Software Foundation, either version 3 of the License, or          #
#                               (at your option) any later version.                                      #
#                                                                                                                               #
#           This program is distributed in the hope that it will be useful,            #
# but WITHOUT ANY WARRANTY; without even the implied warranty of           #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
# GNU General Public License for more details.                             #
#                                                                          #
# You should have received a copy of the GNU General Public License        #
# along with this program.  If not, see <http://www.gnu.org/licenses/>     #

path=$(dirname $0) 

CONFIG_FILE=$path/scan2thunderbird.conf

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi

LANG_FILE=$path/scan2thunderbird.lang

if [ -f $LANG_FILE ]; then
        . $LANG_FILE
fi
     
###### Functions

# Function convert : $resolution $crop $pages $color $quality $pass
convertimage() {

	if [ "$6" -eq "1" ]; then
	convert -page A4 -crop $2 /tmp/$name-$cmpt.tiff  /tmp/$name-$cmpt.tiff 
	convert -page A4 -density $1 -quality $5 -compress jpeg -strip -crop $2 /tmp/$name-$cmpt.tiff /tmp/$name-$cmpt.jpeg 
	else
	convert -page A4 -density $1 -quality $5 -compress jpeg -strip -resize $2 /tmp/$name-$cmpt.tiff /tmp/$name-$cmpt.jpeg
	fi 
}

# Function merge : $resolution $crop $pages $color $quality

merge() {

	# Combine all images (if any) i a single PDF file

	cmpt=0
	while [ "$cmpt" != "$3" ]
		do
		# Concatenate images list
		string="$string /tmp/$name-$cmpt.jpeg"
		echo $string
		cmpt=$(($cmpt+1))
	done
		convert -compress jpeg -quality $5 -density $1 $string /tmp/$name.pdf

}

# Function scan : $resolution $crop $pages $couleur $quality
scan() {

	echo "$txt10 $(($cmpt+1))"; sleep 1

	cmpt=0

	while [ "$cmpt" != "$3" ]
		do
		case $4 in
		[Yes]*)	
			
			# Scan and convert for color case

			echo "$(((50*($cmpt+1)/$3)-10))" | bc ; sleep 1
			echo "$txt11 $(($cmpt+1))" ; sleep 1	
		
			scanimage -p --resolution=$1 --format=tiff > /tmp/$name-$cmpt.tiff

			echo "$(((100*($cmpt+1)/$3)-10))" | bc ; sleep 1
			echo "$txt12 $(($cmpt+1))"; sleep 1	

			convertimage "$1" "$2" "$3" "$4" "$5" "1"

			echo "# File $name-$cmpt.jpeg written in $1 DPI (color : $4) at $quality %." ; sleep 1 ;;

		[No]*)

			# Scan and convert for B&W case	

			echo "$(((50*($cmpt+1)/$3)-10))" | bc ; sleep 1
			echo "$txt11 $(($cmpt+1))"; sleep 1		
	
			scanimage -p --resolution=$1 --mode=gray --format=tiff > /tmp/$name-$cmpt.tiff

			echo "$(((100*($cmpt+1)/$3)-10))" | bc ; sleep 1
			echo "$txt12 $(($cmpt+1))"; sleep 1

			convertimage "$1" "$2" "$3" "$4" "$5" "1"

			echo "# File $name-$cmpt.jpeg written in $1 DPI (color : $4) at $quality %."  ; sleep 1 ;;
		esac 

		if  [ "$cmpt" != "$(($pages-1))" ]; then
			zenity --question \
				--text="$txt20"
			quit "$?"
		fi
 
		cmpt=$(($cmpt+1))
	done

	echo "90" ; sleep 1
	echo "$txt14" ; sleep 1
}

# Function rescan : $resolution $crop $pages $couleur $quality
rescan() {
	cmpt=0

	while [ "$cmpt" != "$3" ]
		do
			convertimage "$1" "$2" "$3" "$4" "$5" "2"
			cmpt=$(($cmpt+1))
	done

}

# Function clean 

clean() {
	shred -n 35 -z -u /tmp/$name-*.tiff
	shred -n 35 -z -u /tmp/$name-*.jpeg
	shred -n 35 -z -u /tmp/$name*.pdf
}

# Function quit : $?

quit() {
	if [ "$1" = 1  ]; then
		break
		clean
		exit 1
	fi
}


####### Init

# Prevent errors in programm and stop it in this case

#set -e
#set -o 

# Check if required packages are installed

## USELESS IF USED AS A DEB PACKAGE

#commands=(scanimage convert gzip shred thunderbird zenity)
#install=(sane imagemagick gzip coreutils thunderbird zenity)

#index=0

#while [ "$index" -lt 6 ]
#	do 
#
#	if which ${commands[$index]} >/dev/null; then
#		ok=ok
#	else
#		zenity --question --text="${install[$index]} $txt21" --title="$txt22"
#			if [ "$?" = 1  ]; then
#				exit 1
#			fi
#		zenity --password --text="${install[$index]}" --title="$txt23 ${install[$index]} ?"| sudo -S -s
#			if [ "$?" = 1  ]; then
#				exit 1
#			fi
#		sudo apt-get -y install ${install[$index]}
#	fi
#	index=$(($index+1))
#done

# Beginning



# Look for plugged scanner

( echo "# $txt26" ; sleep 1

device=$(scanimage  -f  scanner number %i device %d is a %t, model %m, produced by %v )

if [ -z "$device" ]; then
	zenity --error --title="$txt1" --text="$txt2 \n\nLog : \n\n$(sane-find-scanner -q)"
	sleep 1
	exit 1
fi

echo "100" ; sleep 1
) |
zenity --progress --title="Scan2Thunderbird" --text="" --pulsate --auto-close

quit "$?"

####### Running loop

	# Ask file name

	name=$(zenity --entry --title="$txt18" --text="$txt19")

	quit "$?"

	# Ask number of pages

	pages=$(zenity --entry --title="$txt4" --text="$txt5")

	quit "$?"

	couleur=$(zenity 	--list \
				--radiolist \
				--title="$txt6" \
				--column="$txt7" --column="$txt8"\
				 Y Yes\
				 N No\
				\
				--separator="|")
	quit "$?"

	(
		# Scan after determining which proportion are best according to the number of pages
			
			if [ "$pages" -ge "4" ]; then
				scan "$min_resolution"  "$min_crop"  "$pages"  "$couleur" "$quality"
				merge "$min_resolution" "$min_crop" "$pages" "$color" "$quality"
			else
				scan "$max_resolution"  "$max_crop"  "$pages"  "$couleur" "$quality"
				merge "$max_resolution" "$max_crop" "$pages" "$color" "$quality"
			fi

		echo "100" ; sleep 1
		echo "$txt15" ; sleep 1 

	) | zenity   --progress --title="$txt16" \
 				 --text="$txt17" \
					--percentage=0 \
						--auto-close
		quit "$?"

	# Check file weight

	FILESIZE=$(stat -c%s "/tmp/$name.pdf")

	qual=$quality

	while [ "$FILESIZE" -ge "$attachment_limit" ]
		do	

			zenity --info --text="$txt27 $qual % - $min_resolution DPI/PPP" 

			quit "$?"

			unset string

			rescan "$min_resolution"  "$min_crop"  "$pages"  "$couleur" "$qual"
			merge "$min_resolution"  "$min_crop"  "$pages"  "$couleur" "$qual"

			FILESIZE=$(stat -c%s "/tmp/$name.pdf")

			qual=$(($qual-1))
	done

	# Preview and send

	evince /tmp/$name-2.pdf &
	thunderbird -compose "to='',subject='',body='',attachment='file:///tmp/$name.pdf'"
	wait $!

	while [ ps -p $! ]
		do
			sleep 500
	done


	delete=`zenity --question --text="$txt24 $name.pdf ?"`

	# Save and Remove all generated files for security purpose.

	if [ "$?" -eq "0" ]; then
			file=`zenity --file-selection --save  --filename=/$HOME/$USER/  --title="$txt25 ?"`
			clean
		else
			clean
	fi

exit 0
