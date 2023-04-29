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
#
# There is only 2 variables to modify :
# 1. The list of countries that have to be allowed in INPUT
# 2. The MaxMind Licence key
#
#-----------[ User have to modify those script variables ]-----------
#
# List of Allowed Countries to filter IP addresses.
# This selects the countries allowed by nftables afterward
AllowedCountriesList=(AT,AU,BE,DE,DK,ES,FI,FR,GB,IE,IS,IT,JP,LU,MC,NL,NO,PT,SE,VA)
# MaxMind License Key
MaxMindKey="<Put_Your_Key_Here>"
#
#-----------[ User should not modify anything below this line ]-----------
#
# Filename of this script.
ScriptName=`basename "$0"`
# Version number of this script.
ScriptNameVersion="0.0.14"
# Error log filename. This file logs errors in addition to the systemd Journal.
LogFile="/var/log/$ScriptName.log"
# Download URL.
MaxMindDonwloadZipUrl="https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=$MaxMindKey&suffix=zip"
#Checksum File
MMCheckSumFile="https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=$MaxMindKey&suffix=zip.sha256"
# Current date/time.
DateTime="$(date +"%d/%m/%Y %H:%M:%S")"

# Files to remove once the archive has been extracted.
FilesToDelete="COPYRIGHT.txt,LICENSE.txt,GeoLite2-Country-Locations-zh-CN.csv,GeoLite2-Country-Locations-fr.csv,GeoLite2-Country-Locations-es.csv,GeoLite2-Country-Locations-de.csv,GeoLite2-Country-Locations-pt-BR.csv,GeoLite2-Country-Locations-ja.csv,GeoLite2-Country-Locations-ru.csv"

# Ramdisk System MountPoint
RamDiskMountPoint="/tmp/RamDisk"

# Default archives storage directory
# It could be be used with nftables in case of reboot.
DbDir="/var/spool/$ScriptName"

#-----------[ commands used by this script ]-----------
User=`whoami`
Unzip=`which unzip`
Join=`which join`
Sort=`which sort`
Grep=`which grep`
Wget=`which wget`
Mount=`which mount`
ShaCheck=`which sha256sum`

Checks () {
#1. Check if log file alread exists, if not create it with current date and also checks at the same time that the script is allowed to create it.
if [ ! -f $LogFile ]; then
	echo "------------- [ Launch $ScriptName on $DateTime ]------------" >$LogFile
	if [ ! $? -eq 0 ]; then
		echo "Unable to create $LogFile"
		exit 1
	fi
	else
	echo "------------- [ On $DateTime $ScriptName has found an existing $LogFile, launch a rotate process ]------------" >>$LogFile
	
	#Put the LogRotate command here
fi
echo "---> [ STEP 01 Initial checks ]------------" >>$LogFile
#2. Checks if used programms are accessible with this user privilege
if [ -x $Mount ]; then
	echo "$Mount can be launched with this $User account" >>$LogFile
	else
	echo "Unable to find $Mount or $User isn't allowed to launch it" >>$LogFile
	exit 1
fi

if [ -x $Unzip ]; then
	echo "$Unzip can be launched with this $User account" >>$LogFile
	else
	echo "Unable to find $Unzip or $User isn't allowed to launch it" >>$LogFile
	exit 1
fi

if [ -x $Join ]; then
	echo "$Join can be launched with this $User account" >>$LogFile
	else
	echo "Unable to find $Join or $User isn't allowed to launch it" >>$LogFile
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

if [ -x $ShaCheck ]; then
	echo "$ShaCheck can be launched with this $User account" >>$LogFile
	else
	echo "Unable to find $ShaCheck or $User isn't allowed to launch it" >>$LogFile
	exit 1
fi

#3 Create RamDisk
mountpoint -q $RamDiskMountPoint
if [ $? -ne 0 ]; then
mkdir $RamDiskMountPoint
if [ -d $RamDiskMountPoint ]; then echo "$ScriptName is able create a RamDisk mountpoint in $RamDiskMountPoint" >> $LogFile; else echo "unable to create mounting point in $RamDiskMountPoint">> $LogFile; fi
chmod 660 $RamDiskMountPoint
mount -t tmpfs -o size=512m MyRamDisk $RamDiskMountPoint
if [ $? -eq 0 ]; then echo "$ScriptName has attached the RamDisk" >> $LogFile; else echo "unable to mount the RamDisk">> $LogFile; fi
fi
MyRamDiskMounted=`mount | tail -n 1`
echo -e "RamDisk has been attached with the following parameters :\n$MyRamDiskMounted" >>$LogFile

#4 Checks if used directories exists if not create them 
# Default temporary directory where this script ouptuts its working files.
TmpDir="$RamDiskMountPoint"
if [ -d $TmpDir ]; then
touch $TmpDir/TstFile.out
	if [ $? -eq 0 ]; then echo "$ScriptName is able to write files in $TmpDir" >> $LogFile; fi
rm $TmpDir/TstFile.out
	if [ $? -eq 0 ]; then echo "$ScriptName is also able to delete files in $TmpDir" >> $LogFile; fi
fi

if [ -d $DbDir ]; then
touch $DbDir/TstFile.out
	if [ $? -eq 0 ]; then echo "$ScriptName is able to write files in $DbDir" >> $LogFile; fi
rm $DbpDir/TstFile.out
	if [ $? -eq 0 ]; then echo "$ScriptName is also able to delete files in $DbDir" >> $LogFile; fi
fi
}

