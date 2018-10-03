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

