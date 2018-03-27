#!/bin/bash

####Software versions####
indel_version="IndelGenotyper.36.3336"
muse_version="v1.0rc"
mutect_version="v1.1.5"
pindel_version="v0.2.5b8"
radia_version="v1.1.5"
somsniper_version="v1.0.5.0"
varscan_version="v2.3.9"
#########################

usage()
{
        echo "reheader_wrapper.sh"
        echo "Kami E. Chiotti 02.15.18"
        echo
        echo "Generates a configuration YAML then executes tcga-vcf-reheader.py to edit VCF headers"
        echo "prior to vcf2maf merging."
        echo
        echo "Usage: $0 [-i input_vcfs ] [-T tumor_analysis_uuid] [-B tumor_bam_name] \ "
        echo "                           [-X tumor_aliquot_uuid] [-A tumor_aliquot_name] [-n normal_analysis_uuid \ "
        echo "                           [-b normal_bam_name] [-x normal_aliquot_uuid] [-a normal_aliquot_name \ "
        echo "                           [-p platform] [-c center] "
        echo
        echo "  [-i input_vcfs]           - Array of input VCF file (with full paths) generated by mc3_variant.cwl workflow"
        echo "  [-T tumor_analysis_uuid]  - GDC Sample UUID (e.g., cf8c9b38-246d-46aa-b557-6c882e438161)"
        echo "  [-B tumor_bam_name]       - GDC BAM file name (e.g., C317.TCGA-AB-2901-03A-01W-0733-08.4_gdc_realn.bam)"
        echo "  [-X tumor_aliquot_uuid]   - GDC Aliquot UUID (e.g., bac6a6d2-8c40-43cd-ab4c-16d3f8a06eb6)"
        echo "  [-A tumor_aliquot_name]   - GDC Aliquot ID (e.g., TCGA-AB-2901-03A-01W-0733-08)"
        echo "  [-n normal_analysis_uuid] - GDC Sample UUID (e.g., c404dcfb-e580-4cf2-8fe6-6990ce2ce03a)"
        echo "  [-b normal_bam_name]      - GDC Sample UUID (e.g., C317.TCGA-AB-2901-11A-01W-0732-08.4_gdc_realn.bam)"
        echo "  [-x normal_aliquot_uuid]  - GDC Sample UUID (e.g., 22f3f166-41a7-4058-a315-d72e1d7becd6)"
        echo "  [-a normal_aliquot_name]  - GDC Sample UUID (e.g., TCGA-AB-2901-11A-01W-0732-08)"
        echo "  [-p platform]             - Sequencing platform (e.g., illumina)"
        echo "  [-c center]               - Sequencing center (e.g., OHSU)"
        echo "  [-h help]                 - Display this page"
        exit
}

input_vcfs=()
tumor_analysis_uuid=""
tumor_bam_name=""
tumor_aliquot_uuid=""
tumor_aliquot_name=""
normal_analysis_uuid=""
normal_bam_name=""
normal_aliquot_uuid=""
normal_aliquot_name=""
platform=""
center=""

while getopts ":i:T:B:X:A:n:b:x:a:p:c:h" Option
        do
        case $Option in
                i ) input_vcfs+=("$OPTARG") ;;
                T ) tumor_analysis_uuid="$OPTARG" ;;
                B ) tumor_bam_name="$OPTARG" ;;
                X ) tumor_aliquot_uuid="$OPTARG" ;;
                A ) tumor_aliquot_name="$OPTARG" ;;
                n ) normal_analysis_uuid="$OPTARG" ;;
                b ) normal_bam_name="$OPTARG" ;;
                x ) normal_aliquot_uuid="$OPTARG" ;;
                a ) normal_aliquot_name="$OPTARG" ;;
                p ) platform="$OPTARG" ;;
                c ) center="$OPTARG";;
                h ) usage ;;
                * ) echo "Unrecognized argument. Use '-h' for usage information."; exit 255 ;;
        esac
done
shift $(($OPTIND - 1))

