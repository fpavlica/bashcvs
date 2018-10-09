#! /bin/bash

editor="subl" #default file editor
diffdir=".diffs"
logdir=".logs"

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
			pass=false
		 	while [ "$pass" = false ]
		 	do

			 	echo "Are you sure that you want to delete the repository $index and all files in it? (Y/n)"
			 	read choice
		 		case $choice in
		 			Y|y) # TODO add file to repo, ask for source
						rm -r $index
						pass=true ;;
					N|n) echo "not removing"
						pass=true	;;
					*) echo "Invalid option. Try again:"
						pass=false ;;
		 		esac
		 	done
		fi
	done
}

statusfile=".statusinfo"
curr_repo="." #eh probably change this
outdir="./out"

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

		cp "$file" "$outdir" #copy the file to the editing directory

		#make a temp new statusfile
		touch tempstatusfile
		exec 3<> ./tempstatusfile


		while read line || [ -n "$line" ]	#should prevent skipping the last line
		do
			#echo "$line"
			if [ "$line" = "$file,IN" ]
			then
				#change the line to $file,OUT
				line="$file,OUT"

			elif [ "$line" = "$file,OUT" ]
			then
				echo "This file is already being edited."
			#else 
				#maybe check if the file is in the log at all
				#echo "sdfkjsdfjs"
			fi
			echo "$line" >&3
		done < "$statusfile"
		cat tempstatusfile > "$statusfile"
		exec 3>&-
		rm tempstatusfile
	else 
	 	echo "\"$file\" is not a correct file path."
	fi
#cat "$statusfile"
}

add_to_repo () {
	# expecting a name of the new file that should be added to the repository as parameter $1

	#ask for source
	echo "Please enter the full path of the file you would like to add"
	read fToAdd
	if [ -f "$fToAdd" ]
	then
		cp "$fToAdd" "$curr_repo" # copy the file to the current folder
		echo "$1,IN" >> $statusfile
		echo "Added $fToAdd to the current repository as $1"
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
		while read line || [ -n "$line" ]	#should prevent skipping the last line
		do
			#echo "$line"
			if [ "$line" = "$file,OUT" ]
			then
				seconds="$(date +%s)"
				diff "$outdir/$file" "$curr_repo/$file" > "$diffdir/$file-$seconds.diff" #save a diff file
				cp "$outdir/$file" "$curr_repo/$file" # copy the file from the work directory to the current dirrectory


			 	pass=false
			 	while [ "$pass" = false ]
			 	do
					echo "Would you like to add a short comment about this edit to the log file? (Y/n)"
				 	read choice
			 		case $choice in
			 			Y|y)
							echo "Enter your comment:"
							read comment
							pass=true ;;
						N|n) 
							pass=true	;;
						*) echo "Invalid option. Try again:"
							pass=false ;;
			 		esac
			 	done
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
		done < "$statusfile"
		cat tempstatusfile > "$statusfile"
		exec 3>&-
		rm tempstatusfile
	else 
	 	pass=false
	 	while [ "$pass" = false ]
	 	do

		 	echo "\"$file\" is not in the repository. Would you like to add it? (Y/n)"
		 	read choice
	 		case $choice in
	 			Y|y) # TODO add file to repo, ask for source
					add_to_repo $file
					pass=true ;;
				N|n) echo "not adding"
					pass=true	;;
				*) echo "Invalid option. Try again:"
					pass=false ;;
	 		esac
	 	done
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
0) Quit
FILE_MENU

read option

case $option in

1) check_out ;;

2) check_in ;;

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

pass=false
while [ "$pass" = false ]
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

1) addRepo; pass=true ;;

2) delRepo; pass=true ;;

3) selRepo; pass=true ;;

0)  
echo 
echo "Thanks for your time!"
pass=true
;; 

*) 
echo
echo "Not an acceptable option. Try again:"
pass=false
;;
esac

done

cd ..
exit 0
