#MOLGENIS walltime=23:59:00 mem=8gb nodes=1 ppn=4

#string stage
#string checkStage
#string onekgGenomeFasta
#string gatkVersion
#string sampleName
#string internalId
#string toolDir
#string rawVCF
#string uniqueID
#string jdkVersion
#string variantEvalDir
#string evalGrp

set -u
set -e

function returnTest {
  return $1
}

getFile ${rawVCF}

#Load modules
${stage} jdk/${jdkVersion}

#check modules
${checkStage}

mkdir -p ${variantEvalDir}

echo "## "$(date)" ##  $0 Started "

java -Xmx8g -XX:ParallelGCThreads=4 -jar ${toolDir}GATK-${gatkVersion}/GenomeAnalysisTK.jar \
-T VariantEval \
-R ${onekgGenomeFasta} \
-o ${evalGrp} \
--eval:set1 ${rawVCF} \

putFile ${evalGrp}

echo "## "$(date)" ##  $0 Done "

if returnTest \
  0;
then
  echo "returncode: $?";
  echo "succes moving files";
else
  echo "returncode: $?";
  echo "fail";
fi