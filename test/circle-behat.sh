
error=0
for var in "$@"
do
    echo "$var"
    ahoy behat --format=pretty --out=std --format=junit --out=$CIRCLE_ARTIFACTS/junit /home/ubuntu/dkan/dkan/$var

    if [ ! $? -eq 0 ]
    then
      error=1
    fi
done
exit $error
