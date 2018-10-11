#!/bin/bash

editor="subl" #default file editor
diffdir=".diffs"
logdir=".logs"

askYN () {
	#expecting a question as $1 - e.g. "Do thing?", without the [Y/n]
 	while [ 0 ] # not very clean code but this is bash after all
 	do
		echo "$1 [Y/n]"
	 	read choice #</dev/tty # to force read from command line
 		case $choice in
 			Y|y)
				return 0 ;; #true
			N|n) 
				return 1 ;; #false
			*) echo "Invalid option. Try again:" ;;
 		esac
 	done
}

function addRepo() 
{
	echo
	echo "Enter name of repository." 
	read name
	mkdir $name 
	mkdir "$name/$diffdir"
	mkdir "$name/$logdir"
}

function delRepo() 
{
	echo 
	echo "Which repository do you want to delete?"
	counter=0
	for index in $(ls)
	do
		let counter+=1
		echo "$counter) $index"
	done
	read number
	found=1
	counter=0
	for index in $(ls)
	do
		let counter+=1
		if [ $counter == $number ]
		then
			if askYN "Are you sure that you want to delete the repository $index and all files in it?"; then
				rm -r $index 
			fi
		fi
	done
}

statusfile=".statusinfo"
curr_repo="." #eh probably change this
outdir="out"

make_statusfile() {

	if [ ! -f "$statusfile" ]
	then
		touch "$statusfile"
		for file in $(ls)
		do
			echo "$file,IN" >> "$statusfile"
			# $file,OUT means the file is being rdited, $file,IN means it's finished until further changes are needed
		done
	fi
}


#logging a file out
check_out () {
	pwd
	
	echo "enter name of the file to log out"
	read file #$file is the path of the file to be checked out, passed as the first variable to the function
	#echo "enter the full path to the directory where you want to copy this file"
	#read newpath #$newpath is where the file is to be copied, passed as the second variable to the function
		#TODO make sure newpath exists

	#if file exists
	if [ -f $file ]
	then 
		# copy it to the new path
		# cp "$file" "$newpath"


		#make a temp new statusfile
		tempstatusfile=".tempstatusfile"
		touch "$tempstatusfile"
		exec 3<> "./$tempstatusfile"


		while read -u 4 line || [ -n "$line" ]	#should prevent skipping the last line # -u 4 makes it read from FD 4
		do
			#echo "$line"
			if [ "$line" = "$file,IN" ]
			then
				#change the line to $file,OUT
				line="$file,OUT"
				mkdir "$outdir" 2>/dev/null # makes the directory and if it exists already hide the error message
				cp "$file" "$outdir" #copy the file to the editing directory


				#optionally open the file in sublime text if it is installed
				if askYN "Would you like to open this file in an external editor (subl if installed)?"
				then
					if ! subl $file; then #subl failed - possibly not installed
						echo "Sublime Text is not installed. You can install it using \"sudo apt install subl\""
						echo "Launching Nano editor to edit this file. Press the return key to continue."
						read -n 1 -sr #-s hides input, -r skips escape chars, -n 1 stops reading after 1 char 
						nano $file
					fi
				else
					echo "You can edit this file later by opening $(pwd)/$outdir/$file in your favourite text editor."
				fi

			elif [ "$line" = "$file,OUT" ]
			then
				echo "This file is already being edited."
			#else 
				#maybe check if the file is in the log at all
				#echo "sdfkjsdfjs"
			fi
			echo "$line" >&3
		done 4< "$statusfile"
		cat "$tempstatusfile" > "$statusfile"
		exec 3>&-
		rm "$tempstatusfile" # doesn't remove the file because subl just messes ev erything up
	else 
	 	echo "\"$file\" is not a correct file path."
	fi
#cat "$statusfile"
}

