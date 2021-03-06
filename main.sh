#!/bin/bash

# File Name 			: Main.sh
# Authors 				: Alfie Hippisley (170009063), Archie Rutherford (170010226), František Pavlica (170020274)
# Date Created 			: 04/10/2018
# Date Last Modified 	: 11/10/2018
#
# File Purpose 			: This file forms the basis of our Bash CVS System source code.
#


# Declare varibles and give them attributes

declare -r diffdir=".diffs"				# This is the diffrent directory
declare -r logdir=".logs"				# This is the log directory
declare -r statusfile=".statusinfo"		# This is the status file
declare -r curr_repo="." 				# This is the current repo
declare -r outdir=".out"					# This is the output directory

# Function Purpose : Add/create a new repo
# Parameters : None

function addRepo() 
{
	echo

	# Ask user for name of repository
	echo "Enter name of repository."
	
	# Read in the name
	read name

	# Create the repo with appropriate log files
	mkdir $name 
	mkdir "$name/$diffdir"
	mkdir "$name/$logdir"
	mkdir "$name/$outdir"
	echo "The repository $name has been created."
}

# Function Purpose : Delete/remove a repo
# Parameters : None

function delRepo() 
{
	#make sure a repository has been created
	if [ -z "$(ls -d */ 2>/dev/null)" ] #if current directory is empty
	then
		echo "No repositories to delete"
		return 2;
	fi

	echo 

	# Ask user to select repository to delete
	echo "Which repository do you want to delete?"

	# This loop displays all repos to the user
	counter=0
	for index in $(ls -d */ 2>/dev/null)
	do
		let counter+=1
		echo "$counter) $index"
	done

	# Read the user input
	read number
	found=1

	# Now lets check that they actually wanted to delete that repo
	counter=0
	for index in $(ls -d */ 2>/dev/null)
	do
		let counter+=1
		if [ $counter == $number ]
		then
			if askYN "Are you sure that you want to delete the repository $index and all files in it?"; then
				if rm -r $index ;then
					echo "Removed successfully"
				else 
					echo "Removal failed"
				fi
			fi
		fi
	done
}

# Function Purpose : Archive a repo
# Parameters : None

function archRepo()
{
	#Make sure a repository has been created
	if [ -z "$(ls -d */ 2>/dev/null)" ] #if current directory is empty
	then
		echo "No repositories have been created yet"
		return 2;
	fi

	echo

	# Ask the user to select a repo to archive
	echo "Which repository do you want to Archive?"

	# This loop displays all repos to the user
	counter=0
	for index in $(ls -d */ 2>/dev/null)
	do
		let counter+=1
		echo "$counter) $index"
	done

	# Read the user input
	read number

	# This loop gets the user to name the export zip they want to archive
	counter=0
	for index in $(ls ) #-d */ 2>/dev/null)
	do
		let counter+=1
		if [ $counter == $number ]
		then

			filename=$index

			# Enter path
			echo "Enter the full path of the directory to export to:"
			read filepath

			# Export the repo/check that it exists
			if [ -d "$filepath" ]
			then
				echo "Archiving..."
			else
				echo "Directory does not exist. Archiving to the folder where this program is located."
				filepath=".."
			fi
				zip -r "$filename.zip" "$index" -x "*/.*" > /dev/null ;	mv "./$filename.zip" "$filepath"; echo "Archiving done"  &
		fi 
	done
}

# Function Purpose : Asks the user yes or no
# Parameters : The yes/no question to ask

askYN () {

	# Get user input
 	while [ 0 ] # oof
 	do
		echo "$1 [Y/n]"

	 	read choice
 		case $choice in
 			Y|y)
			 	#true
				return 0 ;;
			N|n) 
				#false
				return 1 ;;
			*) echo "Invalid option. Try again:" ;; # Perform error checking here
 		esac
 	done
}

# Function Purpose : Make a status file
# Parameters : None

make_statusfile() {

	#make a out/in status file if it is not made yet
	if [ ! -f "$statusfile" ]
	then
		touch "$statusfile"
		for file in $(ls)
		do
			echo "$file,IN" >> "$statusfile"
			# $file,OUT means the file is being edited, $file,IN means it's finished until further changes are needed
		done
	fi
}

# Function Purpose : Check out a fle
# Parameters : None