Cleanup () {
cd /tmp
umount $RamDiskMountPoint
if [ $? -eq 0 ]; then echo "The RamDisk has been detached from $RamDiskMountPoint" >> $LogFile; else echo "unable to unmount the RamDisk from $RamDiskMountPoint">> $LogFile; fi
rm -rf $RamDiskMountPoint >>$LogFile
}
NoOptionDefined () {
 echo "No option have been mentioned at least one option is required"
 DisplayHelp
}
LogLevel ()
{
case ${Lvalue} in
	q)
		echo "Quiet mode selected"
		FullModeLog=false
	;;
	f)
		echo "Full mode selected"
		FullModeLog=true
	;;
	*)
		echo "Unknown option selected"
		DisplayHelp
		exit 1
	;;
esac
}
StageLevel ()
{
case ${Svalue} in
	d)
		echo "Download Option Selected"
	;;
	n)
		echo "NfTables rulesets setup"
	;;
	*)
		echo "Unknown option selected"
		DisplayHelp
		exit 1
	;;
esac
}
DisplayHelp () {
		      echo "$(basename $0) [-v] [-h] [-p] [-l q|f] [-s d|n]" 
		      echo "              -v     : Version" 
		      echo "              -h     : This help file" 
		      echo "              -p     : Purge all stored backups" 
		      echo "              -l     : Log Level" 
		      echo "                 q   : quiet, store only starting and ending in logfile" 
		      echo "                 f   : store full details in logfile" 
		      echo "              -s     : Only run a small part of this script, options have to be mentioned" 
		      echo "                 d   : download : Only donwloads database and sha256 file"
		      echo "                 n   : just add rulesets to nftables"
		      exit 1


}
DownloadDb() {
#Date of Database donwload
DateDbDown="$(date +"%Y%m%d")-MaxMindDb.zip"
DateCheckDown="$(date +"%Y%m%d")-SHA256Sum.txt"
if [ ! -s "$TmpDir/$DateDbDown" ] && [ ! -s "$TmpDir/$DateCheckDown" ] ; then
	echo "---> [ STEP 02 Download Database ]------------" >>$LogFile
	echo "Downloading MaxMind database GeoLite2-Country from https://maxmind.com." >>$LogFile
	if [ "$silent" = "yes" ]; then
		$Wget -q -a $LogFile -O $TmpDir/$DateDbDown $MaxMindDonwloadZipUrl
			if [ $? -ne 0 ]; then
				echo "Failed to download $MaxMindDonwloadZipUrl. Exiting..." >>$LogFile
				exit 1
			fi
		$Wget -q -a $LogFile -O $TmpDir/$DateCheckDown $MMCheckSumFile
			if [ $? -ne 0 ]; then
				echo "Failed to download $MMCheckSumFile. Exiting..." >>$LogFile
				exit 1
			fi	
	else
		$Wget -nv -a $LogFile -O $TmpDir/$DateDbDown $MaxMindDonwloadZipUrl
			if [ $? -ne 0 ]; then
				echo "Failed to download $MaxMindDonwloadZipUrl. Exiting..." >>$LogFile
				exit 1
			fi
		$Wget -nv -a $LogFile -O $TmpDir/$DateCheckDown $MMCheckSumFile
			if [ $? -ne 0 ]; then
				echo "Failed to download $MMCheckSumFile. Exiting..." >>$LogFile
				exit 1
			fi	
	fi
else
echo "---> [ STEP 02 Database Already exists download canceled ]------------" >>$LogFile
echo -e "The database has already been downloaded today\nUsing existing file : $TmpDir/$DateDbDown" >>$LogFile
echo -e "The SHA256 Checksum File has already been downloaded today\nUsing existing file : $TmpDir/$DateCheckDown" >>$LogFile
fi
}

