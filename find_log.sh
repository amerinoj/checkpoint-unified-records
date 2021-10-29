        #!/bin/bash +x
        set -e

        Log_Path=$FWDIR/log/
        Tmp_dir="find_log_tmp/"
        Pid_find_log="find_log.pid"
        Pid_find_log_job="find_log_job.pid"
        Job="find_log_job.sh"
        Logs=""
        Opt=""
        Time_start=""
        Select_Gateway="any"
        Host_Ip="any"
        Gateway_Name="any"
        Policy_Name="any"
        Rule_Id="any"
        Query_Command=""
        declare -a Select_Files
        declare -a Output_Files
        subproces=""
        declare -a  Child_Pid

        usage()
        {
                printf  "\n"
                printf  "########### find_log ############\n"
                printf  "Search unique traffic per servers  in checkpoint logs\n\n"
                printf  "Execute the script into mds enviroment\n"
                printf  "Execute :mdsstat\n"
                printf  "Execute :mdsenv <cma ip> or <cma name>\n\n"
                printf  "usage: sh find_log.sh -l log_path\n\n"
                printf  "[-l] : Log path, if not used the default path will be use\n"
                printf  "\n"
        }

        find_log_files()
        {
                Logs=""
                echo "Using log path:"$Log_Path
                Logs="$(ls "${Log_Path}"/*.log |rev | cut -d "/" -f1 | rev )"
                if [ -z "$Logs" ] ; then
                        echo "No Log files find ..."
                        echo "Exit..."
                        exit
                else
                        echo "Log files find ..."

                fi
        }
        create_temp_dir()
        {
                Tmp_dir="$(echo "$PWD"/"$Tmp_dir")"
                echo $Tmp_dir
                if [ -d "$Tmp_dir" ]; then
                  echo "Temporal directory exits ${Tmp_dir}..."
                else
                  mkdir $Tmp_dir
                  echo "Creating Temporal directory ..."
                  if [ -d "$Tmp_dir" ]; then
                        echo "Temporal directory created ${Tmp_dir}..."
                  else
                        echo "Error: ${Tmp_dir} not found. Can not continue."
                        exit
                  fi


                fi
        }
        select_gateway()
        {
                echo "Intro managemet Gateway Ip or object name"
                echo "Press intro to select any"
                read -p "gateway : " Select_Gateway
                if ! [ "$Select_Gateway" ]; then
                        Select_Gateway="any"
                fi
                echo -e "Gateway Selected: \e[1m $Select_Gateway \e[21m "
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
        }

        select_Policy()
        {
                echo "Intro the Policy name "
                echo "Press intro to select any"
                read -p "Policy Name : " Policy_Name
                if ! [ "$Policy_Name" ]; then
                        Policy_Name="any"
                fi
                echo -e "Policy Selected: \e[1m $Policy_Name \e[21m "
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
        }
        select_rule_id()
        {
                echo "Intro the Rule Id "
                echo "Press intro to select any"
                read -p "Rule_id : " Rule_Id
                if ! [ "$Rule_Id" ]; then
                        Rule_Id="any"
                fi
                echo -e "Rule Selected: \e[1m $Rule_Id \e[21m "
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
        }
        select_host()
        {
                echo "Intro the host Ip to filter the search"
                echo "The query will try to find any traffic from or to this host"
                echo -e " \e[4m If use 10.0.0. this will be interpreted as 10.0.0.0/24\e[24m"
                echo "Press intro to select any"
                read -p "host Ip : " Host_Ip
                if ! [ "$Host_Ip" ]; then
                        Host_Ip="any"
                fi
                echo -e  "Host Selected:\e[1m $Host_Ip\e[21m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
        }

        machine_status()
        {
        local Ls_path="$1"
        process_renew
        local Cpu="$(cpstat os -f multi_cpu | gawk 'BEGIN{FS=OFS="|";} NF {print $2"  "$6}' | tail -n +5) "
        local Mem="$(free -m  | gawk 'BEGIN{FS=OFS=" ";} {if ($1 ~ /Mem:/) print "Mem in MB Total:"$2" Free:"$4}')"
        #local C_Disk="$(df -H   | sort  -n -t ' ' -k6 |  tail -n +3)"
        local L_Disk="$(df  -k $PWD -h  | sort  -n -t ' ' -k6 |  tail -n +2)"
        local Fsize="$(ls $Ls_path -hlt | cut -d" " -f5-20 | head -n 11 )"

        printf "######################## Global CPU ##########################\n\n"
        printf "Cpu:%-5s %-2s %% | Cpu:%-5s %-2s %% | Cpu:%-5s %-2s %% | Cpu:%-5s %-2s %%\n" $Cpu
        printf "\n###################### Global Memory #########################\n\n"
        printf "%s \n" "$Mem"
        #printf "\n####################### Global Disk ##########################\n\n"
        #printf "%s \n" "$C_Disk"
        printf "\n####################### Process view #########################\n\n"
        printf "[Type]    PID    %%CPU    %%MEM    CMD\n"

        for p in "${Child_Pid[@]}"; do
                local Stat_Pid="$(ps  -p $p -o pid,%cpu,%mem,cmd | tail -n 1  | gawk ' {print $1"    "$2"    "$3"    "$4" "$5" "$6" "$7" "$8" "$9" "$10" "$11" "$12" "$13" "$14" "$15}')"
                if [[ $$ == $p ]] ; then
                        printf "[Ower]    %s \n" "$Stat_Pid"
                else
                        if ps -p $p >/dev/null ; then
                                printf "[Chil]    %s \n" "$Stat_Pid"
                        else
                                printf "No Found :  %s no found\n" "$p"
                        fi
                fi
        done
        printf "\n######################## Disk Use ############################\n\n"
        printf "%s \n" "$L_Disk"
        printf "_______________________________________________________________\n"
        printf "Size:%-4s Date:%-3s %s %-5s Name:%-2s \n" $Fsize

        }

        select_G_Name()
        {
                echo "Intro the Origin Gateway name to filter the search or use a pattern"
                echo -e " \e[4m Example: to get origin names fwcpd1 and fwcpd2 put:fwcpd\e[24m"
                echo "Press intro to select any"
                read -p "Gateway name : " Gateway_Name
                if ! [ "$Gateway_Name" ]; then
                        Gateway_Name="any"
                fi
                echo -e  "Gateway Name:\e[1m $Gateway_Name\e[21m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
        }
        by_by()
        {
                echo -e  "\e[1mClosing script ...\e[21m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
                for p in ${Child_Pid[@]}; do
                        if [[ $$ != $p ]] ; then
                                if ps -p $p >/dev/null ; then
                                        echo "Trying to close subprocess $p"
                                        eval "kill -TERM $p "
                                        sleep 1
                                        if ps -p $p >/dev/null ; then
                                                while  ps -p $p >/dev/null ; do
                                                        echo "ReTrying to close subprocess $p ..."
                                                        eval " kill -9 $p"
                                                        sleep 5
                                                done
                                                echo "Subprocess $p closed ..."

                                        else
                                                echo "Subprocess $p closed ..."

                                        fi
                                fi
                        fi

                done

                ########erase temporal files

                count=`ls -1 ${Tmp_dir}*.flt 2>/dev/null | wc -l`
                if [ $count != 0 ];then
                        echo "Deleting temp files *.flt ..."
                        Command="rm ${Tmp_dir}*.flt"
                        eval $Command
                fi
                count=`ls -1 ${Tmp_dir}*.unq 2>/dev/null | wc -l`
                if [ $count != 0 ];then
                        echo "Deleting temp files *.unq ..."
                        Command="rm ${Tmp_dir}*.unq"
                        eval $Command
                fi
                count=`ls -1 ${Tmp_dir}*.tmp 2>/dev/null | wc -l`
                if [ $count != 0 ];then
                        echo "Deleting temp files *.tmp ..."
                        Command="rm ${Tmp_dir}*.tmp"
                        eval $Command
                fi


                if [[ $$ == $(head -n 1 "$Tmp_dir$Pid_find_log") ]] ;then
                        $(rm "$Tmp_dir$Pid_find_log" )
                fi

                echo -e  "\e[1mClosed ...\e[21m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"

                trap - EXIT TERM INT
                exit 2

        }
        show_query_example()
        {

                Hd_Av_size=$(df  -k $PWD   | sort  -n -t ' ' -k6 |  tail -n +2 | gawk 'BEGIN{FS=OFS=" ";} { print $3  }')
                Hd_Av_size=$(($Hd_Av_size/1024))
                Max_File_Size=$( ls --sort=size -l  $Log_Path*.log | head -n 1 | gawk 'BEGIN{FS=OFS=" ";} { print $5  }')
                Max_File_Size=$(($Max_File_Size/1024/1024))

                Reco_Size=$((${#Select_Files[@]}*2))
                Reco_Size=$(($Reco_Size+$Max_File_Size))
                Reco_Size=$((2*Reco_Size))

                 Query_Command_1="fw log -nplq -m semi -c accept "
                if [[ 'any' != $Select_Gateway ]]; then
                        Query_Command_1="$Query_Command_1 -h $Select_Gateway "

                fi

                Query_Command_2="| gawk 'BEGIN{FS=OFS=\";\";}  {S=D=P=SV=M=L=\"0\";for (I=1;I<NF;I++){if(\$I ~ / src:/ ){S=\$I};if(\$I ~ / dst:/){D=\$I};if(\$I ~ / proto:/){P=\$I};if(\$I ~ / svc:/){SV=\$I};if(\$I ~ / match_id:/){M=\$I};if(\$I ~ / layer_name:/){L=\$I};} split(\$14,O,\",\") ;if(\$7 ==\" Action: accept\" "
				
                if [[ 'any' != $Gateway_Name ]]; then
                        Query_Command_2="$Query_Command_2 && O[1]  ~  /$Gateway_Name/ "
                fi

                if [[ 'any' != $Policy_Name ]]; then
                        Query_Command_2="$Query_Command_2 &&  L  ~  /$Policy_Name/ "
                fi

                if [[ 'any' != $Host_Ip ]]; then
                        Query_Command_2="$Query_Command_2 && (S  ~  /$Host_Ip/ || D  ~  /$Host_Ip/) "
                fi

                if [[ 'any' != $Rule_Id ]]; then
                        Query_Command_2="$Query_Command_2 &&  M  ~  /$Rule_Id/ "
                fi
				
                Query_Command_2="$Query_Command_2 ) print O[1],\$8,\$7,S,D,P,SV,M,L}"

                Query_Command_2="$Query_Command_2 '  > "


                filename=$(echo "${Select_Files[0]}" | cut -f 1 -d '.')
                filename="${Tmp_dir}${Gateway_Name}_${Policy_Name}_${Host_Ip}${Rule_Id}${filename}"
                Query_Command="$Query_Command_1 ${Select_Files[0]} ${Query_Command_2} ${filename}.flt"

                echo -e "\e[5mExecute query command\e[25m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
                echo -e "Selected Gateway: \e[1m"$Select_Gateway"\e[21m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"

                echo -e "Selected Gateway name: \e[1m"$Gateway_Name"\e[21m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"

                echo -e "Selected Policy name: \e[1m"$Policy_Name"\e[21m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"

                echo -e "Selected Rule Id: \e[1m"$Rule_Id"\e[21m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"

                echo -e "Selected Host: \e[1m"$Host_Ip"\e[21m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"

                echo -e "Query example: \e[1m"$Query_Command"\e[21m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
                echo -e "Selected log files: ${Select_Files[@]}"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"

                echo -e "Available Disk space: \e[1m"$Hd_Av_size" [MB]\e[21m"
                echo -e "Approximate size need: \e[1m"$Reco_Size" [MB]\e[21m"
                echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"


        }

        show_job_status()
        {
        local T_start=$(date +%s)
        local process_id="$1"
        File_ls="$Tmp_dir""*.*"
        #######wait until the proccess is alive
        while ps -p $process_id >/dev/null ; do
                clear
                Time_end=$(date +%s)
                DIFF=$(( $Time_end - $T_start ))
                echo "                Execution time:[ $(($DIFF / 60)) minutes $(($DIFF % 60)) seconds]"
                machine_status "$File_ls"
                sleep 5
        done

        File_ls="$Tmp_dir""*.csv"
        EndFile="$(ls $File_ls)"
        echo "Task Done ..."
        printf "Locate your final file : \n%s \n" " ${EndFile}"
        echo "---------------------------------------------------------------"

        }

        process_renew()
        {
                unset Child_Pid
                Child_Pid+=($$)
                if ! [ -z "$subproces" ];then
                        Child_Pid+=($subproces)
                        process_tree $subproces
                fi
        }

        process_tree()
        {
        local Parent_pid="$1"
        local C_pid=$(pgrep -P $Parent_pid )
        for p_id in ${C_pid[@]}; do
                Child_Pid+=($p_id)
                local C2_pid=$(pgrep -P $p_id )
                for p_id2 in ${C2_pid[@]}; do
                        Child_Pid+=($p_id2)
                        local C3_pid=$(pgrep -P $p_id2 )
                        for p_id3 in ${C3_pid[@]}; do
                                Child_Pid+=($p_id3)
                        done
                done
        done
        }

        select_log_files()
        {
        unset Select_Files
        echo -e "\n!!!Select the logs file for query !!!\n"
        hsopt=$Logs
        oldIFS=$IFS
        IFS=$'\n'
        choices=($hsopt)
        choices+=('All')
        choices+=('Range')
        choices+=('Go back')
        IFS=$oldIFS
        PS3="Select file: "
        select answer in "${choices[@]}"; do
                for item in "${choices[@]}"; do
                   if [[ $item == $answer ]]; then
                                if  [[ 'Go back' == $answer ]] || [[ 'All' == $answer ]] ; then
                                        if [[ 'All' == $answer ]]; then
                                                unset Select_Files
                                                Select_Files=($Logs)
                                                echo "Files: ${Select_Files[@]}"
                                        fi
                                        break 2;
                                else
                                        if [[ 'Range' == $answer ]]; then
                                                echo "____________________________________________"
                                                echo "Intro de file range"
                                                echo "id1-id2"
                                                read -p "File Range : " Range_File
                                                if [[ ${Range_File} == *"-"* ]]; then
                                                        from=$(echo ${Range_File}| cut -d'-' -f1)
                                                        to=$(echo ${Range_File}| cut -d'-' -f2)
                                                        echo "From :$from    To :$to"
                                                        for i in "${!choices[@]}"; do
                                                                if (("$i"+1 >= "$from" )) && (("$i"+1 <= "$to")) ;then
                                                                        Select_Files+=(${choices[$i]})
                                                                fi
                                                        done

                                                        echo "Files: ${Select_Files[@]}"
                                                fi
                                        else
                                                if [[ " ${Select_Files[@]} " =~ " ${answer} " ]]; then
                                                        echo "Log file previusly selected"
                                                else
                                                        Select_Files+=($answer)
                                                        echo "Files: ${Select_Files[@]}"

                                                fi
                                        fi

                                fi

                   fi


                done
        done

        }

        ##############MAIN##############
        trap by_by  SIGINT
        unset Child_Pid
        Child_Pid+=$$

        while [ "$1" != "" ]; do
                case $1 in
                        -l | --log )           shift
                                                                        Log_Path=$1
                                                                        ;;
                        -h | --help )           usage
                                                                        exit
                                                                        ;;
                        * )                     usage
                                                                        exit 1
                esac
                shift
        done

        create_temp_dir

        if (test -f "$Tmp_dir$Pid_find_log"); then
                if ps -p $(head -n 1 "$Tmp_dir$Pid_find_log") >/dev/null ; then
                        echo -e  "\e[1mAnother instance find_log is running ...\e[21m"
                        echo -e  "\e[1mInstance find_log PID:$(head -n 1 "$Tmp_dir$Pid_find_log")\e[21m"
                        echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
                        exit
                else
                        echo $$ > "$Tmp_dir$Pid_find_log"
                fi
        else
                echo $$ > "$Tmp_dir$Pid_find_log"

        fi

        if (test -f "$Tmp_dir$Pid_find_log_job"); then
                if ps -p $(head -n 1 "$Tmp_dir$Pid_find_log_job") >/dev/null ; then
                        subproces=$(head -n 1 "$Tmp_dir$Pid_find_log_job")
                        echo -e  "\e[1mAnother instance find_log_job is running ...\e[21m"
                        echo -e  "\e[1mInstance find_log_job PID:$subproces\e[21m"
                        echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"

                        read -r -p "Do you want to take the control? [y/N] :" response
                        case "$response" in
                                [yY][eE][sS]|[yY])

                                        Child_Pid+=($subproces)
                                        process_tree $subproces
                                        show_job_status $subproces
                                        #######remove PID from list
                                        Child_Pid=(${Child_Pid[@]/$subproces})
                                        exit
                                        ;;
                                *)
                                        exit
                                        ;;
                        esac
                fi

        fi


        find_log_files
        Select_Files=($Logs)

        #Menu
        Opt=""
        while [[ $Opt != "End" ]]; do

                echo ""
                printf "\n####################  Menu  options  ####################\n\n"
                PS3='Options: '
                options=("Filter:Select Files" "Filter:Select Gateway Ip" "Filter:Select Gateway Name" "Filter:Policy Name" "Filter:Rule Id" "Filter:Select Host"  "Machine Status" "Execute" "End")
                select Opt in "${options[@]}"
                do
                   case $Opt in
                        "Filter:Select Files")
                                clear
                                select_log_files
                                sleep 2
                                clear
                         break
                         ;;

                        "Filter:Select Gateway Ip")
                                clear
                                select_gateway
                                sleep 2
                                clear
                         break
                         ;;
                        "Filter:Select Gateway Name")
                                clear
                                select_G_Name
                                sleep 2
                                clear
                         break
                         ;;
                        "Filter:Policy Name")
                                clear
                                select_Policy
                                sleep 2
                                clear
                         break
                         ;;
                        "Filter:Rule Id")
                                clear
                                select_rule_id
                                sleep 2
                                clear
                         break
                         ;;
                        "Filter:Select Host")
                                clear
                                select_host
                                sleep 2
                                clear
                         break
                         ;;


                        "Machine Status")
                                clear
                                File_ls="$Tmp_dir""*.*"
                                machine_status "$File_ls"


                         break
                         ;;

                        "Execute")
                                clear
                                show_query_example
                                read -r -p "Are you sure? [y/N] :" response
                                case "$response" in
                                        [yY][eE][sS]|[yY])
                                                break 2
                                                ;;
                                        *)
                                                break
                                                ;;
                                esac
                                clear

                         ;;

                        "End")
                                exit
                                ;;
                        *) echo "invalid option $REPLY";;
                        esac
                done

        done

        clear

        echo "Be patient, It'll take a while ..."
        Time_start=$(date +%s)


        ########launch query job

        log_file_string=""
        for i in "${!Select_Files[@]}"; do
                log_file_string="$log_file_string ${Select_Files[$i]}"
        done
        Command="nohup sh $Job -n $Host_Ip -c $Gateway_Name -g $Select_Gateway -r $Rule_Id -p $Policy_Name -l \" $log_file_string \" "
        eval $Command &
        subproces=$!

        Command="disown -h $subproces"
        eval $Command

        Child_Pid+=($subproces)
        process_tree $subproces
        show_job_status $subproces
        #######remove PID from list
        Child_Pid=(${Child_Pid[@]/$subproces})


        Time_end=$(date +%s)
        DIFF=$(( $Time_end - $Time_start ))

        EndFile="${Tmp_dir}${Gateway_Name}_${Policy_Name}_${Host_Ip}${Rule_Id}$(date '+%Y_%m_%d')"
        echo "---------------------------------------------------------------"
        echo "Execution time: $(($DIFF / 60)) minutes $(($DIFF % 60)) seconds"
        echo "---------------------------------------------------------------"
        echo "Done ..."
        echo "Final file : ${EndFile}.csv "
        echo "---------------------------------------------------------------"