check_out () {
	
	# Ask user for the name of the file they want to log out
	echo "enter name of the file to log out"

	read file 
	
	#$file is the path of the file to be checked out, passed as the first variable to the function
	#echo "enter the full path to the directory where you want to copy this file"

	#if file exists
	if [ -f $file ]
	then 
		# copy it to the new path
		# cp "$file" "$newpath"


		#make a temp new statusfile
		tempstatusfile=".tempstatusfile"
		touch "$tempstatusfile"
		exec 3<> "./$tempstatusfile"

		#should prevent skipping the last line # -u 4 makes it read from FD 4
		while read -u 4 line || [ -n "$line" ]
		do
			#echo "$line"
			if [ "$line" = "$file,IN" ]
			then
				#change the line to $file,OUT
				line="$file,OUT"
				mkdir "$outdir" 2>/dev/null # makes the directory and if it exists already hide the error message
				cp "$file" "$outdir" #copy the file to the editing directory


				#optionally open the file in sublime text if it is installed
				if askYN "Would you like to open this file in Nano?"
				then
					# if ! vi $file; then #if vi fails - possibly not installed
						#originally we would try to open this in sublime so this check made more sense
						# but that launched it in parallel or something 
						# and for some reason made the file at &3 too busy to remove
						#it doesn't make as much sense anymore because vim is likely to be installed by default
					#	echo "Vim is not installed. You can install it using \"sudo apt install vim\""
					#	echo "Attempting to launch nano editor to edit this file. Press the return key to continue."
					#	read -n 1 -sr #-s hides input, -r skips escape chars, -n 1 stops reading after 1 char 
						nano "$outdir/$file"
					#fi
				fi
					echo "You can edit this file later by opening $(pwd)/$outdir/$file in your favourite text editor."
				#fi

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


# Function Purpose : Create a new file in the repository
# Parameters : None
create_file () {
	echo "Please enter the name of the file you would like to create:"
	read name
	touch "$name"
	
	echo "$name,IN" >> $statusfile
	echo "Added $name to the current repository."
}


# Function Purpose : Add an external file to the repository
# Parameters : optionally a new name for the file
add_file () {

	# expecting a name of the new file that should be added to the repository as parameter $1, if the name should be changed

	ls -1 # display contents so the user can make sure they're in the right repository and are trying to add the right files
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

# Function Purpose : Show options for adding a file to the repository
# Parameters : None

add_to_repo () {
	exit=false
	while [ ! "$exit" = true ]
	do
	cat << DOCUMENT

        Options
--------------------
1) Add an existing file to the repository
2) Create a new file in the repository
0) Cancel
DOCUMENT

	# Read the user input
	read option

	case $option in

	1) add_file; exit=true ;;

	2) create_file; exit=true ;;

	# leave
	0) exit=true ;; 

	# Invalid input
	*) 
	exit = false;
	echo
	echo "Not an acceptable option. Try again:"
	;;
	esac
	done
	exit=false
}

# Function Purpose : Check in a file to repo
# Parameters : None

