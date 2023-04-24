#!/bin/bash
#-----------[ commands used by this script ]-----------
#
# The pupose of this script is to download the MaxMind free GeoIP database
# and prepare files ready to be used by nftables rulesets.
#
# User shoudl adapt this script to his needs.
# To use MaxMind database user have to be registered and create a free account
# on MaxMind website.
#
# This script ought to be placed in /usr/local/bin.
# It stores the files generated 
# -------> User have to modify those script variables.
#
# List of Allowed Countries to filter IP addresses.
# This selects the countries allowed by nftables afterward
AllowedCountriesList=(AT,AU,BE,DE,DK,ES,FI,FR,GB,IE,IS,IT,JP,LU,MC,NL,NO,PT,SE,VA)
#
#
# Filename of this script.
ScriptName=`basename "$0"`
# Semantic version number of this script.
ScriptNameVersion="v0.0.9"
# User configuration file.
geo_conf="/etc/$ScriptName.conf"
# Error log filename. This file logs errors in addition to the systemd Journal.
LogFile="/var/log/$ScriptName.log"
# Download URL.
MaxMindDonwloadZipUrl="https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=s2a3dT8OGRAoAtLI&suffix=zip"
# Current date/time.
DateTime="$(date +"%Y-%m-%d %H:%M:%S")"

# Files to remove once the archive has been extracted.
FilesToDelete="COPYRIGHT.txt,LICENSE.txt,GeoLite2-Country-Locations-zh-CN.csv,GeoLite2-Country-Locations-fr.csv,GeoLite2-Country-Locations-es.csv,GeoLite2-Country-Locations-de.csv,GeoLite2-Country-Locations-pt-BR.csv,GeoLite2-Country-Locations-ja.csv,GeoLite2-Country-Locations-ru.csv"

#Date of Database donwload
datedbdown="$(date +"%Y%m%d")"

# Ramdisk System MountPoint
RamDiskMountPoint="/tmp/RamDisk"


# Default cleaned database to be used with nft in case of reboot.
DbDir="/var/spool/$ScriptName"

#-----------[ commands used by this script ]-----------
User=`whoami`
Unzip=`which unzip`
Join=`which join`
Sort=`which sort`
Grep=`which grep`
Wget=`which wget`
Mount=`which mount`

