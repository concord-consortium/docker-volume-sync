#! /bin/bash
if [ ! -d "test_files" ]; then
    echo "Creating test_files directory for host sync..."
    mkdir -p test_files >> /dev/null 2>&1
fi


for n in {1..200}; do
    dd if=/dev/urandom of=test_files/file$( printf %03d "$n" ).bin bs=1 count=$(( RANDOM + 1024 ))
done

echo "Test File Here" > test_files/zzz.txt
