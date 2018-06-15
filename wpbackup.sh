#!/bin/bash

# wpbackup.sh Backs up wordpress sites on the server level retaining
# monthly, weekly, and two days of backups.
#
# Copyright (C) 2018 Dylan Medina
#              http://dylanmedina.com
#              dylan (at) dylanmedina (dot) com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details:
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses/.

usage="\Backs up Wordpress files and database from source dir"
usage+="to target dir, creating any subdirectories as needed. "
usage+="Day backup replaces day_old, and weekly and monthly when needed"
usage+="\t usage: wpbackup.sh -s source_dir -t target_dir"

while getopts ":s:t:" opt
do
   case ${opt} in
      s ) source=$OPTARG ;;
      t ) target=$OPTARG ;;
      \? ) echo $usage ;;
   esac
done
shift $((OPTIND -1))

# Do daily backup.
# Check if we've got any backups yet. IF not abort. Something is amiss.
if [[ ! `find $target/day` ]]
then
   echo "Something is wrong. Either you've not started with manual backups,"
   echo "or something's wrong with the files. Recommend a manual check."
   echo "exiting..."
   exit 0
fi

if [[ `find $target/day_old` ]]
then
   echo "Removing old backup..."
   rm -r $target/day_old
fi

echo "Creating Backup Directory at: "$target/day
mv $target/day $target/day_old
mkdir $target/day
echo "Copying wp-content..."
cp -r $source/wp-content $target/day
echo "Copying config file..."
cp $source/wp-config.php $target/day/wp-config.php
if [[ ! `find $source/.htaccess` ]]
then
   echo "No HTACCESS file to copy."
else
   echo "Copying htaccess file."
   cp $source/.htaccess $target/day/.htaccess
fi
echo "File backup completed."
echo "Beginning database backup..."

mysqldump dpm_wordpress > $target/day/dump.sql
echo "Database backup created."

# Check if monthly backup exists and is 30 days old and remove as needed.
if [[ `find $target/month -mtime 30` || ! `find $target/month` ]]
then
   if [[ `find $target/month` ]]
   then
      rm -r $target/month
   fi
   cp -r $target/day $target/month
elif [[ `find $target/week -mtime 7` || ! `find $target/week` ]]
then
   if [[ `find $target/week` ]]
   then
      rm -r $target/week
   fi
   cp -r $target/day $target/week
fi