Checks () {
#1. Checks if user is allowed to use sudo without interaction.
CheckSudo=`time timeout 1 sudo chmod --help`
# if [ $? -ne 0 ]; then
#	echo "$User is not allowed to run sudo commands" >>$LogFile
#	else
#	sudo echo "$User seems to be allowed to run sudo commands without any password" >>$LogFile
#fi
#2. Check if log file alread exists, if not create it with current date and also checks at the same time that the script is allowed to create it.
if [ ! -f $LogFile ]; then
	sudo echo "------------- [ Launch $ScriptName on $DateTime ]------------" >$LogFile
	if [ ! $? -eq 0 ]; then
		echo "Unable to create $LogFile"
		exit 1
	fi
	else
	sudo echo "------------- [ On $DateTime $ScriptName has found an existing $LogFile, launch a rotate process ]------------" >>$LogFile
	sudo echo "---> [ STEP 01 Initial checks ]------------" >>$LogFile
	#Put the LogRotate command here
fi
#3. Checks if used programms are accessible with this user privilege
if [ -x $Mount ]; then
	echo "$Mount can be launched with this $User account" >>$LogFile
	else
	sudo echo "Unable to find $Mount or $User isn't allowed to launch it" >>$LogFile
	exit 1
fi
if [ -x $Unzip ]; then
	sudo echo "$Unzip can be launched with this $User account" >>$LogFile
	else
	sudo echo "Unable to find $Unzip or $User isn't allowed to launch it" >>$LogFile
	exit 1
fi
if [ -x $Join ]; then
	sudo echo "$Join can be launched with this $User account" >>$LogFile
	else
	sudo echo "Unable to find $Join or $User isn't allowed to launch it" >>$LogFile
	exit 1
fi
if [ -x $Sort ]; then
	echo "$Sort can be launched with this $User account" >>$LogFile
	else
	echo "Unable to find $Sort or $User isn't allowed to launch it" >>$LogFile
	exit 1
fi
if [ -x $Grep ]; then
	echo "$Grep can be launched with this $User account" >>$LogFile
	else
	echo "Unable to find $Grep or $User isn't allowed to launch it" >>$LogFile
	exit 1
fi
if [ -x $Wget ]; then
	echo "$Wget can be launched with this $User account" >>$LogFile
	else
	echo "Unable to find $Wget or $User isn't allowed to launch it" >>$LogFile
	exit 1
fi
#4 Create RamDisk
sudo mountpoint $RamDiskMountPoint
if [ $? -ne 0 ]; then
sudo mkdir $RamDiskMountPoint
if [ -d $RamDiskMountPoint ]; then echo "$ScriptName is able create a RamDisk mountpoint in $RamDiskMountPoint" >> $LogFile; else echo "unable to create mounting point in $RamDiskMountPoint">> $LogFile; fi
sudo chmod 660 $RamDiskMountPoint
sudo mount -t tmpfs -o size=512m MyRamDisk $RamDiskMountPoint
if [ $? -eq 0 ]; then echo "$ScriptName has attached the RamDisk" >> $LogFile; else echo "unable to mount the RamDisk">> $LogFile; fi
fi
MyRamDiskMounted=`mount | tail -n 1`
echo -e "RamDisk has been attached with the following parameters :\n$MyRamDiskMounted" >>$LogFile

#5 Checks if used directories exists if not create them using sudo
# Default temporary directory where this script ouptuts its working files.
# Default temporary directory where this script ouptuts its working files.
TmpDir="$RamDiskMountPoint"
if [ -d $TmpDir ]; then
sudo touch $TmpDir/TstFile.out
	if [ $? -eq 0 ]; then echo "$ScriptName is able to write files in $TmpDir" >> $LogFile; fi
sudo rm $TmpDir/TstFile.out
	if [ $? -eq 0 ]; then echo "$ScriptName is also able to delete files in $TmpDir" >> $LogFile; fi
fi
if [ -d $DbDir ]; then
sudo touch $DbDir/TstFile.out
	if [ $? -eq 0 ]; then echo "$ScriptName is able to write files in $DbDir" >> $LogFile; fi
sudo rm $DbpDir/TstFile.out
	if [ $? -eq 0 ]; then echo "$ScriptName is also able to delete files in $DbDir" >> $LogFile; fi
fi
}

Cleanup () {
sudo umount $RamDiskMountPoint
if [ $? -eq 0 ]; then echo "The RamDisk has been detached from $RamDiskMountPoint" >> $LogFile; else echo "unable to unmount the RamDisk from $RamDiskMountPoint">> $LogFile; fi
sudo rm -rf $RamDiskMountPoint >>$LogFile
}

DownloadDb() {
#Date of Database donwload
DateDbDown="$(date +"%Y%m%d")-MaxMindDb.zip"
if [ ! -s "$TmpDir/$DateDbDown" ]; then
	sudo echo "---> [ STEP 02 Download Database ]------------" >>$LogFile
	sudo echo "Downloading MaxMind database GeoLite2-Country from https://maxmind.com." >>$LogFile
	if [ "$silent" = "yes" ]; then
		$Wget -q -a $LogFile -O $TmpDir/$DateDbDown $MaxMindDonwloadZipUrl
			if [ $? -ne 0 ]; then
				echo "Failed to download $MaxMindDonwloadZipUrl. Exiting..." >>$LogFile
				exit 1
			fi
	else
		$Wget -nv -a $LogFile -O $TmpDir/$DateDbDown $MaxMindDonwloadZipUrl
			if [ $? -ne 0 ]; then
				echo "Failed to download $MaxMindDonwloadZipUrl. Exiting..." >>$LogFile
				exit 1
			fi
	fi
else
sudo echo "---> [ STEP 02 Database Already exists download canceled ]------------" >>$LogFile
sudo echo -e "The database has already been downloaded today the file exists; using existing file:\n$TmpDir/$DateDbDown" >>$LogFile
fi
# Launch archive extraction
ExtarctArchive
}