add_to_repo () {
	# expecting a name of the new file that should be added to the repository as parameter $1

	ls -1 #display contents so the user can make sure they're in the right repository and are trying to add the right files
	#ask for source
	echo "Please enter the full path of the file you would like to add"
	read fToAdd
	if [ -z $1 ] # if $1 is empty
	then 
		newName="$(basename $fToAdd)" #don't change the name of the file when copying
	else
		newName="$1"
	fi

	if [ -f "$fToAdd" ]
	then
		if [ -f "$curr_repo/$newName" ] # if this file is already in the repository
		then
			if askYN "This file is already in the repository. Do you want to overwrite it?"
			then
				echo "Overwriting $newName..." # continue on
			else
				return 1 # leave the function
			fi
		fi
		cp "$fToAdd" "$curr_repo/$newName" # copy the file to the current folder
		echo "$newName,IN" >> $statusfile
		echo "Added $fToAdd to the current repository as $newName"
	else
		echo "This is not a valid path to a file"
	fi
}


check_in () {
	echo "enter the name of the file you want to log in / update"
	read file  #$file is the path of the file to be checked in, passed as the first variable to the function
		#TODO make sure newpath exists

	#     ask to enter full path of the newly edited file
	#echo "please enter the FULL path to the new file"
	#read fullpath

	#if file exists
	if [ -f $file ]
	then 
		# copy it to the new path

		#make a temp new statusfile
		touch tempstatusfile
		exec 3<> ./tempstatusfile


		#sed -ie "s/$file,E/$file,F/" $statusfile #logs that the file is being edited in $statusfile
		while read -u 4 line || [ -n "$line" ]	#should prevent skipping the last line
		do
			#echo "$line"
			if [ "$line" = "$file,OUT" ]
			then
				seconds="$(date +%s)"
				diff "$outdir/$file" "$curr_repo/$file" > "$diffdir/$file-$seconds.diff" #save a diff file
				cp "$outdir/$file" "$curr_repo/$file" # copy the file from the work directory to the current dirrectory

				if askYN "Would you like to add a short comment about this edit to the log file?"
				then
					echo "Enter your comment:"
					read comment
				fi
			 	echo "$(date -d@$seconds): $comment" >> "$logdir/$file.log"

				line="$file,IN" # change the line to $file,IN
				echo "File checked in successfully."

			elif [ "$line" = "$file,IN" ]
			then
				echo "This file has not been checked out yet."
			#else 
				#maybe check if the file is in the log at all
				#echo "sdfkjsdfjs"
			fi
			echo "$line" >&3
		done 4< "$statusfile"
		cat tempstatusfile > "$statusfile"
		exec 3>&-
		rm tempstatusfile
	else 
		if askYN "\"$file\" is not in the repository. Would you like to add it?"
		then
			add_to_repo $file
		else
			echo "not adding"
		fi
	fi
	#cat "$statusfile"

}

function selRepo() 
{
	echo
	echo "Which repository do you want to access?"
	counter=0
	for index in $(ls -d */)
	do
		let counter+=1
		echo "$counter) $index"
	done
	read number
	counter=0
	for index in $(ls -d */)
	do
		let counter+=1
		if [ $counter == $number ]
		then
			cd $index
			fileMenu
			cd ..
		fi 
	done
}

function fileMenu() 
{
	echo
	if [ "$(ls -1|wc -l)" == 0 ]
	then
		echo "No files to show"
	else
		make_statusfile
		echo "Files:"	
		ls -1 --color=auto
	fi

cat << FILE_MENU
	
     File Menu
--------------------
1) Log out file
2) Log in file
3) Add a file
4) Roll back a file to the previous version
0) Quit
FILE_MENU

read option

case $option in

1) check_out ;;

2) check_in ;;

3) add_to_repo ;;

0)  
echo 
echo "Thanks for your time!"
;; 

*) 
echo
echo "Not an acceptable option."
;;
esac
}




cd repo

exit=false
while [ ! "$exit" = true ]
do

cat << DOCUMENT

        Menu
--------------------
1) Create Repository
2) Delete Repository
3) Access Repository
0) Quit
DOCUMENT

read option

case $option in

1) addRepo ;;

2) delRepo ;;

3) selRepo ;;

0)  
echo 
echo "Thanks for your time!"
exit=true
;; 

*) 
echo
echo "Not an acceptable option. Try again:"
;;
esac

done

cd ..
exit 0
