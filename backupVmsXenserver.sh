#!/bin/bash

# Settings
XSNAME=`echo $HOSTNAME`
backup_dir="/var/run/sr-mount/ecb9dc51-297b-2912-3fb2-edde04b1bb0d/$XSNAME/$DATE"
backup_ext=" VM.xva"
date=$(date +%Y-%m-%d_%H-%M-%S)
CLIENTE="XENGEN8 - HP"

#limpa pasta backup
rm -rf /var/run/sr-mount/ecb9dc51-297b-2912-3fb2-edde04b1bb0d/$XSNAME/*

# VMs to backup

vm_backup_list=()
#vm_backup_list[0]="901d9d55-a61d-aff8-d0d1-7da25c83d827"
#vm_backup_list[1]="fe1f60cb-dcd6-46e0-8ed6-d0d8301baf04"
#tiangong
vm_backup_list[0]="7a8a3551-4234-a504-3a8d-20bdedf72fd4"
#elastix
vm_backup_list[1]="e7c3bb9d-18d1-8442-ad5e-6f8ef7ebc280"
#Almaz
vm_backup_list[2]="7a6fef51-6be8-5e44-66aa-1e497e5b2b7f"
#chang
#vm_backup_list[0]="39de60f5-3b0d-3005-1a94-12149cdd61aa"

vm_backup_list_count=${#vm_backup_list[@]}

# Get VM list

vm_list_string=`xe vm-list is-control-domain=false`
IFS="
"
vm_list_array=($vm_list_string)
vm_list_count=${#vm_list_array[@]}

# Create arrays to use

vm_uuid_array=()
vm_label_array=()
vm_log=()


# Start Log

vm_log[${#vm_log[@]}]="Starting VM Backup: $date"
vm_log[${#vm_log[@]}]="-----------------------------"


# Get VMs to export

vm_log[${#vm_log[@]}]="Parsing VM list"

key=0
index=0

for line in ${vm_list_array[@]}; do

        if [ ${line:0:4} = "uuid" ]; then

                uuid=`expr "$line" : '.*: \(.*\)$'`
                label=`expr "${vm_list_array[key+1]}" : '.*: \(.*\)$'`

                vm_uuid_array[index]=$uuid
                vm_label_array[index]=$label

                vm_log[${#vm_log[@]}]="Added VM #$index: $uuid, $label"

                let "index = $index+1"

        fi

	let "key = $key+1"

done

vm_log[${#vm_log[@]}]="Done parsing VM list"


# Backup VMs

vm_log[${#vm_log[@]}]="Backup VMs"

key=0

for uuid in ${vm_uuid_array[@]}; do

        # Set VM backup state

        backup_vm=false

        # If the backup list is empty

        if [ $vm_backup_list_count = 0 ]; then

                # Backup all VMs

                backup_vm=true

        # Else check to see if the VM is to be backed up

        else

            	for backup_uuid in ${vm_backup_list[@]}; do

                        if [ $uuid = $backup_uuid ]; then

                                backup_vm=true
                                break

                        fi

                done

        fi

	# If the VM is being backed up

        if [ $backup_vm = true ]; then

                # Log

               vm_log[${#vm_log[@]}]="VM: $uuid"

                # Label

                label=${vm_label_array[key]}

                # Create snapshot

                echo "criando snapshot"
                snapshot=`xe vm-snapshot vm=$uuid new-name-label=backup_$date`
                vm_log[${#vm_log[@]}]="Snapshot: $snapshot"
                echo "finalizou snapshot"
                # Set as VM not template
                echo "iniciando template"
                snapshot_template=`xe template-param-set is-a-template=false uuid=$snapshot`
                vm_log[${#vm_log[@]}]="Set as VM"
                echo "finalizando template"
                # Export
                echo "enviando p iosafe"
                snapshot_export=`xe vm-export vm=$snapshot filename="$backup_dir$label-$date$backup_ext"`
                vm_log[${#vm_log[@]}]="Export: $snapshot_export"

                # Delete snapshot

                snapshot_delete=`xe vm-uninstall uuid=$snapshot force=true`
                vm_log[${#vm_log[@]}]="Delete Snapshot: $snapshot_delete"

        # Else the VM isnt being backed up

        else

            	# Log

                vm_log[${#vm_log[@]}]="VM: $uuid"
                vm_log[${#vm_log[@]}]="Ignoring Backup"

        fi

	# Increment Key

done

vm_log[${#vm_log[@]}]="Export Complete"
vm_log[${#vm_log[@]}]="

"

# Logging

#echo ${vm_uuid_array[@]}
#echo ${vm_label_array[@]}

for log in ${vm_log[@]}; do
        echo $log
done

echo " Enviando e-mail em `date +%d-%m-%y_%H:%M`"
cat mail -s "Backup Diario XenServer $CLIENTE Finalizado" ti@norteng.com.br

