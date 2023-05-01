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
#
AllowedCountriesList=(AT,AU,BE,CA,CH,DE,DK,ES,FI,FR,GB,IE,IS,IT,JP,LU,MC,NL,NO,PT,SE,US,VA)
# MaxMind License Key
MaxMindKey="<Put_Your_Key_Here>"
#
#-----------[ User should not modify anything below this line ]-----------
#
# Filename of this script.
ScriptName=`basename "$0"`
# Version number of this script.
ScriptNameVersion="0.0.17"
# Error log filename. This file logs errors in addition to the systemd Journal.
LogFile="/var/log/$ScriptName.log"
# Download URL.
MaxMindDonwloadZipUrl="https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=${MaxMindKey}&suffix=zip"
#Checksum File
MMCheckSumFile="https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=${MaxMindKey}&suffix=zip.sha256"
# Current date/time.
DateTime="$(date +"%d/%m/%Y %H:%M:%S")"
#
# Files to remove once the archive has been extracted.
FilesToDelete="COPYRIGHT.txt,LICENSE.txt,GeoLite2-Country-Locations-zh-CN.csv,GeoLite2-Country-Locations-fr.csv,GeoLite2-Country-Locations-es.csv,GeoLite2-Country-Locations-de.csv,GeoLite2-Country-Locations-pt-BR.csv,GeoLite2-Country-Locations-ja.csv,GeoLite2-Country-Locations-ru.csv"
#
# Ramdisk System MountPoint
RamDiskMountPoint="/tmp/RamDisk"
#
# Default archives storage directory
# It could be be used with nftables in case of reboot.
DbDir="/var/spool/$ScriptName"
#
#-----------[ commands used by this script ]-----------
User=`whoami`
#
#-----------[ Functions used by the script ]-----------
#
CheckProgramm ()
{
local ProgNameVar=$1
local ProgPath=`which ${ProgNameVar}`
echo "${ProgPath}"
 if [ -x ${ProgPath} ]; then
    case ${FullModeLog} in
            true)
             echo "${ProgPath} can be launched with the ${User} account" >>${LogFile}
            ;;
            false)
             # Quiet Mode selected no log output
            ;;
            *)
             echo "A strange parameter has been passed during the tests of programms to be used. And that should not occur, so Exiting Right now" >>${LogFile}
             exit 11 
            ;;
    esac
 else
  echo "Unable to find ${ProgPath} or ${User} isn't allowed to launch it" >>${LogFile}
  exit 10
fi
}

MkRamDrive ()
{
# This Function creates a RamDrive and requires 3 parameters : 
# 1. The RamDrive Size
# 2. The RamDrive Name
# 3. The RamDrive MountPoint
local Size=$1
local RamDriveName=$2
local RamDiskMountPoint=$3
  case ${FullModeLog} in
	true)
	 ${MountPoint} -q ${RamDiskMountPoint}
	 if [ $? -ne 0 ]; then
		${MkDir} ${RamDiskMountPoint}
		if [ -d ${RamDiskMountPoint} ]; then 
			echo "${ScriptName} is able create a RamDisk mountpoint in ${RamDiskMountPoint}" >> ${LogFile}; 
		else 
			echo "unable to create mounting point in ${RamDiskMountPoint}">> ${LogFile}; 
		fi
	else
		echo "${RamDiskMountPoint} already exists and is a valid mountpoint" >> ${LogFile}; 

	 fi
	echo -e "RamDrive has been created with the following parameters :\n Size : ${Size} MB\n Name : ${RamDriveName}\n MountPoint : ${RamDiskMountPoint}" >>${LogFile}
	;;
	false)
	 # Quiet Mode selected no log output
	 ${MountPoint} -q ${RamDiskMountPoint}
	 if [ $? -ne 0 ]; then
		${MkDir} ${RamDiskMountPoint}
	 fi
	;;
	*)
	 echo "A strange parameter has been passed During the creation of the RamDrive" >>$LogFile
	 exit 90
	;;
  esac

	chmod 660 ${RamDiskMountPoint}
	${Mount} -t tmpfs -o size=${Size}m ${RamDriveName} ${RamDiskMountPoint}
	if ${FullModeLog}; 
	then 
		MyRamDiskMounted=`${Mount} | ${Grep} ${RamDiskMountPoint}` 
		echo -e "RamDisk has been attached with the following parameters :\n$MyRamDiskMounted" >>${LogFile}
	fi
	echo ${RamDiskMountPoint}
}

