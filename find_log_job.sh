#!/bin/bash +x
set -e

Pid_find_log_job="find_log_job.pid"
declare -a Select_Files
declare -a Output_Files
Query_Command=""
Select_Gateway="any"
Host_Ip="any"
Cluster_Name="any"
Tmp_dir="find_log_tmp/"	
Dns_server1=""	
Dns_server2=""	

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
	by_by()
	{
	
		for i in "${!Output_Files[@]}"; do 
			echo "It's removing the temporary files ..." 
			
			if test -f "${Output_Files[$i]}.flt"; then
				echo "Files ${Output_Files[$i]}.flt"
				Command="rm   ${Output_Files[$i]}.flt "		
				eval $Command
			fi 			
			if test -f "${Output_Files[$i]}.unq"; then
				echo "Files ${Output_Files[$i]}.unq"
				Command="rm   ${Output_Files[$i]}.unq "		
				eval $Command
			fi 	
			if test -f "${Output_Files[$i]}.tmp"; then
				echo "Files ${Output_Files[$i]}.tmp"
				Command="rm   ${Output_Files[$i]}.tmp "		
				eval $Command
			fi 	
		done	
		
		if [[ $$ == $(head -n 1 "$Tmp_dir$Pid_find_log_job") ]] ;then
			$(rm "$Tmp_dir$Pid_find_log_job" )
		fi

	}


	Get_dns() #input final file
	{
		local input_file=$1
		local Ip_List="$(gawk 'BEGIN{FS=OFS=";"}  { for (i=1; i<=NF; i++){ if ($i ~ /src:/ || $i ~ /dst:/ ) split($i,a,":") ; print a[2]}}'  $input_file  | sort | uniq  )"
				for ip in ${Ip_List[@]}; do
					local dsnresult="$(nslookup  -type=A -query=hinfo  -timeout=1  $ip $Dns_server1 $Dns_server2 | gawk 'BEGIN{FS=OFS=" "} { if ($2 ~ /name/) print $4} ' )"
					IFS=' ' read -ra ONENAME <<< "$dsnresult"
					name="${ONENAME[0]}"
					
					if [ -z "${ONENAME[0]}" ];then
						  name="No_name_"						  
					fi
					
					local Ip_name="$(echo $ip | tr -d '[[:space:]]')"
					echo "Adding host name Ip: $Ip_name; name: $name"
					Command="sed -i 's/: $Ip_name;/: $Ip_name; name: $name;/g' $input_file "
					eval $Command
					

				done
	
	}
	
	Query_Job()
	{
		unset Output_Files
		for i in "${!Select_Files[@]}"; do 
			echo "Filtering file ${Select_Files[$i]} "
			filename=$(echo "${Select_Files[$i]}" | cut -f 1 -d '.')
			filename="${Tmp_dir}${Cluster_Name}_${Select_Gateway}_${Host_Ip}_${filename}"
			Output_Files+=($filename)
			Query_Command="$Query_Command_1 ${Select_Files[$i]} ${Query_Command_2} ${filename}.flt "
			eval $Query_Command

			echo "Trying to unifying records for ${filename}.flt "
			Command="sort  ${filename}.flt  | uniq > ${filename}.unq"
			eval $Command
			
			echo "Removing flt file: ${filename}.flt "
			Command="rm  ${filename}.flt "
			eval $Command	
				
		done
		echo ""
		echo "End of Filter ..."
		echo ""
		
		echo "Unifying files ..."
		EndFile="${Tmp_dir}${Cluster_Name}_${Select_Gateway}_${Host_Ip}_$(date '+%Y_%m_%d')"

		for i in "${!Output_Files[@]}"; do 
			echo "Using file ${Output_Files[$i]}.tmp "
			Command="cat ${Output_Files[$i]}.unq >> ${EndFile}.tmp "
			eval $Command	
			
			echo "Removing unq file:  ${Output_Files[$i]}.unq "
			Command="rm   ${Output_Files[$i]}.unq "
			eval $Command	
		done
		echo ""
		echo "End of Unified..."
		echo ""
		
		echo "Trying to sort and remove duplicates in EndFile ${EndFile}.tmp  "
		Command="sort  ${EndFile}.tmp  | uniq  > ${EndFile}.csv"
		eval $Command

		echo "Removing tmp file:  ${EndFile}.tmp"
		Command="rm  ${EndFile}.tmp "
		eval $Command
		

		if [[ '' != $Dns_server1 ]] || [[ '' != $Dns_server2 ]]; then 
			echo "Adding DNS names in:  ${EndFile}.csv"
			Get_dns ${EndFile}.csv
		fi
		
		
		echo "---------------------------------------------------------------"	
		echo "Done ..."
		echo "Final file : ${EndFile}.csv "
		echo "---------------------------------------------------------------"
	}
	
	make_query_command()
	{
		Query_Command_1="fw log  -npl  -c accept "
		if [[ 'any' != $Select_Gateway ]]; then 
			Query_Command_1="$Query_Command_1 -h $Select_Gateway "

		fi
		
		Query_Command_2="| gawk 'BEGIN{FS=OFS=\";\";} {if (\$6 ~ /src:/"
		if [[ 'any' != $Cluster_Name ]]; then 
			Query_Command_2="$Query_Command_2 && tolower(\$4) ~ tolower(\"$Cluster_Name\")) "
		else
			Query_Command_2="$Query_Command_2 )"
		fi

		if [[ 'any' != $Host_Ip ]]; then 
			Query_Command_2="$Query_Command_2 if(\$6 ~ /src: $Host_Ip/ || \$7 ~ /dst: $Host_Ip/)"
		fi


		Query_Command_2="$Query_Command_2 {split(\$1,a,\" \") ; split(\$4,b,\",\") ; print a[6],substr( b[1], 1, length(b[1])-1 ),\$6,\$7,\$8,\$11,\$16,\$21}}'  > "

		filename=$(echo "${Select_Files[0]}" | cut -f 1 -d '.')
		filename="${Tmp_dir}${Cluster_Name}_${Select_Gateway}_${Host_Ip}_${filename}"
		Query_Command="$Query_Command_1 ${Select_Files[0]} ${Query_Command_2} ${filename}.flt"

		echo -e "Query: \e[1m"$Query_Command"\e[21m"
		echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
		
	}