if [[ "$input_vcfs" == "" || "$tumor_analysis_uuid" == "" || "$tumor_bam_name" == "" || "$tumor_aliquot_uuid" == "" || "$tumor_aliquot_name" == "" || "$normal_analysis_uuid" == "" || "$normal_bam_name" == "" || "$normal_aliquot_uuid" == "" || "$normal_aliquot_name" == "" || "$platform" == "" || "$center" == "" ]]
then
        usage
fi

output_ary=()
for ((i = 0; i < ${#input_vcfs[@]}; i++))
do

    if [ ! -r "${input_vcfs[$i]}" ]
    then
            echo "Error: can't open input VCF ${input_vcfs[$i]##*/}" >&2
            exit 1
    fi

    output_vcf="${input_vcfs[$i]%%.*}.reheadered.vcf"

    if [[ ${input_vcfs[$i]##*/} == "muse_filtered.vcf" ]]
    then
      software_name="MuSE"
      software_version=$muse_version
      prefix="muse"
    elif [[ ${input_vcfs[$i]##*/} == "mutect.vcf" ]]
    then
      software_name="MuTect"
      software_version=$mutect_version
      prefix="mutect"
    elif [[ ${input_vcfs[$i]##*/} == "pindel_filtered.vcf" ]]
    then
      software_name="Pindel"
      software_version=$pindel_version
      prefix="pindel"
    elif [[ ${input_vcfs[$i]##*/} == "radia_filtered.vcf" ]]
    then
      software_name="RADIA"
      software_version=$radia_version
      prefix="radia"
    elif [[ ${input_vcfs[$i]##*/} == "somatic_sniper_fpfilter.vcf" ]]
    then
      software_name="SomaticSniper"
      software_version=$somsniper_version
      prefix="somatic_sniper_fpfilter"
    elif [[ ${input_vcfs[$i]##*/} == "varscan_fpfilter.vcf" ]]
    then
      software_name="VarScan"
      software_version=$varscan_version
      prefix="varscan_fpfilter"
    elif [[ ${input_vcfs[$i]##*/} == "varscan_indel.vcf" ]]
    then
      software_name="VarScan"
      software_version=$varscan_version
      prefix="varscan_indel"
    elif [[ ${input_vcfs[$i]##*/} == "indelocator_filtered.vcf" ]]
    then
      software_name="Indelocator"
      software_version=$indel_version
      prefix="indelocator"
    else
      echo "Input Error: ${input_vcfs[$i]##*/} is not a supported VCF. "
    fi

    timestamp=`date +%m%d%y_%H%M`

    cat << EOF > $prefix\_$timestamp\_config.yml
    config:
        sample_line_format:
            SAMPLE=<
            ID={id},
            Description="{description}",
            SampleUUID={aliquot_uuid},SampleTCGABarcode={aliquot_name},
            AnalysisUUID={analysis_uuid},File="{bam_name}",
            Platform="{platform}",
            Source="dbGAP",Accession="dbGaP",
            softwareName=<{software_name}>,
            softwareVer=<{software_version}>,
            softwareParam=<{software_params}>
            >
        fixed_sample_params:
          software_name:      '${software_name}'
          software_version:   '${software_version}'
          software_params:    '.'
        fixed_headers:  # name, assert, value
            - [fileformat,  False,   'VCFv4.1']
            - [tcgaversion, False,   '1.1']
            - [phasing,     False,  'none']
            - [center,      False,  '"${center}"']

    samples:
        NORMAL:
            description:     'Normal'
            analysis_uuid:   ${normal_analysis_uuid}
            bam_name:        ${normal_bam_name}
            aliquot_uuid:    ${normal_aliquot_uuid}
            aliquot_name:    ${normal_aliquot_name}
            platform:        ${platform}
        PRIMARY:
            description:    'Tumor'
            analysis_uuid:   ${tumor_analysis_uuid}
            bam_name:        ${tumor_bam_name}
            aliquot_uuid:    ${tumor_aliquot_uuid}
            aliquot_name:    ${tumor_aliquot_name}
            platform:        ${platform}
EOF
# End of yml creation

python /opt/tcga-vcf-reheader.py "${input_vcfs[$i]}" "${output_vcf}" $prefix\_$timestamp\_config.yml

output_ary[$i]=$output_vcf

done

