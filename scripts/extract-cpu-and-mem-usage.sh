DIRECTORY_PATH=$1
FILES=( $(find $DIRECTORY_PATH -type f -name '*top.txt') )
echo $FILES

for file in "${FILES[@]}"
do
    echo $file
    NEW_FILE_MEM=$( echo "$file" | sed 's/top.txt/top_mem.txt/' )
    NEW_FILE_CPU=$( echo "$file" | sed 's/top.txt/top_cpu.txt/' )
    cat ${file} | grep -P "(MiB Mem).*" > ${NEW_FILE_MEM}
    cat ${file} | grep -P "(%Cpu).*" > ${NEW_FILE_CPU}
done