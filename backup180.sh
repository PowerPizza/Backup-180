#!/bin/bash

if ! command -v zip > /dev/null
then
    echo "Installing package : zip"
    pkg install zip -y
    clear
fi

if ! command -v rsync > /dev/null
then
    echo "Installing package : rsync"
    pkg install rsync -y
    clear
fi

if [ ! -d logs ]
then
    mkdir logs
fi

source $(dirname "$0")/settings.conf
#echo $saving_path
if [ ! -d $saving_path/backup_files ]
then
    mkdir $saving_path/backup_files
fi
saving_path=$saving_path/backup_files

scan_paths=$(echo $scan_paths | tr ":" " ")

echo -e "\033[0;31mWelcome To"
echo -e "\033[0;36m
@@@@@@@    @@@@@@    @@@@@@@  @@@  @@@     @@@  @@@  @@@@@@@   
@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@  @@@     @@@  @@@  @@@@@@@@  
@@!  @@@  @@!  @@@  !@@       @@!  !@@     @@!  @@@  @@!  @@@  
!@   @!@  !@!  @!@  !@!       !@!  @!!     !@!  @!@  !@!  @!@  
@!@!@!@   @!@!@!@!  !@!       @!@@!@!      @!@  !@!  @!@@!@!   
!!!@!!!!  !!!@!!!!  !!!       !!@!!!       !@!  !!!  !!@!!!    
!!:  !!!  !!:  !!!  :!!       !!: :!!      !!:  !!!  !!:       
:!:  !:!  :!:  !:!  :!:       :!:  !:!     :!:  !:!  :!:       
 :: ::::  ::   :::   ::: :::   ::  :::     ::::: ::   ::       
:: : ::    :   : :   :: :: :   :   :::      : :  :    :        
"
echo -e "\033[0;32m
             @@@   @@@@@@    @@@@@@@@   
            @@@@  @@@@@@@@  @@@@@@@@@@  
           @@@!!  @@!  @@@  @@!   @@@@  
             !@!  !@!  @!@  !@!  @!@!@  
@!@!@!@!@    @!@   !@!!@!   @!@ @! !@!  
!!!@!@!!!    !@!   !!@!!!   !@!!!  !!!  
             !!:  !!:  !!!  !!:!   !!!  
             :!:  :!:  !:!  :!:    !:!  
             :::  ::::: ::  ::::::: ::  
              ::   : :  :    : : :  :   
\033[0m"

printf "\nPlease select an option\n"
echo "1 - Pack Image Files"
echo "2 - Pack Video Files"
echo "3 - Pack Audio Files"
echo "4 - Pack Document Files"
echo "5 - Pack Compressed Files"
echo "6 - Pack Executable Files"
echo "7 - Pack Database Files"
echo "0 - Pack Miscellaneous (other) Files"
echo -n ">>> "
read opt

file_checker(){
  # Argument 1 => A path or a file name
  # >>> RETURN VALUES
  # 1 => file is image type
  # 2 => file is video type
  # 3 => file is audio type
  # 4 => file is document type
  # 5 => file is compressed type
  # 6 => file is executable type
  # 7 => file is database type
  # 0 => file is other then those above.
  case ${1,,} in
    *".jpg" | *".jpeg" | *".png" | *".gif" | *".bmp" | *".tiff" | *".tif" | *".webp" | *".heif" | *".heic" | *".svg" | *".eps" | *".ai" | *".raw" | *".cr2" | *".nef" | *".arw" | *".ico" | *".psd" | *".xcf")
      return 1;;
    *.mp4 | *.mkv | *.flv | *.avi | *.mov | *.wmv | *.webm | *.m4v | *.3gp | *.ogv | *.ts | *.vob | *.rm | *.asf | *.f4v)
      return 2;;
    *.mp3 | *.wav | *.flac | *.aac | *.ogg | *.m4a | *.wma | *.opus | *.alac | *.aiff | *.amr | *.ac3 | *.dsd | *.pcm | *.au)
      return 3;;
    *.docx | *.xlsx | *.txt | *.pdf | *.pptx | *.odt | *.csv | *.rtf | *.md | *.tex | *.log | *.wps | *.epub | *.key | *.one)
      return 4;;
    *.zip | *.rar | *.7z | *.tar | *.gz | *.xz | *.bz2 | *.tgz | *.lz | *.cab | *.iso | *.zst | *.arj | *.tar.xz | *.tar.gz)
      return 5;;
    *.exe | *.apk | *.sh | *.bin | *.bat | *.msi | *.cmd | *.jar | *.run | *.deb | *.app | *.elf | *.dmg | *.ps1 | *.vbs)
      return 6;;
    *.sql | *.mdb | *.db | *.sqlite | *.csv | *.accdb | *.json | *.xml | *.dbf | *.ibd | *.frm | *.ndf | *.ldf | *.myd | *.parquet)
      return 7;;
    *) return 0;;
   esac
}

find_log_fname=logs/$(date | tr " " "-" | tr ":" "-").log
rsync_log_fname=logs/copy_fails_$(date | tr " " "-" | tr ":" "-").log

fd_created=0
while [ $fd_created -eq 0 ]
do
    echo -n -e "\033[0;36mEnter output folder name :- "
    read output_fname
    echo -e "\033[0m"
    mkdir $saving_path/$output_fname
    if [ $? -eq 0 ]
    then
      fd_created=1
    fi
done



scanning_for=""
case $opt in
    1) scanning_for="image files";;
    2) scanning_for="video files";;
    3) scanning_for="audio files";;
    4) scanning_for="document files";;
    5) scanning_for="compressed files";;
    6) scanning_for="executable files";;
    7) scanning_for="database files";;
    0) scanning_for="miscellaneous files";;
    *) echo "Invalid choice!!!"
       exit 1
    ;;
esac
echo "Packing all $scanning_for into $output_fname folder"

for sc_path in $scan_paths
do
  printf "\n\033[0;32mScanning into $sc_path\n\033[0m"
  scanned_items=0
  found_items=0
  for i in $(find $sc_path -type f 2>> $find_log_fname)
  do
    file_checker $i
    file_type_code=$?
    if [ $file_type_code -eq $opt ]
    then
      found_items=$(($found_items+1))
      rsync -R $i $saving_path/$output_fname 2>> $rsync_log_fname
    fi

    scanned_items=$(($scanned_items+1))
    printf "\033[0;33m%d images found & %d items has been scanned.\r" $found_items $scanned_items
  done
  printf "\033[0;32m\nScan finished for $sc_path\n\n"
done

echo -e "\033[0m"