ExtarctArchive() {
sudo echo "---> [ STEP 03 Archive extraction ]------------" >>$LogFile
	if [ -s "$TmpDir/$DateDbDown" ]; then
		cd $TmpDir
			if [ $? -ne 0 ]; then
				echo "Unable to access the $TmpDir" >>$LogFile
				exit 1
			fi
		echo "Extract archive named $DateDbDown in $TmpDir" >>$LogFile
			$Unzip -j -o "$TmpDir/$DateDbDown"
			if [ $? -ne 0 ] || [ ! -s "$DateDbDown" ]; then
				echo "Unable to extract archive" >> $LogFile
				exit 1
			else
				IFS=, read -r -a array <<< "$FilesToDelete"
				rm -v "${array[@]}" >>$LogFile
				ls -lh $TmpDir>>$LogFile
			fi

	else
		echo -e "The Downloaded archive file $DateDbDown has not been found in $TmpDir\nExiting..." >>$LogFile
		exit 1
	fi
}

SortingCleaningFiles() {
sudo echo "---> [ STEP 04 Transform all files, Ordering and Filtering ]------------" >>$LogFile
MaxmindDownloadedDb="MaxMindDb.zip"
MaxMindLocation="GeoLite2-Country-Locations-en.csv"
MaxMindIPv6Block="GeoLite2-Country-Blocks-IPv6.csv"
MaxMindIPv4Block="GeoLite2-Country-Blocks-IPv4.csv"
FilteredIPv6List="Filtered_IPv6.csv"
FilteredIPv4List="Filtered_IPv4.csv"

# Delete first line of each files as it describes the columns names.
sudo echo "Delete first line of file $MaxMindLocation" >>$LogFile
sed -i '1d' $MaxMindLocation
sudo echo "Delete first line of file $MaxMindIPv6Block" >>$LogFile
sed -i '1d' $MaxMindIPv6Block
sudo echo "Delete first line of file $MaxMindIPv4Block" >>$LogFile
sed -i '1d' $MaxMindIPv4Block

sudo echo "join data from $MaxMindLocation and  $MaxMindIPv6Block to create $FilteredIPv6List" >>$LogFile
join -t, -1 1 -2 2  <(cut -d, -f1,5 $MaxMindLocation) <(cut -d, -f1,2 $MaxMindIPv6Block | sort -t, -k2 -n) --nocheck-order | sort -t, -k2| cut -d, -f2,3>$FilteredIPv6List
sudo echo "create each country file from $FilteredIPv6List" >>$LogFile
while IFS=, read -r CountryCode Subnet ; do 
    echo "$Subnet" >> "$TmpDir/$CountryCode".nft6
done < $FilteredIPv6List

sudo echo "join data from $MaxMindLocation and  $MaxMindIPv4Block to create $FilteredIPv4List" >>$LogFile
join -t, -1 1 -2 2  <(cut -d, -f1,5 $MaxMindLocation) <(cut -d, -f1,2 $MaxMindIPv4Block | sort -t, -k2 -n) --nocheck-order | sort -t, -k2| cut -d, -f2,3>$FilteredIPv4List
sudo echo "create each country file from $FilteredIPv4List" >>$LogFile
while IFS=, read -r CountryCode Subnet ; do 
    echo "$Subnet" >> "$TmpDir/$CountryCode".nft4
done < $FilteredIPv4List
}
SelectCountriesList () {
sudo echo "---> [ STEP 04 Select list of countries ]------------" >>$LogFile
DestDir=$TmpDir"/DestTempDir"
mkdir -p $DestDir
IFS=',' read -ra array <<<"$AllowedCountriesList"
for CountryCode in "${array[@]}"; do
#	cp -v "$TmpDir/$CountryCode".nft4 "$DestDir">>$LogFile
#	cp -v "$TmpDir/$CountryCode".nft6 "$DestDir">>$LogFile
	cp "$TmpDir/$CountryCode".nft4 "$DestDir"
	cp "$TmpDir/$CountryCode".nft6 "$DestDir"
done

}