ChecksDirectory ()
{
local DirToCheckName=$1
	case ${FullModeLog} in
	true)
		echo "-----> [ Checks on directory : ${DirToCheckName} ]------------">>${LogFile}
		if [ ! -d ${DirToCheckName} ]; then 
			${MkDir} -pv ${DirToCheckName}>>${LogFile}
	       	fi
		${Touch} ${DirToCheckName}/TstFile.out
		if [ $? -eq 0 ]; then 
			echo "${ScriptName} is able to write files in ${DirToCheckName}">>${LogFile} 
		else
			echo "${ScriptName} is unable to write files in ${DirToCheckName}">>${LogFile} 
		fi
		rm -v ${DirToCheckName}/TstFile.out >>${LogFile}
		if [ $? -eq 0 ]; then 
			echo "${ScriptName} is also able to delete files in ${DirToCheckName}">>${LogFile} 
		else
			echo "${ScriptName} is unable to delete files in ${DirToCheckName}">>${LogFile} 
		fi
	;;
	false)
		if [ ! -d ${DirToCheckName} ]; then 
			${MkDir} -p ${DirToCheckName}
	       	fi
		${Touch} ${DirToCheckName}/TstFile.out
		if [ $? -ne 0 ]; then 
			echo "${ScriptName} is unable to write files in ${DirToCheckName}">>${LogFile}
	       	fi
		rm ${DirToCheckName}/TstFile.out
		if [ $? -ne 0 ]; then 
			echo "${ScriptName} is unable to delete files in ${DirToCheckName}">>${LogFile}
	       	fi
	;;
	*)
		echo "A strange parameter has been found... Exiting now" >>${LogFile}
		exit 41
	;;
	esac
}

FirstChecks () 
{
echo "--->   [ STEP 01 Initial checks ]------------" >>${LogFile}
#2. Checks if used programms are accessible with this user privilege
Mount=$(CheckProgramm mount)
UnMount=$(CheckProgramm umount)
Unzip=$(CheckProgramm unzip)
Sed=$(CheckProgramm sed)
Join=$(CheckProgramm join)
Sort=$(CheckProgramm sort)
Awk=$(CheckProgramm awk)
Grep=$(CheckProgramm grep)
Wget=$(CheckProgramm wget)
Cut=$(CheckProgramm cut)
ShaCheck=$(CheckProgramm sha256sum)
MkDir=$(CheckProgramm mkdir)
MountPoint=$(CheckProgramm mountpoint)
TarGz=$(CheckProgramm tar)
NfTables=$(CheckProgramm nft)
Touch=$(CheckProgramm touch)

echo "--->   [ STEP 02 Creation of Temporary RamDrive to compute and download Files ]------------" >>${LogFile}
#3 Create RamDisk
RamDiskDir=$(MkRamDrive "250" "RamDriveTemp" "/tmp/RamDriveTemp")

# Default temporary directory where this script ouptuts its working files.
TmpDir="${RamDiskDir}"
echo "--->   [ STEP 03 Creation of a ${TmpDir} and checks if script can write in ]------------" >>${LogFile}
ChecksDirectory ${TmpDir}
}

Cleanup () {
echo "--->   [ STEP 11 RamDrive destruction ]------------" >>${LogFile}
cd /tmp
	case ${FullModeLog} in
		true)
			${UnMount} ${RamDiskDir}
			if [ $? -eq 0 ]; then 
				echo "The RamDisk has been detached from ${RamDiskDir}" >> $LogFile; 
			else 
				echo "unable to unmount the RamDisk from ${RamDiskDir}">> ${LogFile}; 
			fi
			rm -rfv ${RamDiskDir} >>${LogFile}
		;;
		false)
			${UnMount} ${RamDiskDir}
			if [ $?  -ne 0 ]; then 
				echo "unable to unmount the RamDisk from ${RamDiskDir}">> ${LogFile}; 
			fi
			rm -rf ${RamDiskDir} 
		;;
		*)
			echo "A strange parameter has been found... Exiting now" >>${LogFile}
			exit 111
		;;
