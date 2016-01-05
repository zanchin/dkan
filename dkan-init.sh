mkdir dkan &&
#mv !(dkan) dkan/.
#find . ! -regex '.*/dkan' ! -regex '.' -exec mv '{}' dkan \; &&
shopt -s extglob dotglob
mv !(dkan) dkan
shopt -u dotglob
# find . ! -regex '.*/dkan' ! -regex '.' -exec echo "'{}'" \; &&
ahoy init