check_in () {
	mkdir "$logdir" 2>/dev/null #make the directory if it deosn't exist yet and discard the error message if it does
	echo "enter the name of the file you want to log in / update"
	read file 

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
				diffpath="$diffdir/$file-$seconds.diff"
				diff "$outdir/$file" "$curr_repo/$file" > "$diffpath" #save a diff file
				cp "$outdir/$file" "$curr_repo/$file" # copy the file from the work directory to the current dirrectory
				rm "$outdir/$file" #remove the file from the work directory

				if askYN "Would you like to add a short comment about this edit to the log file?"
				then
					echo "Enter your comment:"
					read comment
				fi
			 	echo "$(date -d@$seconds): $comment" >> "$logdir/$file.rlog" #rlog stands for readable log
			 	if [ ! -f "$logdir/$file.dlog" ] ; then
			 		touch "$logdir/$file.dlog"
			 	fi

			 	#adding the name of the diff file to the top of a log file
			 	echo "$diffpath
$(cat "$logdir/$file.dlog")" > "$logdir/$file.dlog" #dlog stands for diff log

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

# Function Purpose : Roll back version of file
# Parameters : None

roll_back () {
	echo "enter the name of the file you want to roll back to the previous version"
	read file 

	#if file exists
	if [ -f "$file" ] && [ -f "$logdir/$file.dlog" ] 
	then 
		read diffname < "$logdir/$file.dlog"
		patch "$file" "$diffname"
		sed -i -e '1,1d' "$logdir/$file.dlog"
		seconds="$(date +%s)"
	 	echo "$(date -d@$seconds): Rolled back" >> "$logdir/$file.rlog"
	else 
	 	echo "\"$file\" is not a correct file path or there's nothing to roll back to."
	fi
}

# Function Purpose : Edit a file that has been logged out
# Parameters : None

edit_file () {

	echo "enter the name of the logged out file you want to edit"
	read file 
	filelocation="$outdir/$file"

	#if file exists
	if [ -f $file ]
	then 

		while read -u 4 line || [ -n "$line" ]	#should prevent skipping the last line
		do
			#echo "$line"
			if [ "$line" = "$file,OUT" ]
			then
				nano "$filelocation"
			elif [ "$line" = "$file,IN" ]
			then
				echo "This file has not been checked out yet."
			fi
		done 4< "$statusfile"
	else 
		if askYN "\"$file\" is not in the repository. Would you like to add it?"
		then
			add_to_repo "$file"
		else
			echo "not adding"
		fi
	fi
}

# Function Purpose : Display file 
# Parameters : None

display_file () {

	# Ask user for name of file they want to display
	echo "enter the name of the file you want to display"
	read file 

	#if file exists
	if [ -f "$file" ]
	then 
		if [ -f "$outdir/$file" ]
		then
			less "$outdir/$file"
		else
			less "$file"
		fi
	else 
	 	echo "\"$file\" is not a correct file path." # Error check
	fi
}


# Function Purpose : Display a log file
# Parameters : None

display_log () {

	# Ask user for name of file they want to display
	echo "enter the name of the file whose log you want to display"
	read file 

	#if file exists
	if [ -f "$file" ]
	then 
		if [ -f "$logdir/$file.rlog" ]
		then
			less "$logdir/$file.rlog"
		else
			echo "\"$file\" does not have a log entry. This might mean it heas not been edited yet"
		fi
	else 
	 	echo "\"$file\" is not a correct file path." # Error check
	fi
}

# Function Purpose : Select a repo
# Parameters : None

function selRepo() 
{
	#Make sure a repository has been created
	if [ -z "$(ls -d */ 2>/dev/null)" ] #if current directory is empty
	then
		echo "No repositories have been created yet"
		return 2;
	fi

	# Ask the user what repo they would like to access
	echo
	echo "Which repository do you want to access?"

	counter=0

	# Display list of options
	for index in $(ls -d */  2>/dev/null)
	do
		let counter+=1
		echo "$counter) $index"
	done

	# Read that input
	read number

	# Show file menu
	counter=0
	for index in $(ls -d */  2>/dev/null)
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

# Function Purpose : Show a menu regarding file operations
# Parameters : None

function fileMenu() 
{
	exit=false		
	while [ ! $exit = "true" ]
	do
	echo
	if [ "$(ls -1|wc -l)" == 0 ]
	then
		echo "No files to show" # If there are no files to show
	else
		make_statusfile
		echo "Files:"	
		ls -1 --color=auto
	fi

	cat << FILE_MENU
		
     File Menu
--------------------
1) Add a file
2) Log out file
3) Log in file
4) Edit a file that has been logged out
5) Display the contents of a file
6) Roll back a file to the previous version
7) Display a file log with comments about edits
0) Go back to the main menu
FILE_MENU

	# Read in the user input
	read option

	# Go put input down a case system
	case $option in

	1) add_to_repo ;;

	2) check_out ;;

	3) check_in ;;

	4) edit_file ;;

	5) display_file ;;

	6) roll_back ;;

	7) display_log ;;

	# Exit script
	0)  
	exit=true
	;; 

	# Invalid input
	*) 
	echo
	echo "Not an acceptable option."
	;;
	esac
	done
	exit=false
}

#make a direcory for the repositories if it does not exist yet; if it does, discard the error message 
mkdir repo 2> /dev/null
cd repo

exit=false
while [ ! "$exit" = true ]
do

# Display the primary main menu
cat << DOCUMENT

        Menu
--------------------
1) Create Repository
2) Delete Repository
3) Access Repository
4) Archive Reposiory
0) Quit
DOCUMENT

# Read the user input
read option

case $option in

1) addRepo ;;

2) delRepo ;;

3) selRepo ;;

4) archRepo ;;

# Exit program
0)  
echo 
echo "Thanks for your time!"
exit=true
;; 

# Invalid input
*) 
echo
echo "Not an acceptable option. Try again:"
;;
esac
done

# Exit Script For Good
cd ..
exit 0