Check256sums () {
echo "---> [ STEP 03 Compare checksums ]------------" >>$LogFile
local DownloadedSum=`cut -d' ' -f1  $TmpDir/$DateCheckDown`
local SumCompute=`$ShaCheck $TmpDir/$DateDbDown | awk '{print $1}'`
if [ $DownloadedSum != $SumCompute ]; then
	echo "Downloaded File checksumms differs" >>$LogFile
	echo "Checksum of : $TmpDir/$DateDbDown :\n$SumCompute" >>$LogFile
	echo "Checksum of : $TmpDir/$DateCheckDown :\n$DownloadedSum" >>$LogFile
	exit 1
else
echo "Files checksumms are correct : $DownloadedSum" >>$LogFile
fi

}

ExtarctArchive() {
echo "---> [ STEP 04 Archive extraction ]------------" >>$LogFile
	if [ -s "$TmpDir/$DateDbDown" ]; then
		cd $TmpDir
			if [ $? -ne 0 ]; then
				echo "Unable to access the $TmpDir" >>$LogFile
				exit 1
			fi
		echo "Extract archive files from : $DateDbDown in $TmpDir" >>$LogFile
			$Unzip -j -o "$TmpDir/$DateDbDown">>$LogFile
			if [ $? -ne 0 ] || [ ! -s "$DateDbDown" ]; then
				echo "Unable to extract archive" >> $LogFile
				exit 1
			else
				echo "---> [ STEP 04a Remove useless files to save some space on $RamDiskMountPoint ]------------"  >>$LogFile
				IFS=, read -r -a array <<< "$FilesToDelete"
				rm -v "${array[@]}" >>$LogFile
				echo "---> [ STEP 04b Remaing files on $RamDiskMountPoint ]------------"  >>$LogFile
				ls -lh $TmpDir>>$LogFile
			fi

	else
		echo -e "The Downloaded archive file $DateDbDown has not been found in $TmpDir\nExiting..." >>$LogFile
		exit 1
	fi
}

SortingCleaningFiles() {
echo "---> [ STEP 05 Transform all files, Ordering and Filtering ]------------" >>$LogFile
MaxmindDownloadedDb="MaxMindDb.zip"
MaxMindLocation="GeoLite2-Country-Locations-en.csv"
MaxMindIPv6Block="GeoLite2-Country-Blocks-IPv6.csv"
MaxMindIPv4Block="GeoLite2-Country-Blocks-IPv4.csv"
FilteredIPv6List="Filtered_IPv6.csv"
FilteredIPv4List="Filtered_IPv4.csv"

# Delete first line of each files as it describes the columns names.
echo "Delete first line of file $MaxMindLocation" >>$LogFile
sed -i '1d' $MaxMindLocation
echo "Delete first line of file $MaxMindIPv6Block" >>$LogFile
sed -i '1d' $MaxMindIPv6Block
echo "Delete first line of file $MaxMindIPv4Block" >>$LogFile
sed -i '1d' $MaxMindIPv4Block

echo "join data from $MaxMindLocation and  $MaxMindIPv6Block to create $FilteredIPv6List" >>$LogFile
join -t, -1 1 -2 2  <(cut -d, -f1,5 $MaxMindLocation) <(cut -d, -f1,2 $MaxMindIPv6Block | sort -t, -k2 -n) --nocheck-order | sort -t, -k2| cut -d, -f2,3>$FilteredIPv6List
echo "create each country file from $FilteredIPv6List" >>$LogFile
while IFS=, read -r CountryCode Subnet ; do 
    echo "$Subnet" >> "$TmpDir/$CountryCode".nft6
done < $FilteredIPv6List

echo "join data from $MaxMindLocation and  $MaxMindIPv4Block to create $FilteredIPv4List" >>$LogFile
join -t, -1 1 -2 2  <(cut -d, -f1,5 $MaxMindLocation) <(cut -d, -f1,2 $MaxMindIPv4Block | sort -t, -k2 -n) --nocheck-order | sort -t, -k2| cut -d, -f2,3>$FilteredIPv4List
echo "create each country file from $FilteredIPv4List" >>$LogFile
while IFS=, read -r CountryCode Subnet ; do 
    echo "$Subnet" >> "$TmpDir/$CountryCode".nft4
done < $FilteredIPv4List
}