InsertCommas () {
sudo echo "---> [ STEP 05 Insert commas and join lines of files located in $DestDir ]------------" >>$LogFile
shopt -s nullglob
# create an array with all the filer/dir inside ~/myDir
sudo echo "---> [ STEP 05a modify IPv4 files ]------------" >>$LogFile
# rm -v "$TmpDir"/*.nft4>>$LogFile
rm "$TmpDir"/*.nft4
Array=($DestDir/*.nft4)
# iterate through array using a counter
for ((i=0; i<${#Array[@]}; i++)); do
	FileName=`basename ${Array[$i]}`
    awk 'BEGIN{RS="";FS="\n";OFS=", "}{$1=$1}7' "${Array[$i]}" >"$TmpDir/$FileName"
	Country=`echo $FileName | cut -d. -f1`
	BeginOfFile="ipv4_"$Country" = {"
	sed -i -e 's/^/'"$BeginOfFile"'\n/' "$TmpDir/$FileName"
	sed -i -e '$a  }' "$TmpDir/$FileName"
	sed -i -e 'N;s/\n//' "$TmpDir/$FileName"
#	rm -v ${Array[$i]} >>$LogFile
done
sudo echo "---> [ STEP 05b modify IPv6 files ]------------" >>$LogFile
# rm -v "$TmpDir"/*.nft6>>$LogFile
rm "$TmpDir"/*.nft6
Array=($DestDir/*.nft6)
# iterate through array using a counter
for ((i=0; i<${#Array[@]}; i++)); do
	FileName=`basename ${Array[$i]}`
    awk 'BEGIN{RS="";FS="\n";OFS=", "}{$1=$1}7' "${Array[$i]}" >"$TmpDir/$FileName"
	Country=`echo $FileName | cut -d. -f1`
	BeginOfFile="ipv6_"$Country" = {"
	sed -i -e 's/^/'"$BeginOfFile"'\n/' "$TmpDir/$FileName"
	sed -i -e '$a  }' "$TmpDir/$FileName"
	sed -i -e 'N;s/\n//' "$TmpDir/$FileName"
#	rm -v ${Array[$i]} >>$LogFile
done
# rm -v "$DestDir"/*.nft4>>$LogFile
# rm -v "$DestDir"/*.nft6>>$LogFile
# rm -v "$TmpDir"/*.nft4>>$LogFile
sudo echo "Delete directory $DestDir and its content" >>$LogFile
rm -rf $DestDir
# rm -vrf $DestDir>>$LogFile

}

ArchiveFiles () {
sudo echo "---> [ STEP 06 archive files ]------------" >>$LogFile

}

MainProg() {
# Start a timer for the script run time.
	local starttime=$(date +%s)
#Run Checks procedure
Checks
#Run DownloadDb procedure (Download database if necesary) and extracts files if database exists
DownloadDb
#Sort and clean files
SortingCleaningFiles
#Select Countries according to the AllowedCountriesList variables
SelectCountriesList
#Insert commas and join lines
InsertCommas 
#Cleanup all the mess
# Cleanup


# Display the script run time.
echo "Script run time : $(($(date +%s) - $starttime))s">>$LogFile	
}

MainProg "$@"

exit 0