esac
}
NoOptionDefined () {
 echo "No option have been mentioned at least one option is required"
 DisplayHelp
}
LogLevel ()
{
case ${Lvalue} in
	q)
		echo "Quiet mode selected">> ${LogFile}
		FullModeLog=false
	;;
	f)
		echo "Full mode selected">> ${LogFile}
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
if [ ! -s "${TmpDir}/${DateDbDown}" ] && [ ! -s "${TmpDir}/${DateCheckDown}" ] ; then
	echo "--->   [ STEP 04 Download Database ]------------" >>${LogFile}
	case ${FullModeLog} in
		true)
			echo "Downloading MaxMind database GeoLite2-Country from https://maxmind.com." >>${LogFile}
			WgetOption="-nv -a ${LogFile}"
			;;
		false)
			WgetOption="-q -a ${LogFile}"
			;;
		*)
			echo "A strange parameter has been passed in the wget command... Exiting now" >>$LogFile
			exit 41
			;;
	esac
		${Wget} ${WgetOption} -O ${TmpDir}/${DateDbDown} ${MaxMindDonwloadZipUrl}
			if [ $? -ne 0 ]; then
				echo "Failed to download from ${MaxMindDonwloadZipUrl}. Exiting..." >>$LogFile
				exit 42
			fi
		${Wget} ${WgetOption} -O ${TmpDir}/${DateCheckDown} ${MMCheckSumFile}
			if [ $? -ne 0 ]; then
				echo "Failed to download $MMCheckSumFile. Exiting..." >>$LogFile
				exit 43
			fi	

else
echo "--->   [ STEP 04 Database Already exists download canceled ]------------" >>$LogFile
echo -e "The database has already been downloaded today\nUsing existing file : $TmpDir/$DateDbDown" >>$LogFile
echo -e "The SHA256 Checksum File has already been downloaded today\nUsing existing file : $TmpDir/$DateCheckDown" >>$LogFile
fi
}

Check256sums () {
echo "--->   [ STEP 05 Compare checksums ]------------" >>$LogFile
local DownloadedSum=`${Cut} -d' ' -f1  ${TmpDir}/${DateCheckDown}`
local SumCompute=`$ShaCheck ${TmpDir}/${DateDbDown} | ${Awk} '{print $1}'`
if [ ${DownloadedSum} != ${SumCompute} ]; then
	echo "Downloaded File checksumms differs" >>${LogFile}
	echo -e "Checksum of : ${TmpDir}/${DateDbDown} :\n${SumCompute}" >>${LogFile}
	echo -e "Checksum of : ${TmpDir}/${DateCheckDown} :\n${DownloadedSum}" >>${LogFile}
	exit 51
else
	if ${FullModeLog};
		then
		echo "Files checksumms are correct : ${DownloadedSum}" >>${LogFile}
	fi
										        
fi

}