SelectCountriesList () {
echo "---> [ STEP 06 Select list of countries ]------------" >>$LogFile
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
echo "---> [ STEP 07 Insert commas and join lines of files located in $DestDir ]------------" >>$LogFile
shopt -s nullglob
# create an array with all the filer/dir inside ~/myDir
echo "---> [ STEP 07a modify IPv4 files ]------------" >>$LogFile
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
done
echo "---> [ STEP 07b modify IPv6 files ]------------" >>$LogFile
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
echo "Delete directory $DestDir and its content" >>$LogFile
rm -rf $DestDir
}

ArchiveFiles () {
DateArchiveFile="$(date +"%Y%m%d")-ScriptName-rulesets.tar.gz"
cd $TmpDir
echo "---> [ STEP 08 archive the following files in $DbDir/$DateArchiveFile ]------------" >>$LogFile
if [ ! -d $DbDir ]; then 
	mkdir -pv $DbDir >>$LogFile
else 
	echo "Directory $DbDir already exists">>$LogFile
fi
tar czvf $DbDir/$DateArchiveFile *.nft*>>$LogFile
}

PurgeSavedArchives ()
	{
echo "---> [ Purge Saved Archives in the directory : $DbDir ]------------" >>$LogFile
if [ -d $DbDir ]; then
	echo "Directory content : ">>$LogFile
	ls -lrth  $DbDir >>$LogFile
	rm -rfv $DbDir >>$LogFile
	exit 0
else
	echo "Directory ${DbDir} does not exists" >>$LogFile
	exit 1
fi
	}

MainProg() {
# Start a timer for the script run time.
local StartTime=$(date +%s)

# Check parameters mentioned at script launch
LFlag=false
SFlag=false
NoArg=true
Parameter="vpl:s:"
  while getopts $Parameter Options
  do
   case ${Options} in
     v)
      echo "$(basename $0) version : $ScriptNameVersion"
      exit 0
     ;;
     p)
	# Purge Previously stored archives.
	PurgeSavedArchives
      ;;
     l)
      LFlag=true;
      Lvalue=${OPTARG}
      LogLevel
 #     echo "loglevel ${Lvalue}"
     ;;
     s)
      SFlag=true;
      Svalue=${OPTARG}
      StageLevel
#      echo "stage ${Svalue}"
     ;;
     \?|h)
      DisplayHelp
      exit 1
     ;;
   esac
 NoArg=false
done
[[ "$NoArg" == true  ]] && { NoOptionDefined; }
shift $(($OPTIND-1))
    if ! $LFlag && [[ -d $1 ]]
      then echo -e "The parameter 'l' option requires a mandatory argument\n --> f : Full log, the most verbose option to see what the script is doing.\n--> q: Basic log option">>$LogFile
      exit 1
    fi
    if ! $SFlag && [[ -d $1 ]]
      then echo "The parameter 's' option requires a mandatory argument"
      exit 1
    fi
										    

#Run Checks procedure
Checks
#Run DownloadDb procedure (Download database if necesary) and extracts files if database exists
DownloadDb
# Checks the SHA256 sums of downloaded file and the one computed
Check256sums
# Launch archive extraction
ExtarctArchive
#Sort and clean files
SortingCleaningFiles
#Select Countries according to the AllowedCountriesList variables
SelectCountriesList
#Insert commas and join lines
InsertCommas
#Archive files
ArchiveFiles 
#Cleanup all the mess
Cleanup
# Display the script run time.
echo "Script run time : $(($(date +%s) - $StartTime))s">>$LogFile	
}
MainProg "$@"
exit 0