########### MAIN ####################

# Parse options to 
while getopts "hl:n:c:g:" opt; do
  case ${opt} in
	h )
		echo "Usage:"
		echo "    find_log_job -h                      Display this help message."
		echo "    [-n]                      		   Host or net Ip."	
		echo "    [-c]                      		   Cluster name."
		echo "    [-g]                      		   Gateway Ip."
		echo "    [-l]                      		   Log files."	
		echo ""
		echo ""		
		echo "    Example:" 	
		echo "    find_log_job.sh -n 1.1.1.1 -c fwcpd -g 2.2.2.2 -l \"2020-05-04_000000.log 2020-05-03_000000.log\""
		echo ""
		exit 0
	  ;;
	g )
		Select_Gateway="$OPTARG"
		echo -e  "-------------------------------------"
		echo -e "Select Gateway: \e[1m"$Select_Gateway"\e[21m"
		echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
	;; 
	c )
		Cluster_Name="$OPTARG"
		echo -e  "-------------------------------------"
		echo -e  "Select cluster: \e[1m"$Cluster_Name"\e[21m"
		echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
	;; 
	n )
		Host_Ip="$OPTARG"
		echo -e  "-------------------------------------"
		echo -e  "Select host: \e[1m"$Host_Ip"\e[21m"
		echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
	;; 
	l )
		IFS=' ' read -r -a Select_Files <<< "$OPTARG"
		echo -e  "-------------------------------------"
		echo -e  "Files: \e[1m"${Select_Files[@]}"\e[21m"
		echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
	 ;; 
   \? )
		echo "Invalid Option: -$OPTARG" 1>&2
		exit 1
	 ;;
  esac
done



if [ -z "$Select_Files" ];then
	echo "At least the log name files sould be pass as argument"
	exit 1
fi

echo " My Pid: "$$""
echo ""
trap by_by EXIT 

create_temp_dir

if (test -f "$Tmp_dir$Pid_find_log_job"); then
	if ps -p $(head -n 1 "$Tmp_dir$Pid_find_log_job") >/dev/null ; then
		echo -e  "\e[1mA other instance find_log_job is running ...\e[21m"
		echo -e  "\e[1mInstance find_log_job PID:$(head -n 1 "$Tmp_dir$Pid_find_log_job")\e[21m"
		echo -e "\e[25m\e[21m\e[22m\e[24m\e[25m\e[27m\e[28m"
		exit
	else
		echo $$ > "$Tmp_dir$Pid_find_log_job"
	fi
else
	echo $$ > "$Tmp_dir$Pid_find_log_job"

fi

make_query_command
Query_Job