ExtarctArchive() {
echo "--->   [ STEP 06 Extracts the archive ${TmpDir}/${DateDbDown} to ${TmpDir} ]------------" >>${LogFile}
	if [ -s "${TmpDir}/${DateDbDown}" ]; then
		cd ${TmpDir}
			if [ $? -ne 0 ]; then
				echo "Unable to access the ${TmpDir}" >>${LogFile}
				exit 62
			fi

			case ${FullModeLog} in
			  	true)
					$Unzip -j -o "${TmpDir}/${DateDbDown}">>$LogFile
					if [ $? -ne 0 ] || [ ! -s "${DateDbDown}" ]; then
						echo "Unable to extract archive" >> ${LogFile}
						exit 64
					else
						echo "---> [ STEP 06a Remove useless files to save some space on ${TmpDir} ]------------"  >>${LogFile}
						IFS=, read -r -a array <<< "${FilesToDelete}"
						rm -v "${array[@]}" >>${LogFile}
						echo "---> [ STEP 06b Remaining files on ${TmpDir} ]------------"  >>${LogFile}
						ls -lh ${TmpDir}>>${LogFile}
					fi
				;;
				false)
					$Unzip -qq -j -o "${TmpDir}/${DateDbDown}">>${LogFile}
					if [ $? -ne 0 ] || [ ! -s "${DateDbDown}" ]; then
						echo "Unable to extract archive" >> ${LogFile}
						exit 64
					else
						IFS=, read -r -a array <<< "${FilesToDelete}"
						rm "${array[@]}" 
					fi
				;;
				*)
			  		echo "A strange parameter has been found... Exiting now" >>$LogFile
			  		exit 63
				;;
			esac


	else
		echo -e "The Downloaded archive file ${DateDbDown} has not been found in ${TmpDir}\nExiting..." >>${LogFile}
		exit 61
	fi
}

SortingCleaningFiles() {
echo "--->   [ STEP 07 Transform all files, Ordering and Filtering ]------------" >>$LogFile
local MaxMindLocation="${TmpDir}/GeoLite2-Country-Locations-en.csv"
local MaxMindIPv6Block="${TmpDir}/GeoLite2-Country-Blocks-IPv6.csv"
local MaxMindIPv4Block="${TmpDir}/GeoLite2-Country-Blocks-IPv4.csv"
local FilteredIPv6List="${TmpDir}/Filtered_IPv6.csv"
local FilteredIPv4List="${TmpDir}/Filtered_IPv4.csv"

# Delete first line of each files as it describes the columns names.
if ${FullModeLog};
  then
	echo "Delete first line of file ${MaxMindLocation}" >>${LogFile}
	echo "Delete first line of file ${MaxMindIPv6Block}" >>${LogFile}
	echo "Delete first line of file ${MaxMindIPv4Block}" >>${LogFile}
fi
${Sed} -i '1d' ${MaxMindLocation}
${Sed} -i '1d' ${MaxMindIPv6Block}
${Sed} -i '1d' ${MaxMindIPv4Block}

if ${FullModeLog}; then echo "join data from ${MaxMindLocation} and  ${MaxMindIPv6Block} to create ${FilteredIPv6List}" >>${LogFile}; fi
${Join} -t, -1 1 -2 2  <(${Cut} -d, -f1,5 $MaxMindLocation) <(${Cut} -d, -f1,2 $MaxMindIPv6Block | ${Sort} -t, -k2 -n) --nocheck-order | ${Sort} -t, -k2| ${Cut} -d, -f2,3>${FilteredIPv6List}
if ${FullModeLog}; then echo "create each country file from $FilteredIPv6List" >>${LogFile}; fi
while IFS=, read -r CountryCode Subnet ; do 
    echo "$Subnet" >> "$TmpDir/$CountryCode".nft6
done < $FilteredIPv6List

if ${FullModeLog}; then echo "join data from ${MaxMindLocation} and  ${MaxMindIPv4Block} to create ${FilteredIPv4List}">>${LogFile}; fi
${Join} -t, -1 1 -2 2  <(${Cut} -d, -f1,5 ${MaxMindLocation}) <(${Cut} -d, -f1,2 ${MaxMindIPv4Block} | ${Sort} -t, -k2 -n) --nocheck-order | ${Sort} -t, -k2| ${Cut} -d, -f2,3>${FilteredIPv4List}
if ${FullModeLog}; then echo "create each country file from ${FilteredIPv4List}" >>${LogFile}; fi
while IFS=, read -r CountryCode Subnet ; do 
    echo "$Subnet" >> "$TmpDir/$CountryCode".nft4
done < $FilteredIPv4List
}

