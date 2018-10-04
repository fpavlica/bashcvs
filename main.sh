#! /bin/bash

function addRepo() 
{
	echo
	echo "Enter name of repository." 
	read name
	mkdir $name 
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
			rmdir $index
		fi
	done
}

statusfile=statusinfo
curr_repo="."

make_statusfile() {

	if [ ! -f "$statusfile" ]
	then
		touch "$statusfile"
		for file in $(ls)
		do
			echo "$file,F" >> "$statusfile"
		done
	fi
}

#logging a file out
check_out () {
	
	echo "enter name of the file to log out"
	read file #$file is the path of the file to be checked out, passed as the first variable to the function
	echo "enter the full path to the directory where you want to copy this file"
	read newpath #$newpath is where the file is to be copied, passed as the second variable to the function
		#TODO make sure newpath exists

	#if file exists
	if [ -f $file ]
	then 
		# copy it to the new path
		cp "$file" "$newpath"


		#make a temp new statusfile
		touch tempstatusfile
		exec 3<> ./tempstatusfile


		#sed -ie "s/$file,E/$file,F/" $statusfile #logs that the file is being edited in $statusfile
		while read line || [ -n "$line" ]	#should prevent skipping the last line
		do
			#echo "$line"
			if [ "$line" = "$file,F" ]
			then
				#change the line to $file,E
				line="$file,E"

			elif [ "$line" = "$file,E" ]
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
cat "$statusfile"
}


check_in () {
	echo "enter the name of the file you want to log in / update"
	read file  #$file is the path of the file to be checked in, passed as the first variable to the function
		#TODO make sure newpath exists

	#     ask to enter full path of the newly edited file
	echo "please enter the FULL path to the new file"
	read fullpath

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
			if [ "$line" = "$file,E" ]
			then
				cp "$fullpath" "$curr_repo/$file"
				#change the line to $file,E
				line="$file,F"
				echo "File checked in successfully."

			elif [ "$line" = "$file,F" ]
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
	 	echo "\"$file\" is not in the repo. adding it."
	 	cp "$fullpath" "$curr_repo/$file"
	fi
	cat "$statusfile"

}

function selRepo() 
{
	echo
	echo "Which repository do you want to access?"
	counter=0
	for index in $(ls)
	do
		let counter+=1
		echo "$counter) $index"
	done
	read number
	counter=0
	for index in $(ls)
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
;; 

*) 
echo
echo "Not an acceptable option."
;;
esac

cd ..
exit 0

