#! /bin/bash

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

1)  
echo
echo "Enter name of repository." 
read name
mkdir $name 
;;

2) 
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
;;

3) 
echo
echo "Which repository do you want to access?"
counter=0
for index in $(ls)
do
	let counter+=1
	echo "$counter) $index"
done
read number
for index in $(ls)
do
	let counter+=1
	if [ $counter == $number ]
	then
		cd $index
		for $files in $(ls)
		do
			let number+=1
			echo "$number) $files"
		done
		cd ..
	fi 
done
;;

0)  
echo 
echo "Thanks for your time!"
exit 0
;; 

*) 
echo
echo "Not an acceptable option."
;;
esac

cd ..
exit 0