SelectCountriesList () {
echo "--->   [ STEP 08 Select list of countries ]------------" >>$LogFile
DestDir=${TmpDir}"/DestTempDir"
ChecksDirectory ${DestDir}
IFS=',' read -ra array <<<"$AllowedCountriesList"
for CountryCode in "${array[@]}"; do
	case ${FullModeLog} in
		true)
			cp -v "$TmpDir/$CountryCode".nft4 "$DestDir">>$LogFile
	 		cp -v "$TmpDir/$CountryCode".nft6 "$DestDir">>$LogFile
			;;
		false)
			cp "$TmpDir/$CountryCode".nft4 "$DestDir"
			cp "$TmpDir/$CountryCode".nft6 "$DestDir"
			;;
		*)
			echo "A strange parameter while copying ${TmpDir}/${CountryCode} files to ${DestDir}... Exiting now" >>$LogFile
			exit 71 
			;;
	esac
done

}

InsertCommas () {
echo "--->   [ STEP 09 Insert commas and join lines of files located in $DestDir ]------------" >>$LogFile
shopt -s nullglob
echo "-----> [ STEP 09a modify IPv4 files ]------------" >>$LogFile
if ${FullModeLog}; then 
	rm -v "${TmpDir}"/*.nft4>>${LogFile}
else
	rm "${TmpDir}"/*.nft4
fi
Array=($DestDir/*.nft4)
# iterate through array using a counter
for ((i=0; i<${#Array[@]}; i++)); do
	FileName=`basename ${Array[$i]}`
    	awk 'BEGIN{RS="";FS="\n";OFS=", "}{$1=$1}7' "${Array[$i]}" >"$TmpDir/$FileName"
	Country=`echo $FileName | ${Cut} -d. -f1`
	BeginOfFile="define ipv4_"$Country" = {"
	sed -i -e 's/^/'"$BeginOfFile"'\n/' "$TmpDir/$FileName"
	sed -i -e '$a  }' "$TmpDir/$FileName"
	sed -i -e 'N;s/\n//' "$TmpDir/$FileName"
done
echo "-----> [ STEP 09b modify IPv6 files ]------------" >>$LogFile
if ${FullModeLog}; then 
	rm -v "${TmpDir}"/*.nft6>>${LogFile}
else
	rm "${TmpDir}"/*.nft6
fi
Array=($DestDir/*.nft6)
# iterate through array using a counter
for ((i=0; i<${#Array[@]}; i++)); do
	FileName=`basename ${Array[$i]}`
        awk 'BEGIN{RS="";FS="\n";OFS=", "}{$1=$1}7' "${Array[$i]}" >"$TmpDir/$FileName"
	Country=`echo $FileName | ${Cut} -d. -f1`
	BeginOfFile="define ipv6_"$Country" = {"
	sed -i -e 's/^/'"$BeginOfFile"'\n/' "$TmpDir/$FileName"
	sed -i -e '$a  }' "$TmpDir/$FileName"
	sed -i -e 'N;s/\n//' "$TmpDir/$FileName"
done
 if ${FullModeLog};
	then
	echo "Delete directory $DestDir and its content" >>${LogFile}
	rm -rfv ${DestDir}>>${LogFile}
 fi
}

ArchiveFiles () {
echo "--->   [ STEP 10 archive the generated files in $DbDir/$DateArchiveFile ]------------" >>${LogFile}
DateArchiveFile="$(date +"%Y%m%d")-${ScriptName}-rulesets.tar.gz"
ChecksDirectory ${DbDir}
cd ${TmpDir}
case ${FullModeLog} in
	true)
		${TarGz} czvf ${DbDir}/${DateArchiveFile} *.nft*>>${LogFile}
	;;
	false)
		${TarGz} czf $DbDir/$DateArchiveFile *.nft*
	;;
	*)
	echo "A strange parameter has been found... Exiting now" >>$LogFile
	exit 101
	;;
esac
}

PurgeSavedArchives ()
{
echo "--->   [ Purge Saved Archives in the directory : $DbDir ]------------" >>$LogFile
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

MainProg () 
{
# Start a timer for the script run time.
local StartTime=$(date +%s)
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
     ;;
     s)
      SFlag=true;
      Svalue=${OPTARG}
      StageLevel
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
FirstChecks
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
