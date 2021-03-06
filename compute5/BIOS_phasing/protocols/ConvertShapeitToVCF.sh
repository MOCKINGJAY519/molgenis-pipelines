#MOLGENIS walltime=23:59:00 mem=8gb nodes=1 ppn=1

### variables to help adding to database (have to use weave)
#string project
###
#string stage
#string checkStage

#string WORKDIR
#string shapeitVersion
#string shapeitLigatedHaplotype
#string shapeitPhasedOutputPrefix
#string CHR
#string shapeitPhasedOutputPostfix
#string shapeitDir
#string tabixVersion

echo "## "$(date)" Start $0"



${stage} shapeit/${shapeitVersion}
${stage} tabix/${tabixVersion}
${checkStage}


#Run shapeit convert

# haps inputfile has the .haps postfix hardcoded in so need to remove from our parameter
if shapeit \
    -convert \
    --input-haps ${shapeitLigatedHaplotype%.haps} \
    --output-vcf ${shapeitPhasedOutputPrefix}${CHR}${shapeitPhasedOutputPostfix}.vcf.gz
then
 echo "returncode: $?";
 cd ${shapeitDir}
 bname=$(basename ${shapeitPhasedOutputPrefix}${CHR}${shapeitPhasedOutputPostfix}.vcf.gz)
 # has to be bgzipped
 gunzip ${bname}
 bgzip ${bname%.gz}
 tabix ${bname}
 echo "making md5sum..."
 md5sum ${bname} > ${bname}.md5
 cd -
 echo "succes moving files";
else
 >&2 echo "went wrong with following command:"
 >&2 echo "shapeit \\
            -convert \\
            --input-haps ${shapeitLigatedHaplotype} \\
            --output-vcf ${shapeitPhasedOutputPrefix}${CHR}${shapeitPhasedOutputPostfix}.vcf.gz"
 echo "returncode: $?";
 echo "fail";
 exit 1;
fi

echo "## "$(date)" ##  $0 Done "
